---
paths:
  - "**/*.tf"
  - "**/*.tfvars"
  - "**/*.hcl"
---
# Terraform

- Plan Review: Before `terraform apply`, confirm the plan has no unintended destroy or replace, and map every planned change, each destroy / replace included, to a concrete intended edit. Do not explain unexplained drift with "probably"; read the module source and state the mechanism.
