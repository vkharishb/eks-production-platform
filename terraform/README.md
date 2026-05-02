# terraform/

This directory contains reusable **modules** and per-environment **roots**.

## Layout

```
terraform/
├── global/
│   └── s3-backend/     # Bootstrap once per AWS account: S3 + DynamoDB
├── modules/
│   ├── eks/            # Reusable EKS cluster module
│   └── vpc/            # Reusable VPC module
└── envs/
    └── dev/            # Dev environment root — run terraform here
```

## Note

The root-level `providers.tf`, `variables.tf`, and `versions.tf` files that
previously existed here have been removed. They defined an AWS provider with
no corresponding `main.tf` or backend config, creating a ghost Terraform root
that would produce orphaned state if `terraform init` was run here.

Each environment under `envs/` has its own complete set of provider, version,
and backend configuration.
