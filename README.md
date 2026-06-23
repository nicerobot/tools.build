# build-tools

Public, cross-org home for **code-level quality & CI**. (Repository administration and deployment live in [`admin-tools`](https://github.com/nicerobot/admin-tools); image/asset generation in [`img-tools`](https://github.com/nicerobot/img-tools).)

Spec: [`nicerobot/projects` → `specs/build-tools-consolidation/`](https://github.com/nicerobot/projects/tree/main/specs/build-tools-consolidation).

## Contents

- **[`go-tooling/`](go-tooling/)** — prebuilt Go toolchain image (`ghcr.io/nicerobot/build-tools/go-tooling`) + includable `tools.mk`. Pulled, not rebuilt. Used as `uses: nicerobot/build-tools/go-tooling@vN`.
- **[`go-make/`](go-make/)** — the canonical in-tree Go toolchain `Makefile` + `golangci.yaml`, distributed into consumer repos by the push-tooling in [`repository-tools`](https://github.com/nicerobot/repository-tools). Self-contained: it never points outward.
- **`ci/<type>/`** — dockerized quality gates (`go docs shell actions dockerfiles python typescript terraform hugo`), each usable via `bin/workflow <type>` and as `uses: nicerobot/build-tools/ci/<type>@vN`. *(in progress — C3)*
- **`runtime/`** — shared distroless runtime base image. *(in progress — C2)*
- **[`scripts/check-alignment.sh`](scripts/check-alignment.sh)** — asserts the single-source contract: the `go-make` tool list matches the `go-tooling` `go.mod` `tool` block, and the two golangci configs are identical.

## The single tool set

The Go tool set and its versions live **once** in [`go-tooling/go.mod`](go-tooling/go.mod)'s `tool (...)` block (22 tools). `go-make`'s `Makefile` mirrors it; `scripts/check-alignment.sh` fails CI on any drift — co-location makes alignment a local check, not cross-repo verification.

Quality bar (enforced by the shared golangci config): cognitive complexity ≤ 7, cyclomatic ≤ 12, plus the full linter/security/vulnerability suite.
