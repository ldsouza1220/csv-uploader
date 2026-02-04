# ADR-0008: CI/CD Pipeline

**Status:** Accepted

## Context

Code changes need automated validation before reaching production.

## Decision

GitHub Actions pipeline with four stages:

| Stage | Tool | Purpose |
|-------|------|---------|
| Lint | ruff | Code style and static analysis |
| Test | pytest | Unit tests with mocked S3 |
| Build | Docker | Push to GHCR |
| Deploy | yq + git | Update image tag, Flux picks it up |

Current test coverage:
- File upload validation (CSV-only)
- API endpoint responses
- Database persistence (mocked)
- S3 operations (mocked)

## Production Improvements

This pipeline is minimal. For production:

**More meaningful tests:**
- Integration tests against real MinIO
- End-to-end tests that upload a file and verify it lands in S3

**Additional stages:**
- Security scanning (Trivy, Snyk)
- SAST/DAST analysis
- Staging environment deployment before prod
- Smoke tests post-deployment

The current setup validates basic functionality. Production needs tests that reflect what actually matters to customers.

## Consequences

**Pros:**
- Automated validation on every push
- GitOps deployment (no manual kubectl)
- Fast feedback loop

**Cons:**
- Test coverage is basic
- No staging environment
- No security scanning yet
