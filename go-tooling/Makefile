# go-tooling/Makefile — the canonical Go gate for the tool module itself.
#
# go-tooling is a TOOLS-ONLY module: its go.mod `tool (...)` stanza is the single
# source of every pinned quality tool, and it ships no first-party Go packages.
# It still answers to the SAME target interface as any other Go module here
# (help/fmt/lint/vet/staticcheck/vulncheck/test/cover/tidy/check/ci/clean) so it
# is uniform and not exempt from the gates — adapted where its nature requires:
#
#   • It dogfoods its OWN stanza: tools run via `go tool <name>` (not from $GOBIN
#     like consumer repos), so the gate needs nothing installed and proves the
#     exact pinned versions it ships.
#   • vulncheck scans the STANZA (a package-less module can't be module-scanned).
#   • Package-scoped gates (vet/lint/staticcheck/test/cover) skip cleanly when
#     there are no first-party packages, instead of failing on "matched no
#     packages" — see scripts/go-if-packages.sh.
#
# All real logic lives in checked-in scripts under ../scripts; recipes are plain
# commands. Image build / upgrade / demo are the module's custom maintenance
# targets; `ci` does NOT build the image (the release workflow and `make build`
# do that).

.DELETE_ON_ERROR:
.DEFAULT_GOAL := help

# Absolute paths, anchored to this Makefile's directory so it runs the same from
# any working directory.
here    := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
scripts := $(realpath $(here)..)/scripts

GO ?= go

# Tools come from THIS module's own `tool (...)` stanza — go-tooling is the one
# module that legitimately uses `go tool <name>`.
GOFUMPT       := $(GO) tool gofumpt
GOLANGCI_LINT := $(GO) tool golangci-lint
STATICCHECK   := $(GO) tool staticcheck
GOTESTSUM     := $(GO) tool gotestsum

GOLANGCI_CONFIG := $(here).golangci.yml
GO_TEST_FORMAT  ?= standard-verbose

IMAGE      ?= ghcr.io/nicerobot/tools.build/go-tooling
TAG        ?= dev
GO_VERSION ?= 1.26

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m[ target... ]\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

##@ Quality gate

.PHONY: check
check: fmt-check lint staticcheck vulncheck cover tidy-check ## Full developer gate

.PHONY: ci
ci: check ## CI gate (image build is separate — see `build` / the release workflow)

.PHONY: fmt
fmt: ## Format Go files (gofumpt)
	$(GOFUMPT) -l -w $(here)

.PHONY: fmt-check
fmt-check: ## Fail if any Go file is not gofumpt-clean
	$(scripts)/go-fmt-check.sh $(GOFUMPT)

.PHONY: vet
vet: ## go vet (skips when there are no first-party packages)
	$(scripts)/go-if-packages.sh $(GO) vet ./...

.PHONY: lint
lint: vet ## Verify the shipped golangci config + run golangci-lint
	$(GOLANGCI_LINT) config verify -c $(GOLANGCI_CONFIG)
	$(scripts)/go-if-packages.sh $(GOLANGCI_LINT) run

.PHONY: staticcheck
staticcheck: ## staticcheck (skips when there are no first-party packages)
	$(scripts)/go-if-packages.sh $(STATICCHECK) ./...

.PHONY: vulncheck
vulncheck: ## govulncheck scan of the tool stanza
	$(scripts)/go-stanza-vulncheck.sh

.PHONY: test
test: ## Run tests (skips when there are no first-party packages)
	$(scripts)/go-if-packages.sh $(GOTESTSUM) --format $(GO_TEST_FORMAT) -- ./...

.PHONY: cover
cover: ## Run tests with coverage (skips when there are no first-party packages)
	$(scripts)/go-if-packages.sh $(GOTESTSUM) --format $(GO_TEST_FORMAT) -- -coverprofile=coverage.out ./...

.PHONY: tidy
tidy: ## go mod tidy
	$(GO) -C $(here) mod tidy

.PHONY: tidy-check
tidy-check: ## Fail if go.mod/go.sum are not tidy
	$(scripts)/go-tidy-check.sh

.PHONY: clean
clean: ## Remove coverage artifacts
	rm -f $(here)coverage.out $(here)coverage.html

##@ Image & tool maintenance

.PHONY: build
build: ## Build the go-tooling image (override IMAGE/TAG)
	docker build --build-arg GO_VERSION=$(GO_VERSION) --file $(here)Dockerfile --tag $(IMAGE):$(TAG) $(here)

.PHONY: upgrade
upgrade: ## Bump every bundled tool to @latest and re-tidy
	$(scripts)/go-tooling-upgrade.sh

.PHONY: tool-versions
tool-versions: build ## Print bundled tool versions from the built image
	docker run --rm $(IMAGE):$(TAG) make -f /opt/go-tooling/tools.mk tool-versions

.PHONY: demo
demo: build ## Run the image's gate against a throwaway sample module
	$(scripts)/go-tooling-demo.sh $(IMAGE):$(TAG)
