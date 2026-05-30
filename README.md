# Lab 3.3: Writing Compliance Policies in Rego (AWS)

Policy-as-code library using OPA (Open Policy Agent) and Rego to enforce NIST 800-53 compliance controls against `terraform plan` output — before any infrastructure is deployed to AWS.

## What this lab does

Evaluates a Terraform plan JSON file against three compliance policies and flags violations with the control ID and exact remediation step. Nothing is deployed to AWS — this is a plan-only preventive control.

## Policies

| Policy | NIST Control | Severity | Enforces |
|---|---|---|---|
| `sc28_encryption.rego` | SC-28 | High | KMS encryption on every S3 bucket |
| `ac3_no_public.rego` | AC-3 | Critical | S3 public access blocked; no SSH/RDP open to internet |
| `cm6_required_tags.rego` | CM-6 | Medium | Four required tags on every taggable resource |

## Results against the test fixture

```
[SC-28] aws_s3_bucket.bad_no_kms: missing KMS encryption.
[AC-3] aws_s3_bucket.bad_public: public access not fully blocked.
[AC-3] aws_security_group.open_ssh: management port 22 open to 0.0.0.0/0.
[CM-6] aws_s3_bucket.bad_no_tags: missing required tags ["compliance_scope", "environment", "managed_by", "project"].
```

`aws_s3_bucket.good` is silent across all three policies.

## Prerequisites

- OPA >= 1.0.0 — [Download](https://github.com/open-policy-agent/opa/releases/latest)
- Terraform >= 1.6

## Usage

```bash
# Run all 9 unit tests
opa test -v policies/

# Evaluate against the included plan
opa eval -d policies/ -i terraform/plan.json "data.compliance.sc28.deny" --format=pretty
opa eval -d policies/ -i terraform/plan.json "data.compliance.ac3.deny"  --format=pretty
opa eval -d policies/ -i terraform/plan.json "data.compliance.cm6.deny"  --format=pretty
```

## Project structure

```
policies/               Rego policies with NIST METADATA blocks
policies/tests/         Unit test fixtures (9 tests, 3 per policy)
policies/README.md      Per-policy control reference and remediation guide
terraform/main.tf       AWS test fixture (compliant + non-compliant resources)
terraform/plan.json     Generated plan evaluated by the policies
evidence/lab-3-3/       OPA test results JSON (portfolio evidence)
```
