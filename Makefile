JQ ?= jq
SHELLCHECK ?= shellcheck

.PHONY: check lint lint-sh lint-jq deps

check: lint

lint: lint-sh lint-jq

lint-sh:
	@if command -v $(SHELLCHECK) >/dev/null 2>&1; then \
		$(SHELLCHECK) ror.sh; \
	else \
		echo "shellcheck not found; skipping shell lint"; \
	fi
	@bash -n ror.sh

lint-jq:
	@printf '[]' | $(JQ) -L lib -f ws.jq >/dev/null

deps:
	@missing=0; \
	for bin in jq niri; do \
		if ! command -v $$bin >/dev/null 2>&1; then \
			echo "Missing dependency: $$bin"; \
			missing=1; \
		fi; \
	done; \
	if [ $$missing -ne 0 ]; then \
		exit 1; \
	fi; \
	echo "All required dependencies present."
