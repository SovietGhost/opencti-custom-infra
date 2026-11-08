.DEFAULT_GOAL := help
COMPOSE := docker compose

help: ## Show targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'

env: ## Generate .env (idempotent; keeps existing values)
	scripts/generate-env.sh

upstream: ## Re-fetch official OpenCTI compose files (REF=master)
	scripts/fetch-upstream.sh $(REF)

config: ## Validate the merged compose model
	$(COMPOSE) config --quiet && echo "compose OK"

up: ## Start the stack (honours COMPOSE_PROFILES in .env)
	$(COMPOSE) up -d

down: ## Stop the stack
	$(COMPOSE) down

logs: ## Tail logs (SVC=connector-alienvault to filter)
	$(COMPOSE) logs -f --tail=100 $(SVC)
