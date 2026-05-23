# EKS Production Platform

Production-grade AWS EKS platform provisioned with Terraform, deployed via Helm, and automated end-to-end with GitHub Actions.

The pipeline runs in three stages: **CI** validates code quality, **Terraform** provisions infrastructure, and **CD** deploys the application — each stage triggering the next automatically on the `dev` branch.

---

## Repository Structure

```
.
├── .github/workflows/
│   ├── ci.yml              # Lint, validate, build, scan
│   ├── terraform.yml       # Provision AWS infrastructure
│   └── cd.yml              # Deploy to EKS via Helm
│
├── terraform/
│   ├── global/s3-backend/  # Remote state bootstrap (S3 + DynamoDB)
│   ├── modules/
│   │   ├── vpc/            # VPC, subnets, NAT gateway
│   │   └── eks/            # EKS cluster, node group, add-ons, IRSA
│   └── envs/
│       ├── dev/            # Dev environment composition
│       └── prod/           # Prod environment composition
│
├── helm/
│   └── eks-production-platform/   # App Helm chart (Deployment, Service, Ingress, HPA)
│
├── k8s/                    # Platform manifests (namespaces, RBAC, quotas, NetworkPolicies, StorageClass)
└── docker/
    └── Dockerfile          # Minimal HTTP echo image
```

---

## Architecture

```
AWS ap-south-1
│
└── VPC 10.0.0.0/16
    ├── Public subnets
    │   ├── NAT Gateway
    │   └── Internet-facing ALB  (provisioned by AWS Load Balancer Controller)
    │
    └── Private subnets
        └── EKS Managed Node Group
            └── Application pods (hello-app)

EKS Cluster
├── Kubernetes 1.32
├── Managed add-ons: VPC CNI · CoreDNS · kube-proxy · EBS CSI
└── IRSA roles: EBS CSI Driver · AWS Load Balancer Controller

State Backend
├── S3 bucket  (versioned, per environment)
└── DynamoDB   (state locking)
```

---

## Environments

| Setting            | Dev                  | Prod                       |
|--------------------|----------------------|----------------------------|
| NAT Gateways       | 1 shared             | 1 per AZ                   |
| EKS nodes          | min 1 / desired 1 / max 3 | min 2 / desired 3 / max 6 |
| App replicas       | 1                    | 3                          |
| HPA                | Disabled             | Enabled (3–10 replicas)    |
| Hostname           | `hello-dev.internal` | `hello.example.com`        |

---

## CI/CD Pipeline

### CI — `.github/workflows/ci.yml`

Triggers on push to `dev` / `main` and on all pull requests.

- `terraform fmt -check` across `terraform/`
- `terraform init` + `terraform validate` for dev and prod
- `helm lint` and `helm template` for dev and prod values
- Docker image build
- Trivy scan (HIGH and CRITICAL vulnerabilities)

### Terraform — `.github/workflows/terraform.yml`

Triggers automatically after CI succeeds on `dev`. Also supports manual dispatch.

**Manual inputs:**

| Input                 | Options                  | Default         |
|-----------------------|--------------------------|-----------------|
| `environment`         | `dev` / `prod`           | `dev`           |
| `action`              | `plan` / `apply` / `destroy` | `plan`      |
| `allowed_cidr_blocks` | JSON CIDR list           | `["0.0.0.0/0"]` |

> `destroy` is restricted to the `dev` environment only.

On `apply`, Terraform outputs (cluster name, endpoint, VPC ID, subnets) are exported as a workflow artifact consumed by the CD job.

**Required secrets:** `AWS_ACCESS_KEY_ID` · `AWS_SECRET_ACCESS_KEY` · `AWS_REGION`

### CD — `.github/workflows/cd.yml`

Triggers automatically after Terraform succeeds.

1. Configures `kubectl` against the correct EKS cluster
2. Creates the Kubernetes namespace if absent
3. Runs `helm upgrade --install` with `--atomic` and `--wait`
4. Verifies rollout with `helm status` and `kubectl rollout status`
5. 

**Required secrets:** `AWS_ACCESS_KEY_ID` · `AWS_SECRET_ACCESS_KEY` · `AWS_REGION` · `AWS_ROLE_ARN`

---

## Getting Started

### Prerequisites

- AWS CLI v2
- Terraform >= 1.5
- kubectl
- Helm >= 3
- An AWS account with permissions to create VPCs, EKS clusters, and IAM roles

### 1. Bootstrap Remote State

Run once per environment before any Terraform apply:

```bash
cd terraform/global/s3-backend
terraform init
terraform apply -var="env=dev"
terraform apply -var="env=prod"
```

### 2. Provision Infrastructure

```bash
cd terraform/envs/dev
terraform init
terraform plan  -var='allowed_cidr_blocks=["203.0.113.10/32"]'
terraform apply -var='allowed_cidr_blocks=["203.0.113.10/32"]'
```

Repeat under `terraform/envs/prod` for the production environment.

### 3. Configure kubectl

```bash
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name eks-cluster-dev
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

### 5. Deploy the Application

```bash
helm upgrade --install eks-production ./helm/eks-production-platform \
  --namespace production \
  --create-namespace \
  --values helm/eks-production-platform/values.yaml \
  --atomic \
  --wait
```

---

## GitHub Actions Setup

Add the following secrets to the repository under **Settings → Secrets and variables → Actions**:

| Secret                  | Description                          |
|-------------------------|--------------------------------------|
| `AWS_ACCESS_KEY_ID`     | IAM access key                       |
| `AWS_SECRET_ACCESS_KEY` | IAM secret key                       |
| `AWS_REGION`            | Target region (e.g. `ap-south-1`)    |

Push to the `dev` branch to trigger the full CI → Terraform → CD pipeline automatically.

---

## Teardown

```bash
# Remove the Helm release
helm uninstall eks-production -n production

# Destroy infrastructure (dev first, prod separately)
cd terraform/envs/dev && terraform destroy
cd terraform/envs/prod && terraform destroy
```

> Destroy the S3 backend last. The state bucket must be emptied manually before Terraform can delete it (versioned buckets are non-empty by default).

---

## Key Design Decisions

**Cluster name read from Terraform outputs, not hardcoded.** The CD workflow parses `cluster_name` from the `terraform-output.json` artifact, so renaming the cluster in Terraform never silently breaks the deploy step.

**Artifact pinned to the exact triggering run.** The CD workflow downloads the Terraform outputs artifact using `run_id: ${{ github.event.workflow_run.id }}`, preventing a race condition where a newer artifact from a different run could be consumed.

**Destroy gated to dev only.** The `Guard Destroy Environment` step in the Terraform workflow exits with an error if `destroy` is requested against `prod`, preventing accidental production teardown via manual dispatch.

**OIDC-ready.** AWS credentials are currently configured with access keys. To switch to keyless authentication, uncomment `role-to-assume` in the workflow files and remove the key/secret inputs.
