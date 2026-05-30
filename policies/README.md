# Compliance Policies (AWS)

Rego policies for OPA that evaluate `terraform plan -json` output against NIST 800-53 controls before any infrastructure is deployed.

## Policies

| File | Control | Severity | What it enforces |
|---|---|---|---|
| `sc28_encryption.rego` | SC-28 | High | Every `aws_s3_bucket` must have a corresponding `aws_s3_bucket_server_side_encryption_configuration` using `aws:kms` |
| `ac3_no_public.rego` | AC-3 | Critical | S3 buckets must have all four public access block flags set to `true`; security groups must not expose ports 22 or 3389 to `0.0.0.0/0` |
| `cm6_required_tags.rego` | CM-6 | Medium | Every `aws_s3_bucket`, `aws_instance`, and `aws_ebs_volume` must carry the tags `project`, `environment`, `managed_by`, and `compliance_scope` |

## Remediation

**SC-28** — Add to your Terraform:
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "aws:kms" }
  }
}
```

**AC-3 (bucket)** — Add to your Terraform:
```hcl
resource "aws_s3_bucket_public_access_block" "example" {
  bucket                  = aws_s3_bucket.example.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

**AC-3 (security group)** — Remove or narrow `cidr_blocks` on ports 22 and 3389.

**CM-6** — Add to every resource:
```hcl
tags = {
  project          = "<value>"
  environment      = "<value>"
  managed_by       = "terraform"
  compliance_scope = "<value>"
}
```

## Running the policies

```bash
# Run all unit tests
opa test -v policies/

# Evaluate against a real plan
opa eval -d policies/ -i terraform/plan.json "data.compliance.sc28.deny" --format=pretty
opa eval -d policies/ -i terraform/plan.json "data.compliance.ac3.deny"  --format=pretty
opa eval -d policies/ -i terraform/plan.json "data.compliance.cm6.deny"  --format=pretty
```