# Deploy from zero

## Laptop (default)

1. Install Docker, kubectl, [kind](https://kind.sigs.k8s.io/), and [Helm](https://helm.sh/).
2. `make kind-up`
3. Clone [kubernetes-gitops](https://github.com/EtienneFokou-E18560/kubernetes-gitops) and apply the root Application (see that README).
4. `make kind-down` when finished. Nothing should keep running in AWS.

## AWS sandbox (ephemeral)

1. Create a dedicated AWS account. Enable a **$10** monthly budget (this repo also defines `aws_budgets_budget`).
2. Configure GitHub OIDC (`iam-oidc` role); never create long-lived access keys for Actions.
3. From `envs/dev`: `terraform init`, `terraform plan`. Apply only if you will destroy the same day.
4. Staging and production roots are **plan-only** until a GitHub Environment approval exists.
5. `terraform destroy` is mandatory after the demo. NAT, EKS, and RDS are the cost traps.

Remote state: copy the commented S3 backend in `envs/*/backend.tf` once a lock table exists.
