JQ ?= jq
SHELLCHECK ?= shellcheck
NOTIFY_CMD ?= $(ROR_NOTIFY_CMD)
DEFAULT_NOTIFY ?= notify-send

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
	notify_str="$${NOTIFY_CMD:-$(DEFAULT_NOTIFY)}"; \
	notify_bin="$$(set -- $$notify_str; echo $$1)"; \
	if [ -n "$$notify_bin" ] && ! command -v $$notify_bin >/dev/null 2>&1; then \
		echo "Missing notification command: $$notify_bin (set ROR_NOTIFY_CMD or NOTIFY_CMD to change, or set empty to skip)"; \
		missing=1; \
	fi; \
	if [ $$missing -ne 0 ]; then \
		exit 1; \
	fi; \
	echo "All required dependencies present."
