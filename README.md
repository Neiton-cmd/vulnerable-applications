# Vulnerable Apps

Collection of intentionally vulnerable modern web applications focused on realistic business logic flaws, API security issues, and modern web exploitation scenarios.

The goal of this repository is not to create toy CTF challenges, but to simulate how real developers accidentally introduce vulnerabilities into modern applications.

---

# Philosophy

Most vulnerable labs focus on:

* isolated payloads
* unrealistic bugs
* intentionally insecure code

This repository focuses on:

* realistic architecture
* believable business logic
* modern frameworks
* authentication & authorization flows
* API-driven applications
* subtle trust boundary mistakes

The vulnerabilities are designed to emerge naturally from application features and developer assumptions.

---

# Applications

## idor-multitenant-saas

Modern ecommerce/SaaS-style application built with:

### Stack

* FastAPI
* PostgreSQL
* Next.js
* Docker Compose
* JWT authentication
* Cookie-based sessions

### Features

* Authentication
* JWT cookie auth
* Protected routes
* Products catalog
* Orders system
* Account management
* Password reset
* Role-based users
* API-driven frontend

### Security Topics

* IDOR / BOLA
* Broken access control
* Authorization flaws
* Business logic vulnerabilities
* Mass assignment
* State manipulation
* Multi-tenant security issues

---

# Repository Structure

```text
vulnerable-apps/
│
├── idor-multitenant-saas/
```

---

# Goals

This repository is intended for:

* pentesters
* bug bounty hunters
* AppSec engineers
* developers learning secure architecture
* API security practice
* modern web exploitation research

---

# Running Applications

Most applications are fully Dockerized.

Example:

```bash
cd idor-multitenant-saas
docker compose up --build
```

---

# Important

These applications are intentionally vulnerable.

Do NOT expose them to the public internet.

Run locally only.

---

# Future Plans

* Multi-tenant SaaS applications
* GraphQL authorization labs
* Webhook exploitation scenarios
* Race condition labs
* File upload vulnerabilities
* JWT/JWK attacks
* OAuth/OIDC misconfigurations
* Modern frontend trust boundary issues
* Realistic admin panels
* Supply chain scenarios

---

# Author

GitHub:
https://github.com/Neiton-cmd
