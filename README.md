# EKS Production Platform

Production-oriented AWS EKS platform built with Terraform, Kubernetes manifests, Helm, Docker, and GitHub Actions.

This repository provisions the AWS network and EKS foundation, applies baseline Kubernetes guardrails, builds a small container image, and deploys the `hello-app` Helm release into `dev` or `prod`.

## What Is Included

| Area | Path | Purpose |
|---|---|---|
| Terraform environments | `terraform/envs/dev`, `terraform/envs/prod` | Compose the VPC and EKS modules per environment |
| Terraform modules | `terraform/modules/vpc`, `terraform/modules/eks` | Reusable VPC and EKS building blocks |
| Remote state bootstrap | `terraform/global/s3-backend` | S3 state bucket and DynamoDB lock table |
| Helm app | `helm/apps/hello-app` | App Deployment, Service, Ingress, and HPA templates |
| Kubernetes platform manifests | `k8s/` | Namespaces, quotas, limits, RBAC, NetworkPolicies, and gp3 StorageClass |
| Container image | `docker/Dockerfile` | Minimal local HTTP echo demo image |
| Automation | `.github/workflows` | CI validation, Terraform automation, and CD deployment |

## Architecture

```text
AWS ap-south-1

VPC 10.0.0.0/16
  Public subnets
    - NAT gateway
    - Internet-facing ALB from Kubernetes Ingress

  Private subnets
    - EKS managed node group
    - Application pods

EKS
  - Kubernetes 1.32
  - Managed add-ons: VPC CNI, CoreDNS, kube-proxy, EBS CSI
  - IRSA for EBS CSI and AWS Load Balancer Controller

State
  - S3 backend
  - DynamoDB state locking
```

## Environment Differences

| Setting | Dev | Prod |
|---|---:|---:|
| NAT gateways | 1 shared NAT gateway | NAT gateway per AZ |
| EKS desired nodes | 1 | 3 |
| EKS min nodes | 1 | 2 |
| EKS max nodes | 3 | 6 |
| App replicas | 1 | 3 |
| App HPA | Disabled | Enabled, 3 to 10 replicas |
| App hostname | `hello-dev.internal` | `hello.example.com` |

## Workflows

### CI

`.github/workflows/ci.yml` runs on pushes to `dev` and `main`, and on pull requests.

It checks:

- Terraform formatting across `terraform/`
- Terraform init and validate for `dev`
- Terraform init and validate for `prod`
- Helm chart linting
- Helm rendering for dev and prod values
- Docker image build
- Trivy image scan for high and critical vulnerabilities

### Terraform

`.github/workflows/terraform.yml` runs after successful CI on `dev`, and also supports manual `plan` or `apply` for `dev` and `prod`.

Required GitHub secrets:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

Recommended GitHub variables:

- `AWS_REGION`, defaults to `ap-south-1`
- `ALLOWED_CIDR_BLOCKS`, JSON list used for EKS public API access

Example:

```json
["203.0.113.10/32"]
```

### CD

`.github/workflows/cd.yml` runs after the Terraform workflow succeeds on `dev`, and supports manual deployment to `dev` or `prod`.

It builds and pushes the image to GitHub Container Registry, installs or upgrades the AWS Load Balancer Controller, applies Kubernetes platform manifests, deploys the Helm release, and verifies the rollout.

## Deployment

### 1. Bootstrap Remote State

Run once for each environment that needs its own state backend:

```bash
cd terraform/global/s3-backend
terraform init
terraform apply -var="env=dev"
terraform apply -var="env=prod"
```

### 2. Deploy Infrastructure

```bash
cd terraform/envs/dev
terraform init
terraform plan -var='allowed_cidr_blocks=["203.0.113.10/32"]'
terraform apply -var='allowed_cidr_blocks=["203.0.113.10/32"]'
```

For prod:

```bash
cd terraform/envs/prod
terraform init
terraform plan -var='allowed_cidr_blocks=["203.0.113.10/32"]'
terraform apply -var='allowed_cidr_blocks=["203.0.113.10/32"]'
```

### 3. Configure kubectl

```bash
aws eks update-kubeconfig --region ap-south-1 --name eks-cluster-dev
```

### 4. Apply Platform Manifests

```bash
kubectl apply -f k8s/namespaces/
kubectl apply -f k8s/network/
kubectl apply -f k8s/quotas/
kubectl apply -f k8s/limits/
kubectl apply -f k8s/rbac/
kubectl apply -f k8s/storage/
```

### 5. Deploy the App

```bash
helm upgrade --install hello-app ./helm/apps/hello-app \
  --namespace dev \
  --create-namespace \
  --values helm/apps/hello-app/values.yaml \
  --values helm/apps/hello-app/values-dev.yml
```

## Validation Proof

These checks were run locally from this repository after the fixes:

| Check | Result |
|---|---|
| `terraform fmt -recursive terraform` | Passed |
| `terraform init -backend=false` in `terraform/envs/dev` | Passed |
| `terraform validate` in `terraform/envs/dev` | Passed: configuration is valid |
| `terraform init -backend=false` in `terraform/envs/prod` | Passed |
| `terraform validate` in `terraform/envs/prod` | Passed: configuration is valid |
| `rg -n "[^[:ascii:]]" README.md terraform helm k8s docker .github` | Passed: no matches after cleanup |

Local limitations:

- Helm is not installed on this workstation, so `helm lint` and `helm template` are validated by GitHub Actions rather than locally.
- Docker is not installed on this workstation, so image build and Trivy scan are validated by GitHub Actions rather than locally.
- GitHub CLI is installed but not authenticated on this workstation, so the real GitHub Actions workflow could not be dispatched locally with `gh`.

## GitHub Actions Proof Checklist

After pushing this branch, verify the pipeline with:

```bash
gh auth login
gh workflow run CI --ref dev
gh run list --workflow CI --limit 5
```

Expected result:

- CI completes successfully.
- Terraform workflow starts after CI succeeds on `dev`.
- CD workflow starts after Terraform succeeds on `dev`.
- Manual `prod` workflow dispatch remains gated by the `prod` environment.

## Teardown

```bash
helm uninstall hello-app -n dev
helm uninstall hello-app -n prod

cd terraform/envs/dev
terraform destroy

cd ../prod
terraform destroy
```

Destroy the S3 backend last. Empty the state bucket before destroying it because Terraform cannot delete a non-empty versioned bucket.
