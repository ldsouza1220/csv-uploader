# ADR-0009: Security Practices

**Status:** Accepted

## Context

Containers and Kubernetes clusters need security hardening beyond defaults.

## Decision

### TLS Everywhere

- All external traffic terminates TLS at the Gateway
- Certificates from Let's Encrypt via cert-manager
- Cloudflare DNS validation (no HTTP challenge exposure)

### Container Security

Both applications run with hardened security contexts:

```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
```

**csv-uploader:**
- Runs as UID 1000 (non-root)
- Read-only filesystem
- `/data` volume for SQLite (writable)
- `/tmp` volume for temp files (writable)

**panda-secret (nginx):**
- Runs as UID 101 (nginx user)
- Read-only filesystem
- Writable volumes for `/var/cache/nginx`, `/var/run`, `/tmp`
- Listens on port 8080 (non-privileged)

### What's Not Implemented (Yet)

Production would benefit from:
- **Network Policies**: Restrict pod-to-pod traffic
- **Pod Security Standards**: Enforce restricted profile cluster-wide
- **OPA/Kyverno**: Policy enforcement for image sources, labels, etc.
- **Secrets management**: External Secrets Operator + AWS Secrets Manager
- **Image scanning**: Block deployment of vulnerable images
- **Runtime security**: Falco for anomaly detection

Current setup follows Kubernetes security best practices. It's solid for a demo but production would need the additional layers above.

## Consequences

**Pros:**
- Containers can't escalate privileges
- Filesystem tampering prevented
- Reduced attack surface (no root, dropped capabilities)

**Cons:**
- More complex container setup (writable volume mounts)
- Some apps may need adjustment to work with read-only fs
