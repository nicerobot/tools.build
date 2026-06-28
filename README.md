# tools.build

[![CI](https://github.com/nicerobot/tools.build/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/nicerobot/tools.build/actions/workflows/ci.yml)

Public, cross-org home for **code-level quality & CI**. (Repository administration and deployment live in [`tools.admin`](https://github.com/nicerobot/tools.admin); image/asset generation in [`tools.img`](https://github.com/nicerobot/tools.img).)

Spec: [`nicerobot/projects` → `specs/tools.build-consolidation/`](https://github.com/nicerobot/projects/tree/main/specs/tools.build-consolidation).

## Contents

- **[`go-tooling/`](go-tooling/)** — prebuilt Go toolchain image (`ghcr.io/nicerobot/tools.build/go-tooling`) + includable `tools.mk`. Pulled, not rebuilt. Used as `uses: nicerobot/tools.build/go-tooling@vN`.
- **[`build/`](build/)** — the per-type build bundles distributed into consumer repos by `distribute-build` in [`tools.repository`](https://github.com/nicerobot/tools.repository): one directory per primary language (`build/go/` — the canonical `Makefile` + `.golangci.yaml`; `build/python/` — uv-based) plus a flat [`build/workflows/`](build/workflows/) of named CI workflows (`go.yml`, `docs.yml`, …) keyed off each repo's detected features. Self-contained: bundles never point outward.
- **`ci/<type>/`** — dockerized quality gates (`go docs shell actions dockerfiles python typescript terraform hugo`), each usable via `bin/workflow <type>` and as `uses: nicerobot/tools.build/ci/<type>@vN`. _(in progress — C3)_
- **[`tag/`](tag/)** — language-agnostic auto-versioning composite action (`uses: nicerobot/tools.build/tag@vN`). On merge to `main` it derives the next `vX.Y.Z` from Conventional Commits — `feat:`→minor, everything else→patch, **capped at minor (never major)** — and pushes the tag. Distributed via [`build/workflows/release.yml`](build/workflows/release.yml); opt out per repo with a `.no-autorelease` file.
- **`runtime/`** — shared distroless runtime base image. _(in progress — C2)_
- **[`scripts/check-alignment.sh`](scripts/check-alignment.sh)** — asserts the single-source contract: every tool the `build/go` Makefile invokes is provided by the `go-tooling` [`tools.txt`](go-tooling/tools.txt) manifest, and the two golangci configs are identical.

## The single tool set

The Go tool set and its versions live **once** in [`go-tooling/tools.txt`](go-tooling/tools.txt) (20 tools, one pinned `importpath@version` each), installed via `go install path@version` into `$GOBIN` — identically by a developer's `make tools` and by the `go-tooling` image, so `~/go/bin` and CI hold the same versions. `scripts/check-alignment.sh` fails CI if the `build/go` Makefile invokes a tool the manifest does not provide.

Quality bar (enforced by the shared golangci config): cognitive complexity ≤ 7, cyclomatic ≤ 12, plus the full linter/security/vulnerability suite.
