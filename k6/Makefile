DEV_URL := http://csv.local
PROD_URL := https://csv.souzaxx.dev

.PHONY: help dev prod smoke

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  dev    Run load test against local dev (csv.local)"
	@echo "  prod   Run load test against production"
	@echo "  smoke  Quick smoke test (10 users, 30s)"
	@echo ""

dev:
	@echo "Load testing dev environment: $(DEV_URL)"
	k6 run -e TARGET_URL=$(DEV_URL) load-test.js

prod:
	@echo "Load testing production: $(PROD_URL)"
	k6 run -e TARGET_URL=$(PROD_URL) load-test.js

smoke:
	@echo "Smoke test against dev: $(DEV_URL)"
	k6 run -e TARGET_URL=$(DEV_URL) --vus 10 --duration 30s load-test.js
