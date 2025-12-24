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
_metrics_lock = asyncio.Lock()
_request_counts: Dict[tuple[str, str, int], int] = defaultdict(int)
_request_latency_sum_ms: Dict[tuple[str, str], float] = defaultdict(float)
_request_latency_count: Dict[tuple[str, str], int] = defaultdict(int)
_client_counts: Dict[tuple[str, str], int] = defaultdict(int)
_client_latency_sum_ms: Dict[str, float] = defaultdict(float)
_client_latency_count: Dict[str, int] = defaultdict(int)
_feedback_entries: list[dict[str, Any]] = []
_feedback_limit = 200


class ClientMetricEvent(BaseModel):
    event: str
    duration_ms: float | None = None
    status: str = Field(default="ok")
    timestamp: str | None = None


class FeedbackPayload(BaseModel):
    rating: int = Field(ge=1, le=5)
    comment: str | None = None
    scenario: str = Field(default="unknown")
    timestamp: str | None = None


def _metrics_snapshot() -> dict[str, Any]:
    return {
        "request_counts": dict(_request_counts),
        "request_latency_sum_ms": dict(_request_latency_sum_ms),
        "request_latency_count": dict(_request_latency_count),
        "client_counts": dict(_client_counts),
        "client_latency_sum_ms": dict(_client_latency_sum_ms),
        "client_latency_count": dict(_client_latency_count),
        "feedback_entries": list(_feedback_entries),
    }


def _render_dashboard(snapshot: dict[str, Any]) -> str:
    request_counts = snapshot["request_counts"]
    request_latency_sum_ms = snapshot["request_latency_sum_ms"]
    request_latency_count = snapshot["request_latency_count"]
    client_counts = snapshot["client_counts"]
    client_latency_sum_ms = snapshot["client_latency_sum_ms"]
    client_latency_count = snapshot["client_latency_count"]
    feedback_entries = snapshot["feedback_entries"]

    feedback_count = len(feedback_entries)
    feedback_avg = (
        sum(item["rating"] for item in feedback_entries) / feedback_count if feedback_count else 0.0
    )
    feedback_rows = []
    for entry in feedback_entries[-5:][::-1]:
        comment = entry.get("comment") or "-"
        scenario = entry.get("scenario") or "unknown"
        rating = entry.get("rating", "-")
        feedback_rows.append(f"<tr><td>{rating}</td><td>{scenario}</td><td>{comment}</td></tr>")

    rows_requests = []
    for (method, path, status_code), count in sorted(request_counts.items()):
        latency_key = (method, path)
        total = request_latency_sum_ms.get(latency_key, 0.0)
        cnt = request_latency_count.get(latency_key, 0) or 1
        avg = total / cnt
        rows_requests.append(
            f"<tr><td>{method}</td><td>{path}</td><td>{status_code}</td>"
            f"<td>{count}</td><td>{avg:.1f} ms</td></tr>"
        )

    rows_client = []
    for (event, status_value), count in sorted(client_counts.items()):
        total = client_latency_sum_ms.get(event, 0.0)
        cnt = client_latency_count.get(event, 0) or 1
        avg = total / cnt
        rows_client.append(
            f"<tr><td>{event}</td><td>{status_value}</td><td>{count}</td><td>{avg:.1f} ms</td></tr>"
        )

    return f"""<!doctype html>
<html lang="ru">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Gateway Metrics Dashboard</title>
    <style>
      :root {{
        color-scheme: light;
        --bg: #f4f1ec;
        --card: #ffffff;
        --ink: #1b1b1b;
        --muted: #5b5b5b;
        --accent: #1f7a8c;
        --border: #e0dbd3;
      }}
      body {{
        margin: 0;
        font-family: "IBM Plex Mono", "SF Mono", Menlo, monospace;
        background: radial-gradient(circle at top, #fef7ef, #f4f1ec 45%, #efe9df);
        color: var(--ink);
      }}
      header {{
        padding: 24px 28px 8px;
      }}
      h1 {{
        margin: 0 0 6px;
        font-size: 22px;
        letter-spacing: 0.5px;
      }}
      .sub {{
        color: var(--muted);
        font-size: 13px;
      }}
      .grid {{
        display: grid;
        gap: 18px;
        padding: 18px 28px 36px;
        grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
      }}
      .card {{
        background: var(--card);
        border: 1px solid var(--border);
        border-radius: 14px;
        padding: 16px;
        box-shadow: 0 6px 16px rgba(15, 15, 15, 0.08);
      }}
      table {{
        width: 100%;
        border-collapse: collapse;
        font-size: 12px;
      }}
      th, td {{
        text-align: left;
        padding: 6px 8px;
        border-bottom: 1px solid var(--border);
      }}
      th {{
        text-transform: uppercase;
        font-size: 10px;
        letter-spacing: 0.08em;
        color: var(--muted);
      }}
      .pill {{
        display: inline-block;
        padding: 4px 8px;
        border-radius: 999px;
        background: #eaf3f4;
        color: var(--accent);
        font-size: 11px;
        margin-right: 6px;
      }}
    </style>
  </head>
  <body>
    <header>
      <h1>Gateway Metrics Dashboard</h1>
      <div class="sub">Источник: in-memory gateway counters • Обнови страницу после тестов</div>
    </header>
    <section class="grid">
      <div class="card">
        <div class="pill">HTTP</div>
        <h2>Requests</h2>
        <table>
          <thead>
            <tr><th>Method</th><th>Path</th><th>Status</th><th>Count</th><th>Avg</th></tr>
          </thead>
          <tbody>
            {''.join(rows_requests) if rows_requests else '<tr><td colspan="5">No data yet</td></tr>'}
          </tbody>
        </table>
      </div>
      <div class="card">
        <div class="pill">Client</div>
        <h2>App Metrics</h2>
        <table>
          <thead>
            <tr><th>Event</th><th>Status</th><th>Count</th><th>Avg</th></tr>
          </thead>
          <tbody>
            {''.join(rows_client) if rows_client else '<tr><td colspan="4">No data yet</td></tr>'}
          </tbody>
        </table>
      </div>
      <div class="card">
        <div class="pill">Feedback</div>
        <h2>User Satisfaction</h2>
        <p>Avg rating: <strong>{feedback_avg:.2f}</strong> • Total: <strong>{feedback_count}</strong></p>
        <table>
          <thead>
            <tr><th>Rating</th><th>Scenario</th><th>Comment</th></tr>
          </thead>
          <tbody>
            {''.join(feedback_rows) if feedback_rows else '<tr><td colspan="3">No feedback yet</td></tr>'}
          </tbody>
        </table>
      </div>
    </section>
  </body>
</html>
"""


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


@app.middleware("http")
async def collect_http_metrics(request: Request, call_next):
    if request.url.path == "/metrics":
        return await call_next(request)
    start = time.perf_counter()
    response = await call_next(request)
    duration_ms = (time.perf_counter() - start) * 1000
    key = (request.method, request.url.path, response.status_code)
    latency_key = (request.method, request.url.path)
    async with _metrics_lock:
        _request_counts[key] += 1
        _request_latency_sum_ms[latency_key] += duration_ms
        _request_latency_count[latency_key] += 1
    return response


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


@app.post("/client-metrics")
async def client_metrics(
    payload: ClientMetricEvent,
    _: None = Depends(verify_token),
) -> dict[str, Any]:
    event = payload.event.strip().lower()
    status_value = payload.status.strip().lower()
    async with _metrics_lock:
        _client_counts[(event, status_value)] += 1
        if payload.duration_ms is not None:
            _client_latency_sum_ms[event] += payload.duration_ms
            _client_latency_count[event] += 1
    return {"status": "ok"}


@app.post("/feedback")
async def feedback(
    payload: FeedbackPayload,
    _: None = Depends(verify_token),
) -> dict[str, Any]:
    async with _metrics_lock:
        _feedback_entries.append(payload.model_dump())
        if len(_feedback_entries) > _feedback_limit:
            _feedback_entries.pop(0)
    return {"status": "ok"}


@app.get("/feedback/summary")
async def feedback_summary() -> dict[str, Any]:
    async with _metrics_lock:
        entries = list(_feedback_entries)
    count = len(entries)
    avg = sum(item["rating"] for item in entries) / count if count else 0.0
    return {"count": count, "average_rating": avg}


@app.get("/metrics")
async def metrics(request: Request) -> Response:
    lines: list[str] = []
    lines.append("# HELP gateway_http_requests_total Total HTTP requests processed by the gateway.")
    lines.append("# TYPE gateway_http_requests_total counter")
    lines.append("# HELP gateway_http_request_duration_ms Gateway request duration in milliseconds.")
    lines.append("# TYPE gateway_http_request_duration_ms summary")
    lines.append("# HELP gateway_client_metrics_total Client-side metrics reported by the app.")
    lines.append("# TYPE gateway_client_metrics_total counter")
    lines.append("# HELP gateway_client_latency_ms Client-side latency in milliseconds.")
    lines.append("# TYPE gateway_client_latency_ms summary")
    lines.append("# HELP gateway_feedback_count Total feedback responses.")
    lines.append("# TYPE gateway_feedback_count gauge")
    lines.append("# HELP gateway_feedback_avg_rating Average rating from feedback (1-5).")
    lines.append("# TYPE gateway_feedback_avg_rating gauge")

    async with _metrics_lock:
        snapshot = _metrics_snapshot()
        for (method, path, status_code), count in snapshot["request_counts"].items():
            lines.append(
                f'gateway_http_requests_total{{method="{method}",path="{path}",status="{status_code}"}} {count}'
            )
        for (method, path), total in snapshot["request_latency_sum_ms"].items():
            count = snapshot["request_latency_count"][(method, path)]
            lines.append(
                f'gateway_http_request_duration_ms_sum{{method="{method}",path="{path}"}} {total:.3f}'
            )
            lines.append(
                f'gateway_http_request_duration_ms_count{{method="{method}",path="{path}"}} {count}'
            )
        for (event, status_value), count in snapshot["client_counts"].items():
            lines.append(
                f'gateway_client_metrics_total{{event="{event}",status="{status_value}"}} {count}'
            )
        for event, total in snapshot["client_latency_sum_ms"].items():
            count = snapshot["client_latency_count"][event]
            lines.append(f'gateway_client_latency_ms_sum{{event="{event}"}} {total:.3f}')
            lines.append(f'gateway_client_latency_ms_count{{event="{event}"}} {count}')
        feedback_count = len(snapshot["feedback_entries"])
        feedback_avg = (
            sum(item["rating"] for item in snapshot["feedback_entries"]) / feedback_count
            if feedback_count
            else 0.0
        )
        lines.append(f"gateway_feedback_count {feedback_count}")
        lines.append(f"gateway_feedback_avg_rating {feedback_avg:.3f}")

    accepts = request.headers.get("accept", "")
    if "text/html" in accepts:
        return Response(_render_dashboard(snapshot), media_type="text/html")
    return Response("\n".join(lines) + "\n", media_type="text/plain; version=0.0.4")


@app.get("/dashboard")
async def dashboard() -> Response:
    async with _metrics_lock:
        snapshot = _metrics_snapshot()
    return Response(_render_dashboard(snapshot), media_type="text/html")


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
