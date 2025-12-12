# MAD_Excersise #11 – Secure Software Engineering for Mobile Apps

## Block 1 – Core Security Principles in Mobile Context

This exercise focuses on applying fundamental security principles—confidentiality, integrity, authenticity, non-repudiation, and authorization—to mobile applications. Mobile apps handle particularly sensitive data (credentials, payment information, location, health data), often on devices that can be lost, stolen, or compromised.

Key principles:
- Confidentiality: ensuring that only authorized parties can access sensitive information, typically through encryption in transit (TLS) and at rest (secure storage).
- Integrity: guaranteeing that data has not been tampered with, using checksums, message authentication codes (MACs), and digital signatures.
- Authenticity: verifying the identities of users and servers, typically using credentials, tokens, and certificates.
- Non-repudiation: providing proof of actions (e.g., signed transactions and audit logs) so they cannot be denied later.
- Authorization: enforcing fine-grained access control so users and services only access resources they are permitted to use.

In your summary, explain how these principles translate into concrete design decisions for a mobile banking or healthcare app.

---

## Block 2 – Threat Modeling Methodologies

The assignment introduces threat modeling frameworks like STRIDE and PASTA as systematic ways to identify and prioritize risks.

STRIDE (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege) provides a checklist of threat categories:
- Spoofing: impersonating a user or service (e.g., fake login screens, forged tokens).
- Tampering: modifying requests, responses, or stored data.
- Repudiation: denying actions without reliable logs.
- Information disclosure: leaking sensitive data through insecure storage, logs, or network.
- Denial of service: making the app or backend unavailable via resource exhaustion.
- Elevation of privilege: gaining higher permissions than intended.

PASTA (Process for Attack Simulation and Threat Analysis) is a risk-centric methodology that moves from defining business objectives and assets to modeling threats, simulating attacks, and proposing countermeasures.

Your analysis should outline how you would apply STRIDE or PASTA to a concrete mobile app (e.g., a payment app), identifying assets (credentials, tokens, transactions) and likely attack vectors (MITM, rooted devices, reverse engineering).

---

## Block 3 – Secure Coding, Input Validation, and Data Storage

Secure coding practices and robust input validation are critical for preventing common vulnerabilities from OWASP Mobile Top 10.

Key practices:
- Input validation and sanitization on both client and server to prevent injection attacks (SQL injection, XSS) against backends.
- Avoiding dynamic code execution or reflection with untrusted data.
- Proper error handling that does not leak sensitive information.

For data storage:
- Use platform-provided secure storage (Android Keystore, iOS Keychain) for keys and tokens.
- Encrypt sensitive databases and files where appropriate (e.g., SQLCipher, EncryptedSharedPreferences, encrypted Core Data stores).
- Avoid storing secrets or PII in logs or screenshots.

Explain how these techniques mitigate risks such as credential theft, unauthorized access after device loss, and forensic extraction.

---

## Block 4 – Authentication, Encryption, and Secure Communication

The exercise lists authentication protocols and encryption strategies: OAuth 2.0, OpenID Connect (OIDC), mutual TLS, certificate pinning, symmetric/asymmetric encryption, hashing.

Important points:
- OAuth 2.0 and OIDC: used for delegated access and single sign-on; mobile apps often use authorization code flow with PKCE to avoid exposing client secrets.
- JWT or opaque tokens: represent authenticated sessions; must be stored securely and validated on each request.
- TLS: ensures encryption in transit; proper certificate validation prevents man-in-the-middle attacks.
- Certificate pinning: binding the app to specific server certificates or public keys to reduce risk from compromised CAs.

In your summary, discuss best practices such as short-lived access tokens, refresh tokens with additional protections, and rotating keys. Also explain how to design APIs so that the server remains the ultimate authority for authorization decisions.

---

## Block 5 – Reverse Engineering, Code Tampering, and Security Testing

Mobile apps are distributed as binaries that attackers can inspect and modify. Common threats include reverse engineering, repackaging with malware, and runtime tampering.

Mitigation strategies:
- Code obfuscation to make static analysis harder (ProGuard/R8 on Android, third-party tools for iOS binaries).
- Runtime protections: jailbreak/root detection, debugger detection, and checks for integrity of the app binary.
- Moving critical logic and secrets to backends instead of embedding them in the app.

Security testing approaches:
- Static analysis (SAST) of source or bytecode to find insecure patterns.
- Dynamic analysis (DAST) and penetration testing using tools like OWASP MASVS/MASTG checklists.
- Using security scanners and fuzzing tools to identify edge-case vulnerabilities.

A brief synthesis should tie these practices to compliance standards (e.g., OWASP MASTG, GDPR, HIPAA), emphasizing that security is an ongoing process rather than a one-time checklist.

---

## Synthesis / Conclusions

Exercise #11 frames mobile app development as secure software engineering rather than just feature implementation. By grounding designs in core security principles and structured threat modeling, you can prioritize defenses where they matter most. Secure coding and storage practices protect data on inherently insecure devices, while robust authentication and encrypted communication protect data in transit.

At the same time, recognizing the realities of reverse engineering and tampering pushes critical functionality and secrets to backends and motivates continuous security testing. When combined with regulatory awareness and incident response planning, these techniques form a defense-in-depth strategy appropriate for modern mobile applications handling sensitive user data.

