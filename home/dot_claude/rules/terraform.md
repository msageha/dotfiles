---
paths:
  - "**/*.tf"
  - "**/*.tfvars"
  - "**/*.hcl"
---
# Terraform

- Plan Review: Before `terraform apply`, confirm `destroy = 0` and map every planned change to a concrete intended edit. Do not explain unexplained drift with "probably"; read the module source and state the mechanism.
