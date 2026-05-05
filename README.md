# EKS Production Platform

A production-grade AWS EKS platform built with Terraform, Helm, and Kubernetes manifests — demonstrating infrastructure-as-code best practices, GitOps-ready structure, and cloud-native application deployment patterns.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS (ap-south-1)                     │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    VPC (10.0.0.0/16)                 │   │
│  │                                                      │   │
│  │  ┌─────────────────┐      ┌─────────────────┐        │   │
│  │  │  Public Subnets  │      │ Private Subnets  │        │   │
│  │  │  (AZ-a, AZ-b)   │      │  (AZ-a, AZ-b)   │        │   │
│  │  │                 │      │                 │        │   │
│  │  │  ┌───────────┐  │      │  ┌───────────┐  │        │   │
│  │  │  │    ALB    │  │      │  │  EKS Node │  │        │   │
│  │  │  │ (Ingress) │  │      │  │  Group    │  │        │   │
│  │  │  └─────┬─────┘  │      │  └─────┬─────┘  │        │   │
│  │  │        │        │      │        │        │        │   │
│  │  │  ┌─────▼─────┐  │      │  ┌─────▼─────┐  │        │   │
│  │  │  │    NAT    │◄─┼──────┼──│  EKS      │  │        │   │
│  │  │  │  Gateway  │  │      │  │  Cluster  │  │        │   │
│  │  │  └───────────┘  │      │  └───────────┘  │        │   │
│  │  └─────────────────┘      └─────────────────┘        │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────┐   ┌──────────────┐   ┌────────────────┐   │
│  │  S3 Backend  │   │   DynamoDB   │   │   IAM / IRSA   │   │
│  │  (TF State)  │   │  State Lock  │   │    (OIDC)      │   │
│  └──────────────┘   └──────────────┘   └────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Tool | Purpose |
|---|---|---|
| Infrastructure | Terraform | VPC, EKS cluster, IAM, S3 backend |
| Container Orchestration | AWS EKS (K8s 1.32) | Managed Kubernetes control plane |
| Package Management | Helm | App deployment with environment overrides |
| Networking | AWS VPC CNI, ALB Ingress Controller | Pod networking, external traffic routing |
| Autoscaling | HPA (autoscaling/v2) | CPU-based horizontal pod autoscaling |
| Storage | EBS CSI Driver (gp3) | Persistent volume provisioning |
| Security | IRSA, RBAC, NetworkPolicy | Least-privilege IAM, pod-level access control |
| State Management | S3 + DynamoDB | Remote state with locking |

---

## Repository Structure

```
eks-production-platform/
├── terraform/
│   ├── global/
│   │   └── s3-backend/          # Bootstrap: S3 bucket + DynamoDB lock table
│   ├── modules/
│   │   ├── eks/                 # EKS cluster, node groups, add-ons, IAM
│   │   └── vpc/                 # VPC, subnets, NAT gateway, subnet tags
│   └── envs/
│       └── dev/                 # Dev environment root module
│           ├── main.tf          # Module composition
│           ├── providers.tf     # AWS provider + default tags
│           ├── versions.tf      # S3 backend + provider version pins
│           └── outputs.tf       # Cluster name, endpoint, VPC outputs
│
├── helm/
│   └── apps/
│       └── hello-app/           # Production-ready Helm chart
│           ├── templates/
│           │   ├── deployment.yml
│           │   ├── service.yml
│           │   ├── ingress.yml
│           │   └── hpa.yml
│           ├── values.yaml      # Base values
│           ├── values-dev.yml   # Dev overrides (1 replica, HPA off)
│           └── values-prod.yml  # Prod overrides (3 replicas, HPA on)
│
├── k8s/
│   ├── namespaces/              # dev + prod namespace definitions
│   ├── network/                 # Default-deny + allow-internal NetworkPolicies
│   ├── quotas/                  # ResourceQuota per namespace
│   ├── limits/                  # LimitRange default CPU/memory
│   ├── rbac/                    # Read-only Role + RoleBinding for developers
│   └── storage/                 # gp3 StorageClass (WaitForFirstConsumer)
│
└── docker/
    └── Dockerfile               # Container image definition
```

---

## Key Design Decisions

### Modular Terraform Layout
Infrastructure is split into reusable modules (`vpc`, `eks`) and environment-specific roots (`envs/dev`). This mirrors real-world team structures where platform and application teams own separate layers.

### Remote State with Locking
Terraform state is stored in S3 with DynamoDB-backed state locking, preventing concurrent apply conflicts across team members or CI pipelines.

### IRSA (IAM Roles for Service Accounts)
The EBS CSI driver uses IRSA via OIDC federation rather than node-level IAM policies. This scopes AWS permissions to individual workloads, following least-privilege principles.

### EKS Managed Add-ons
Core components (VPC CNI, kube-proxy, CoreDNS, EBS CSI) are deployed as EKS managed add-ons. This delegates version lifecycle management to AWS and simplifies cluster upgrades.

### Helm Values Layering
The Helm chart uses a base `values.yaml` with environment-specific overrides (`values-dev.yml`, `values-prod.yml`). This keeps environment differences explicit and minimal, and the same chart can be promoted through environments without modification.

### Network Isolation
Namespaces start with a default-deny NetworkPolicy and selectively allow intra-namespace pod communication. This contains blast radius in the event of a compromised pod.

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.3.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with sufficient IAM permissions
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/) >= 3.x

---

## Getting Started

### 1. Bootstrap remote state

```bash
cd terraform/global/s3-backend
terraform init
terraform apply
```

This creates the S3 bucket and DynamoDB table used to store Terraform state for all environments.

### 2. Deploy the dev environment

```bash
cd terraform/envs/dev
terraform init
terraform plan
terraform apply
```

### 3. Configure kubectl

```bash
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name eks-cluster-dev
```

### 4. Apply Kubernetes manifests

```bash
# Namespaces first
kubectl apply -f k8s/namespaces/

# Then supporting resources
kubectl apply -f k8s/network/
kubectl apply -f k8s/quotas/
kubectl apply -f k8s/limits/
kubectl apply -f k8s/rbac/
kubectl apply -f k8s/storage/
```

### 5. Deploy the application

```bash
# Deploy to dev namespace
helm upgrade --install hello-app ./helm/apps/hello-app \
  --namespace dev \
  --values helm/apps/hello-app/values.yaml \
  --values helm/apps/hello-app/values-dev.yml

# Deploy to prod namespace
helm upgrade --install hello-app ./helm/apps/hello-app \
  --namespace prod \
  --values helm/apps/hello-app/values.yaml \
  --values helm/apps/hello-app/values-prod.yml
```

---

## Environment Configuration

| Parameter | Dev | Prod |
|---|---|---|
| Replicas | 1 | 3 |
| HPA | Disabled | Enabled (3–10 replicas) |
| HPA CPU target | — | 70% |
| Node capacity type | ON_DEMAND | ON_DEMAND |
| NAT Gateway | Single | One per AZ (recommended) |

---

## Teardown

```bash
# Remove Helm releases
helm uninstall hello-app -n dev
helm uninstall hello-app -n prod

# Destroy infrastructure
cd terraform/envs/dev
terraform destroy

# Destroy state backend (last)
cd terraform/global/s3-backend
terraform destroy
```

> **Note:** Empty the S3 bucket manually before destroying it, as Terraform cannot delete non-empty buckets by default.

---

## Author

**Harish** · [GitHub](https://github.com/vkharishb)
