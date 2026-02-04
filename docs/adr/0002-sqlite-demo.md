# ADR-0002: SQLite for Demo

**Status:** Accepted

## Context

The csv-uploader needs a database. This is a demo project - the goal is showcasing infrastructure patterns, not production data persistence.

## Decision

Use SQLite with a PVC (EBS gp2).

Accepted trade-offs:
- No HA or replication
- Single-writer limitation
- Data loss on PVC deletion is acceptable

## Production Alternative

Replace with RDS PostgreSQL or Aurora Serverless. The app uses SQLAlchemy, so migration is just changing `DATABASE_URL` and adding the driver.

## Consequences

**Pros:**
- Zero operational overhead
- Simple deployment (single file)
- Good enough for demo

**Cons:**
- Not suitable for production workloads
- No point-in-time recovery
