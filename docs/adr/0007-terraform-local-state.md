# ADR-0007: Terraform Local State

**Status:** Accepted

## Context

Terraform needs state management. Production best practice is remote state (S3 + DynamoDB) with CI/CD pipelines.

This is a demo with a single operator.

## Decision

- Local state (no S3 backend)
- Manual runs (no CI/CD pipeline)

Remote state benefits that don't apply here:
- Team collaboration
- State locking
- Disaster recovery

## Production Alternative

```hcl
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "ounass-eks/terraform.tfstate"
    region         = "me-central-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

Add GitHub Actions or Atlantis for plan-on-PR and approval gates.

## Consequences

**Pros:**
- No setup overhead for demo

**Cons:**
- State only on operator's machine
- Not suitable for teams
