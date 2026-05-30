# Makefile for the GitOps-Namespace-Factory

# Executables
HELM ?= helm
KUBECTL ?= kubectl
MINIKUBE ?= minikube

#Minikube variables
DRIVER ?= podman
RUNTIME ?= cri-o
CPUS ?= 2
MEMORY ?= 7g

# Helm chart variables
CHART_DIR := helm/nsfactory
TENANTS_DIR := tenants
TENANT ?=

#
ARGOCD_DIR := argocd
ARGOCD_NAMESPACE := argocd
ARGOCD_INSTALL_YAML := https://raw.githubusercontent.com/argoproj/argo-cd/refs/tags/stable/manifests/install.yaml
ARGOCD_APPLICATION_YAML := ${ARGOCD_DIR}/application.yaml

# Targets(Commands):
.PHONY: help lint-chart lint-values template template-all cluster-start cluster-stop cluster-delete cluster-status create-namespace deploy-argo verify-crds verify-argocd deploy-appproject deploy-application access-argo demo-start demo-stop

help: ## Show targets
	@grep -E '^[a-zA-Z0-9_.-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-22s %s\n", $$1, $$2}'

lint-chart: ## Lint with chart defaults only
	@$(HELM) lint $(CHART_DIR)

lint-values: ## Lint chart with every tenants/values-*.yaml
	@for file in $(TENANTS_DIR)/values-*.yaml; do \
		echo "==> $$file"; \
		$(HELM) lint $(CHART_DIR) -f "$$file" || exit 1; \
	done

template: ## Render one value file: make template TENANT=values.yaml
	@test -n "$(TENANT)" || (echo "Usage: make template TENANT=values.yaml"; exit 1)
	$(HELM) template nsfactory $(CHART_DIR) -f $(TENANTS_DIR)/$(TENANT)

template-all: ## Render all value files
	@for f in $(TENANTS_DIR)/values-*.yaml; do \
		echo "==> $$f"; \
		$(HELM) template nsfactory $(CHART_DIR) -f "$$f" > /dev/null || exit 1; \
	done

cluster-start: ## Start the cluster
	@$(MINIKUBE) start --driver=$(DRIVER) --container-runtime=$(RUNTIME) --cpus=$(CPUS) --memory=$(MEMORY)

cluster-stop: ## Stop the cluster
	@$(MINIKUBE) stop

cluster-delete: ## Delete the cluster
	@$(MINIKUBE) delete

cluster-status: ## Show the cluster status
	@$(MINIKUBE) status

create-namespace: ## Create the namespace
	@$(KUBECTL) create namespace $(ARGOCD_NAMESPACE) || true

deploy-argo: create-namespace ## Deploy ArgoCD
	@echo "Deploying ArgoCD"
	@$(KUBECTL) apply -f $(ARGOCD_INSTALL_YAML) --server-side --force-conflicts -n $(ARGOCD_NAMESPACE) >/dev/null 2>&1 && sleep 5

verify-crds: ## Verify the CRDs
	@echo "Verifying CRDs:"
	@$(KUBECTL) get crds | grep argoproj.io >/dev/null 2>&1 && echo "  CRDs found" || (echo "CRDs not found, please install ArgoCD"; exit 1)

verify-argocd: ## Verify the ArgoCD installation
	@echo "Waiting for ArgoCD to be ready:"
	@$(KUBECTL) wait --for=jsonpath='{.status.phase}'=Running pod -l app.kubernetes.io/name=argocd-server -n $(ARGOCD_NAMESPACE) --timeout=200s >/dev/null 2>&1 && echo "  ArgoCD running" || (echo "ArgoCD not running, please check the logs"; exit 1)
	@$(KUBECTL) wait --for=create service/argocd-server -n $(ARGOCD_NAMESPACE) --timeout=30s >/dev/null 2>&1 && echo "  ArgoCD service server found" || (echo "ArgoCD service server not found, please check the logs"; exit 1)
	@$(KUBECTL) wait --for=create secret/argocd-initial-admin-secret -n $(ARGOCD_NAMESPACE) --timeout=30s >/dev/null 2>&1 && echo "  ArgoCD initial admin secret found" || (echo "ArgoCD initial admin secret not found, please check the logs"; exit 1)
	
deploy-appproject: verify-crds verify-argocd ## Deploy the application project
	@$(KUBECTL) apply -f $(ARGOCD_DIR)/appproject.yaml -n $(ARGOCD_NAMESPACE) >/dev/null 2>&1 && echo "  AppProject Platform-Apps deployed" || (echo "AppProject not deployed, please check the logs"; exit 1)

deploy-application: ## Deploy the application
	@$(KUBECTL) apply -f $(ARGOCD_DIR)/application.yaml -n $(ARGOCD_NAMESPACE) >/dev/null 2>&1 && echo "  App of Apps deployed" || (echo "App of Apps not deployed, please check the logs"; exit 1)

access-argo: ## Access the ArgoCD UI
	@echo "Argo credentials:"
	@echo "Username: admin"
	@echo "Password: $(shell $(KUBECTL) get secret argocd-initial-admin-secret -n $(ARGOCD_NAMESPACE) -o jsonpath="{.data.password}" | base64 -d)"
	@$(KUBECTL) port-forward svc/argocd-server -n $(ARGOCD_NAMESPACE) 8080:80 & echo "ArgoCD UI is available at http://localhost:8080, to stop the port forward, CTRL+C"

demo-start: cluster-start deploy-argo deploy-appproject deploy-application ## Start the demo cluster and deploy the demo application
	@echo "Demo cluster started and ArgoCD deployed"
	@echo "AppProject and ApplicationSet deployed"
	@echo "ApplicationSet is syncing the applications"
	@echo "Please run 'make access-argo' to access the ArgoCD UI"

demo-stop: cluster-stop cluster-delete ## Stop and delete the demo cluster
