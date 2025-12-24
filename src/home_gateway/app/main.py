"""
FastAPI gateway for forwarding chat/model requests to a local Ollama instance.
"""

from __future__ import annotations

import asyncio
import hmac
import os
import time
from collections import defaultdict, deque
from typing import Any, AsyncIterator, Deque, Dict, Optional

import httpx
from fastapi import Depends, FastAPI, Header, HTTPException, Request, Response, status
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel, Field

APP_VERSION = "0.1.0"


class Settings(BaseModel):
    ollama_base_url: str = Field(default=os.getenv("OLLAMA_BASE_URL", "http://10.8.1.3:11434"))
    shared_token: Optional[str] = Field(default=os.getenv("GATEWAY_SHARED_TOKEN"))
    rate_limit_requests: int = Field(default=int(os.getenv("RATE_LIMIT_REQUESTS", "20")))
    rate_limit_window_sec: int = Field(default=int(os.getenv("RATE_LIMIT_WINDOW_SEC", "60")))


settings = Settings()

app = FastAPI(
    title="Home Gateway",
    description="Proxy between iOS app and local Ollama runtime.",
    version=APP_VERSION,
)

_client: httpx.AsyncClient | None = None


async def get_client() -> httpx.AsyncClient:
    global _client
    if _client is None:
        _client = httpx.AsyncClient(timeout=httpx.Timeout(60.0, connect=10.0))
    return _client


class ChatRequest(BaseModel):
    model: str
    prompt: str
    stream: bool = Field(default=False)
    options: Dict[str, Any] | None = None


rate_state: Dict[str, Deque[float]] = defaultdict(deque)
_rate_lock = asyncio.Lock()


async def enforce_rate_limit(request: Request) -> None:
    if settings.rate_limit_requests <= 0:
        return
    client_host = request.client.host if request.client else "unknown"
    window = settings.rate_limit_window_sec
    async with _rate_lock:
        timestamps = rate_state[client_host]
        now = time.time()
        # Remove timestamps older than window.
        while timestamps and timestamps[0] <= now - window:
            timestamps.popleft()
        if len(timestamps) >= settings.rate_limit_requests:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many requests, please slow down.",
            )
        timestamps.append(now)


async def verify_token(authorization: str | None = Header(default=None)) -> None:
    expected = settings.shared_token
    if not expected:
        return
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing bearer token.")
    provided = authorization.split(" ", 1)[1]
    if not hmac.compare_digest(provided.strip(), expected.strip()):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid bearer token.")


@app.get("/health")
async def health() -> dict[str, Any]:
    return {
        "status": "ok",
        "ollama_base_url": settings.ollama_base_url,
        "version": APP_VERSION,
    }


@app.get("/")
async def root() -> dict[str, Any]:
    return {
        "message": "Home Gateway for Ollama",
        "health": "/health",
        "models": "/models",
        "chat": "/chat",
    }


@app.get("/models")
async def list_models(_: None = Depends(verify_token), __: None = Depends(enforce_rate_limit)) -> dict[str, Any]:
    client = await get_client()
    url = f"{settings.ollama_base_url.rstrip('/')}/api/tags"
    try:
        response = await client.get(url)
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=str(exc)) from exc
    if response.status_code >= 400:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@app.post("/chat")
async def chat(
    payload: ChatRequest,
    request: Request,
    _: None = Depends(verify_token),
    __: None = Depends(enforce_rate_limit),
) -> Response:
    client = await get_client()
    url = f"{settings.ollama_base_url.rstrip('/')}/api/chat"
    ollama_payload: dict[str, Any] = {
        "model": payload.model,
        "messages": [
            {"role": "user", "content": payload.prompt},
        ],
        "stream": payload.stream,
    }
    if payload.options:
        ollama_payload["options"] = payload.options

    if payload.stream:
        try:
            stream = client.stream("POST", url, json=ollama_payload)
        except httpx.HTTPError as exc:
            raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=str(exc)) from exc

        async def forward_stream() -> AsyncIterator[bytes]:
            async with stream as response:
                if response.status_code >= 400:
                    body = await response.aread()
                    raise HTTPException(status_code=response.status_code, detail=body.decode())
                async for chunk in response.aiter_bytes():
                    if not chunk:
                        continue
                    yield chunk

        return StreamingResponse(content=forward_stream(), media_type="application/x-ndjson")

    try:
        response = await client.post(url, json=ollama_payload)
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=str(exc)) from exc
    if response.status_code >= 400:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return JSONResponse(response.json())


@app.on_event("shutdown")
async def shutdown_event() -> None:
    global _client
    if _client is not None:
        await _client.aclose()
        _client = None
