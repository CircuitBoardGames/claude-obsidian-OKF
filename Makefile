# claude-obsidian deterministic developer entry points.

<<<<<<< HEAD
.PHONY: test test-address test-tiling test-boundary test-bm25 test-retrieve \
        test-lock test-concurrent test-mode test-contextual test-hot-cache \
        setup-dragonscale setup-retrieve setup-mode clean-test-state help

help:
	@echo "claude-obsidian developer targets:"
	@echo "  make test              Run all v1.7 tests (DragonScale + retrieval + concurrency)"
	@echo "  make test-address     scripts/allocate-address.sh tests (shell)"
	@echo "  make test-tiling      scripts/tiling-check.py tests (python, no ollama required)"
	@echo "  make test-boundary    scripts/boundary-score.py tests (python, no prereqs)"
	@echo "  make test-bm25        scripts/bm25-index.py tests (python, hermetic)"
	@echo "  make test-retrieve    scripts/retrieve.py + rerank.py tests (python, hermetic)"
	@echo "  make test-lock        scripts/wiki-lock.sh tests (shell, hermetic)"
	@echo "  make test-concurrent  multi-writer correctness gate (shell, hermetic)"
	@echo "  make test-mode        scripts/wiki-mode.py tests (python, hermetic)"
	@echo "  make test-contextual  scripts/contextual-prefix.py cache-floor tests (python, hermetic)"
	@echo "  make test-hot-cache   scripts/hot-cache-stale.sh + hooks.json shell validity (shell, hermetic)"
	@echo "  make setup-dragonscale Run bin/setup-dragonscale.sh against this vault"
	@echo "  make setup-retrieve   Run bin/setup-retrieve.sh against this vault (opt-in v1.7)"
	@echo "  make setup-mode       Run bin/setup-mode.sh to pick a methodology mode (opt-in v1.8)"
	@echo "  make clean-test-state Remove runtime lockfiles and tiling/embed caches"

test: test-address test-tiling test-boundary test-bm25 test-retrieve test-lock test-concurrent test-mode test-contextual test-hot-cache
	@echo ""
	@echo "All tests passed."
=======
PYTHON ?= python3
export PYTHONDONTWRITEBYTECODE := 1

.PHONY: help test test-python test-shell test-contracts test-package validate \
	setup-dragonscale setup-retrieve setup-mode clean-test-state

help:
	@echo "claude-obsidian developer targets:"
	@echo "  make test             Run every hermetic Python and shell test, then contracts"
	@echo "  make test-python      Run each tests/test_*.py file in isolation"
	@echo "  make test-shell       Run each tests/test_*.sh file in isolation"
	@echo "  make test-contracts   Execute canonical product/capability verification"
	@echo "  make test-package     Validate portable skill, hook, and manifest metadata"
	@echo "  make validate         Run package and contract validators without the test suite"
	@echo "  make setup-*          Run an opt-in legacy extension setup helper"

test: test-python test-shell test-contracts test-package
	@echo "All hermetic tests and executable contracts passed."
>>>>>>> 1c1bc49c03a685ee8f5d09c99efe52b42d6673f5

test-python:
	@set -eu; for test_file in tests/test_*.py; do \
		echo "=== $$test_file ==="; \
		$(PYTHON) "$$test_file"; \
	done

test-shell:
	@set -eu; for test_file in tests/test_*.sh; do \
		echo "=== $$test_file ==="; \
		bash "$$test_file"; \
	done

test-contracts:
	@$(PYTHON) scripts/claude-obsidian.py contracts --check-only
	@$(PYTHON) scripts/claude-obsidian.py contracts --verify

test-package:
	@$(PYTHON) scripts/claude-obsidian.py package validate

validate: test-contracts test-package

test-hot-cache:
	@echo "=== test_hot_cache_hook.sh ==="
	@bash tests/test_hot_cache_hook.sh

setup-dragonscale:
	@bash bin/setup-dragonscale.sh

setup-retrieve:
	@bash bin/setup-retrieve.sh

setup-mode:
	@bash bin/setup-mode.sh

clean-test-state:
	@rm -rf .vault-meta/mutation.lock .vault-meta/mutation.lock.reaping-* \
		.vault-meta/transactions .vault-meta/capture .vault-meta/capabilities \
		.vault-meta/chunks .vault-meta/bm25 .vault-meta/locks \
		.vault-meta/.address.lock.d .vault-meta/.address.lock.d.reaping-* \
		.vault-meta/.address.lock.d.reaper \
		.vault-meta/.wiki-lock.meta.d .vault-meta/.wiki-lock.meta.d.reaping-* \
		.vault-meta/.wiki-lock.meta.d.reaper
	@rm -f .vault-meta/.address.lock .vault-meta/.tiling.lock .vault-meta/.bm25.lock \
		.vault-meta/.embed-cache.lock .vault-meta/.wiki-lock.meta \
		.vault-meta/tiling-cache.json .vault-meta/tiling-cache.*.tmp \
		.vault-meta/embed-cache.json .vault-meta/embed-cache.*.tmp \
		.vault-meta/transport.json .vault-meta/transport.*.tmp \
		.vault-meta/mode.json .vault-meta/mode.*.tmp .vault-meta/hook.log
	@echo "Runtime locks, caches, and generated state removed."
