# Lab 3.3: Writing Compliance Policies in Rego (AWS)

Policy-as-code library using OPA (Open Policy Agent) and Rego to enforce NIST 800-53 compliance controls against `terraform plan` output — before any infrastructure is deployed to AWS.

---

## 1. What this lab is

This lab builds a set of automated compliance gates written in Rego that evaluate a `terraform plan -json` file against NIST 800-53 controls. Three policies are implemented targeting AWS resources: encryption at rest (SC-28), access enforcement (AC-3), and required configuration tags (CM-6). The policies run against `plan.json` — the same artifact captured as tamper-evident evidence in Lab 2.5 — meaning compliance is enforced at the earliest possible point in the deployment pipeline, before `terraform apply` is ever executed.

---

## 2. Why it matters

Most compliance programs detect violations after infrastructure is deployed — through security scans, config rules, or audit findings. By the time a non-compliant resource is discovered, it may have been live for weeks or months.

This lab implements a **preventive control**: the policies act as a gate that rejects non-compliant Terraform plans before any resource reaches AWS. A developer who forgets to add KMS encryption or leaves SSH open to the internet gets an immediate, actionable error message with the exact NIST control ID and the fix required. No GRC ticket, no audit finding, no breach.

In an audit scenario, this answers the hardest question an assessor asks:

> *"What technical control prevents a non-compliant resource from ever being deployed?"*

The answer is this policy library, the test results in `evidence/lab-3-3/`, and the CI/CD integration that runs it on every pull request.

---

## 3. Key design decisions

**AWS resource correlation at plan time.** Unlike GCP where encryption and access settings are nested inside the bucket resource itself, AWS splits these into separate resources (`aws_s3_bucket_server_side_encryption_configuration`, `aws_s3_bucket_public_access_block`). At plan time, Terraform cannot resolve cross-resource references — the `bucket` field in these resources shows as `(known after apply)` in `plan.json`.

To solve this, each policy uses a `resource_name()` helper that extracts the suffix from a resource address (e.g., `aws_s3_bucket.good` → `good`) and matches it to the corresponding control resource (`aws_s3_bucket_server_side_encryption_configuration.good` → `good`). This lets the policies correlate buckets to their controls without needing a resolved bucket ID.

**One deny rule per control, not per symptom.** Each policy reports a violation against the `aws_s3_bucket` address, not the missing child resource. This means the developer sees exactly which bucket is non-compliant and what to add — not a generic parse error about a missing resource type.

---

## 4. Results

Policies evaluated against `terraform/plan.json` (13 resources: 4 buckets, 4 SSE configs, 4 public access blocks, 1 security group):

```
SC-28 violations:
  [SC-28] aws_s3_bucket.bad_no_kms: missing KMS encryption. Remediation: add
  aws_s3_bucket_server_side_encryption_configuration with sse_algorithm = "aws:kms".

AC-3 violations:
  [AC-3] aws_s3_bucket.bad_public: public access not fully blocked. Remediation:
  add aws_s3_bucket_public_access_block with all four flags set to true.
  [AC-3] aws_security_group.open_ssh: management port 22 open to 0.0.0.0/0.
  Remediation: narrow cidr_blocks or remove the ingress rule.

CM-6 violations:
  [CM-6] aws_s3_bucket.bad_no_tags: missing required tags ["compliance_scope",
  "environment", "managed_by", "project"]. Remediation: add the missing tags.
```

`aws_s3_bucket.good` is **silent across all three policies** — no false positives.

Unit test suite: **PASS 9/9** (3 tests per policy: compliant passes, wrong value fails, missing config fails).

---

## 5. How to reproduce

**Prerequisites:** OPA >= 1.0.0 ([download](https://github.com/open-policy-agent/opa/releases/latest)), Terraform >= 1.6, AWS CLI with a configured `default` profile.

**Generate the plan:**
```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform show -json tfplan > plan.json
```

**Run all unit tests:**
```bash
opa test -v policies/
```

**Evaluate against the plan:**
```bash
opa eval -d policies/ -i terraform/plan.json "data.compliance.sc28.deny" --format=pretty
opa eval -d policies/ -i terraform/plan.json "data.compliance.ac3.deny"  --format=pretty
opa eval -d policies/ -i terraform/plan.json "data.compliance.cm6.deny"  --format=pretty
```

Nothing is deployed to AWS. This lab is plan-only — `terraform apply` is never run.

---

## Project structure

```
policies/               Rego policies with NIST 800-53 METADATA blocks
policies/tests/         Unit test fixtures (9 tests, 3 per policy)
policies/README.md      Per-policy control reference and remediation guide
terraform/main.tf       AWS test fixture (compliant + intentionally non-compliant resources)
terraform/plan.json     Generated plan evaluated by the policies
evidence/lab-3-3/       opa-test-results.json (portfolio evidence, PASS 9/9)
```
