# go-tooling/Makefile — the gate and maintenance targets for the tool set itself.
#
# go-tooling is TOOLS-ONLY: tools.txt is the single pinned source of every quality
# tool, installed via `go install path@version` (no shared go.mod). There are no
# first-party Go packages, so the package-scoped gates (fmt/lint/vet/staticcheck/
# test/cover/tidy) do not apply; the meaningful gate is that the manifest installs,
# the installed binaries match it, and they are vulnerability-clean:
#
#   • tools     — install the manifest into $GOBIN (the developer/CI install path)
#   • verify    — assert $GOBIN matches tools.txt (the local==CI proof)
#   • vulncheck — govulncheck -mode=binary over every installed tool
#
# All real logic lives in checked-in scripts under ../scripts and the install/
# verify scripts beside this file; recipes are plain commands. Image build /
# upgrade / demo are maintenance targets; `ci` does NOT build the image (the
# release workflow and `make build` do that).

.DELETE_ON_ERROR:
.DEFAULT_GOAL := help

# Absolute paths, anchored to this Makefile's directory so it runs the same from
# any working directory.
here    := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
scripts := $(realpath $(here)..)/scripts

IMAGE      ?= ghcr.io/nicerobot/tools.build/go-tooling
TAG        ?= dev
GO_VERSION ?= 1.26

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m[ target... ]\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

##@ Quality gate

.PHONY: check
check: tools verify vulncheck ## Full gate: install the manifest, prove versions, scan

.PHONY: ci
ci: check ## CI gate (image build is separate — see `build` / the release workflow)

.PHONY: tools
tools: ## Install the pinned tool set (tools.txt) into $GOBIN
	$(here)install-tools.sh

.PHONY: verify
verify: ## Assert installed $GOBIN tools match tools.txt (the local==CI proof)
	$(here)verify-tools.sh

.PHONY: vulncheck
vulncheck: ## govulncheck -mode=binary over every installed tool
	$(scripts)/go-tools-vulncheck.sh

.PHONY: doctor
doctor: ## Verify versions and warn on Homebrew-shadowed tools
	$(scripts)/go-doctor.sh

##@ Image & tool maintenance

.PHONY: build
build: ## Build the go-tooling image (override IMAGE/TAG)
	docker build --build-arg GO_VERSION=$(GO_VERSION) --file $(here)Dockerfile --tag $(IMAGE):$(TAG) $(here)

.PHONY: upgrade
upgrade: ## Bump every tool in tools.txt to @latest and reinstall
	$(scripts)/go-tooling-upgrade.sh

.PHONY: tool-versions
tool-versions: build ## Print bundled tool versions from the built image
	docker run --rm $(IMAGE):$(TAG) make -f /opt/go-tooling/tools.mk tool-versions

.PHONY: demo
demo: build ## Run the image's gate against a throwaway sample module
	$(scripts)/go-tooling-demo.sh $(IMAGE):$(TAG)
