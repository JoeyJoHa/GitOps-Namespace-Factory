CHART_DIR := helm/nsfactory
TENANTS_DIR := tenants
HELM ?= helm
TENANT ?=

# Targets(Commands):
.PHONY: help lint-chart lint-values template template-all

help: ## Show targets
	@grep -E '^[a-zA-Z0-9_.-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-22s %s\n", $$1, $$2}'

lint-chart: ## Lint with chart defaults only
	$(HELM) lint $(CHART_DIR)

lint-values: ## Lint chart with every tenants/values-*.yaml
	@for f in $(TENANTS_DIR)/values-*.yaml; do \
		echo "==> $$f"; \
		$(HELM) lint $(CHART_DIR) -f "$$f" || exit 1; \
	done

template: ## Render one value file: make template TENANT=values.yaml
	@test -n "$(TENANT)" || (echo "Usage: make template TENANT=values.yaml"; exit 1)
	$(HELM) template nsfactory $(CHART_DIR) -f $(TENANTS_DIR)/$(TENANT)

template-all: ## Render all value files
	@for f in $(TENANTS_DIR)/values-*.yaml; do \
		echo "==> $$f"; \
		$(HELM) template nsfactory $(CHART_DIR) -f "$$f" > /dev/null || exit 1; \
	done