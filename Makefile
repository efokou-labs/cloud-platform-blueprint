.PHONY: verify kind-up kind-down argocd-port-forward fmt validate help

CLUSTER ?= portfolio
TERRAFORM_IMAGE ?= hashicorp/terraform:1.9.8
TF_DIRS := envs/dev envs/staging envs/prod
TF := docker run --rm -v "$(CURDIR):/src" -w /src $(TERRAFORM_IMAGE)

help:
	@echo "verify              fmt + validate all env roots"
	@echo "kind-up             create kind cluster and bootstrap Helm components"
	@echo "kind-down           delete the kind cluster"
	@echo "argocd-port-forward expose Argo CD server on localhost:8080"

verify: fmt validate
	@echo "cloud-platform-blueprint verify passed"

fmt:
	@for d in $(TF_DIRS); do \
		$(TF) -chdir=$$d fmt -check -recursive || $(TF) -chdir=$$d fmt -recursive; \
	done

validate:
	@for d in $(TF_DIRS); do \
		$(TF) -chdir=$$d init -backend=false -input=false >/tmp/tf-init-$$(basename $$d).log; \
		$(TF) -chdir=$$d validate; \
	done

kind-up:
	@command -v kind >/dev/null || { echo "Install kind: https://kind.sigs.k8s.io/docs/user/quick-start/"; exit 1; }
	@command -v helm >/dev/null || { echo "Install helm: https://helm.sh/docs/intro/install/"; exit 1; }
	@command -v kubectl >/dev/null || { echo "Install kubectl"; exit 1; }
	kind create cluster --name $(CLUSTER) --config hack/kind/cluster.yaml
	kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
	kubectl -n kube-system patch deploy metrics-server --type='json' \
		-p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' || true
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo add argo https://argoproj.github.io/argo-helm
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
	helm repo update
	helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
		--namespace ingress-nginx --create-namespace \
		-f bootstrap/values/ingress-nginx.yaml --wait --timeout 5m
	helm upgrade --install argocd argo/argo-cd \
		--namespace argocd --create-namespace \
		-f bootstrap/values/argocd.yaml --wait --timeout 8m
	helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
		--namespace observability --create-namespace \
		-f bootstrap/values/otel-collector.yaml --wait --timeout 5m
	@echo "Optional (heavy): helm upgrade --install kps prometheus-community/kube-prometheus-stack -n observability -f bootstrap/values/kube-prometheus-stack.yaml"
	@echo "kind cluster '$(CLUSTER)' is ready. Next: apply kubernetes-gitops root Application."

kind-down:
	@command -v kind >/dev/null || { echo "kind not installed"; exit 1; }
	kind delete cluster --name $(CLUSTER)

argocd-port-forward:
	kubectl -n argocd port-forward svc/argocd-server 8080:443
