# ADR-0005: Gateway API with NGINX Gateway Fabric

**Status:** Accepted

## Context

Kubernetes Ingress has limitations:
- Vendor-specific annotations for advanced features
- No standard for TCP/UDP
- Limited routing expressiveness

Gateway API is the successor - role-oriented, portable, and more powerful.

## Decision

Use Gateway API with NGINX Gateway Fabric as the implementation.

Resource hierarchy:
```
GatewayClass (cluster-scoped)
  └── Gateway (provisions NLB)
        └── HTTPRoute (per-app routing)
```

TLS handled by cert-manager with Let's Encrypt (Cloudflare DNS validation).

## Consequences

**Pros:**
- Future-proof (Gateway API is the standard going forward)
- Clean separation: infra team owns Gateway, app teams own HTTPRoute
- No vendor annotations in app manifests
- Native support in external-dns and cert-manager

**Cons:**
- Gateway API still evolving
