# MAD_Excersise #7 – Mobile Security, Networking, and APIs

## Block 1 – Fundamentals of Mobile Networking

This exercise examines how mobile apps communicate with backend services over HTTP/HTTPS and how to secure that communication. Mobile networks are variable (Wi-Fi, 4G/5G, roaming), so robust error handling, retries, and offline strategies are necessary.

Core concepts:
- HTTP/HTTPS requests, RESTful APIs, and JSON as the de-facto data exchange format.
- TLS for encryption in transit and the importance of certificate validation.
- Common libraries and tools: Retrofit/OkHttp on Android, URLSession/Alamofire on iOS, `fetch`/Axios in cross-platform stacks.

You should understand how request/response lifecycles work, how to handle status codes and errors, and how to design network layers that are testable and resilient.

---

## Block 2 – Authentication and Authorization

A major focus is secure authentication and authorization in mobile apps.

Key topics:
- Token-based auth (JWT, opaque tokens) instead of long-lived passwords.
- OAuth 2.0 and OpenID Connect for delegated login via identity providers (Google, Apple, etc.).
- Secure storage of tokens in platform-specific mechanisms (Android Keystore, iOS Keychain).

Your analysis should explain why storing tokens in plain preferences or local files is dangerous and how secure storage APIs protect against device compromise.

---

## Block 3 – API Design and Error Handling

The exercise usually asks you to design or analyze an API contract between mobile app and backend.

Important considerations:
- Clear, versioned endpoints (e.g., `/api/v1/...`).
- Consistent JSON structures with explicit fields and error codes.
- Pagination and filtering for large data sets.
- Idempotency for actions that might be retried.

On the client side, robust error handling includes:
- Differentiating between network errors, server errors (5xx), client errors (4xx), and validation errors.
- Showing user-friendly messages and recovery options (retry, contact support, edit input).
- Logging errors to monitoring systems.

---

## Block 4 – Secure Data Handling on Device

Beyond secure transport, the assignment covers how data is stored and processed locally.

Key practices:
- Use of encrypted storage for sensitive data (Keychain/Keystore, encrypted databases).
- Minimization of stored PII (personally identifiable information) and careful consideration of what needs to be cached.
- Proper handling of logs to avoid leaking secrets or private data.

Discuss how these practices align with privacy regulations and platform policies.

---

## Block 5 – Common Vulnerabilities and Defenses

Mobile apps face recurring security vulnerabilities:
- Insecure data storage (plain-text passwords or tokens).
- Insecure communication (HTTP instead of HTTPS, weak TLS configurations, missing certificate validation).
- Hardcoded secrets (API keys embedded in the app binary).
- Insufficient input validation leading to injection attacks on backends.

Defensive strategies include:
- Enforcing HTTPS and using HSTS/SSL pinning where appropriate.
- Moving secrets to secure backend services and using short-lived tokens.
- Applying least-privilege principles and role-based access control.

A brief summary should connect these issues to real incident reports and platform security guidelines (OWASP Mobile Top 10).

