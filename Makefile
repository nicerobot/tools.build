# tools.build/Makefile — repo entry point: build the per-workflow CI images, and
# provision the pinned Go tool set onto your machine (`install` / `doctor`).
#
# Each image is the single source of truth for ONE workflow, defined by
# docker/<type>/{Dockerfile,check}. GitHub Actions and bin/workflow both build
# and run it, so CI and local are byte-identical. Build one with `make <type>`,
# all with `make build`. bin/workflow already builds (or pulls) on demand, so
# this Makefile is for pre-building / cache warming and CI bootstrap.
#
# Paths are anchored to this Makefile's directory so it builds the same from any
# working directory.
here := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

.DELETE_ON_ERROR:
.DEFAULT_GOAL := help

.PHONY: help
help: ## This help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m[ target... ]\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

# One explicit image per workflow type, plus an aggregate. New gate? Add its name
# here and create docker/<type>/{Dockerfile,check}.
IMAGES := go docs shell actions dockerfiles python typescript terraform hugo

.PHONY: install
install: ## Install the pinned Go tool set into ${GOBIN} (bootstraps GOBIN to ~/go/bin if unset)
	$(here)scripts/go-install-tools.sh

.PHONY: doctor
doctor: ## Warn if a Homebrew copy shadows a pinned ${GOBIN} Go tool
	$(here)scripts/go-doctor.sh

.PHONY: deps
deps: ## Update tools.txt — bump every pinned Go tool to its latest release
	$(here)scripts/go-tooling-upgrade.sh

.PHONY: build
build: $(IMAGES) ## Build every workflow image

# Static pattern rule: one real target per image (NOT a shell loop), so `make -j`
# builds them in parallel. The tag matches what bin/workflow runs; the build
# context is the type's own directory so its Dockerfile COPYs `check` + configs.
.PHONY: $(IMAGES)
$(IMAGES): %:
	docker build --file $(here)ci/$@/Dockerfile --tag tools.build/ci-$@:local $(here)ci/$@
