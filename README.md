# Cloud platform blueprint

Flagship infrastructure repository. It creates the platform that the other portfolio workloads consume.

**Default target:** kind (this laptop). **Documented cloud:** AWS (env roots under `envs/`). Do not leave EKS running.

## Architecture

```text
Makefile kind-up
        |
        v
   kind cluster (portfolio)
        |
        +-- ingress-nginx
        +-- metrics-server
        +-- Argo CD
        +-- kube-prometheus-stack (optional, heavier)
        `-- OpenTelemetry Collector
        |
        v
  kubernetes-gitops (desired state)

Terraform envs/dev|staging|prod
        |
        v
   AWS account (ephemeral)
        |
        +-- VPC
        +-- EKS
        +-- ECR
        +-- RDS PostgreSQL
        +-- Secrets Manager
        `-- budget alarm
```

## Verify

```bash
make verify
```

Bring up the local platform (requires Docker, kind, helm, kubectl):

```bash
make kind-up
# Argo CD UI: https://localhost:8080  (see make argocd-port-forward)
make kind-down
```

`terraform plan` against AWS is **not** the default. Use it only in a sandbox account with a $10 budget alarm, then destroy.

## Repository map

This repo provisions. [kubernetes-gitops](https://github.com/EtienneFokou-E18560/kubernetes-gitops) holds desired workload state. Modules are published from [terraform-modules](https://github.com/EtienneFokou-E18560/terraform-modules).

## CI

Pull requests run `terraform fmt`, `validate`, tflint, and Checkov. `terraform plan` runs only when AWS OIDC is configured on the GitHub environment.

## Reusable workflows

App repositories may call:

```yaml
jobs:
  python:
    uses: EtienneFokou-E18560/cloud-platform-blueprint/.github/workflows/python-ci.yml@main
```
