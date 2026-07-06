# Repository standards exemptions — design

## Problem

`distribute --org <owner>` injects the uniform build unit (Makefile, configs, CI workflows) into every buildable repo in an owner. Of 58 buildable `gomatic` repos, only the 21 `go-*` libraries are modernized (carry a managed Makefile under distribute-build); the other 37 either follow non-Go standards (22 `docs.*` Hugo sites, 2 `www.*`, 2 `infra.*`, 2 governance) or are unmodernized Go code with hand-authored Makefiles (`cirql`, `hyt`, `jsonfs`, `modern-go-application`, `qp`, `renderizer`, `ssh-tgzx`, `template.cli`, `ui.family`).

Running distribute org-wide injects a `go.yml` CI workflow (which runs `make ci`) into repos whose hand-authored Makefiles do not implement `ci`, turning CI red across them while leaving their Makefiles unmanaged (distribute skips hand-authored files). There is today no way for a repo to declare "I do not yet satisfy standard X — do not enforce or inject it until I do," and no mechanism to ensure such an opt-out is removed once the repo actually complies.

## Goal

A per-repo, per-capability **exemption marker** that both `distribute` and the shared gate honor, governed by an **anti-rot ratchet**: an exemption is a verifiable, self-expiring claim of non-compliance. Exemptions can only shrink — the tooling fails the moment a claimed gap is closed, forcing the line's removal.

## Model (decided)

- **Granularity**: per-capability (not coarse whole-bundle). A repo lists only the specific capabilities it does not yet satisfy.
- **Enforcement surfaces**: both — `distribute` (skip injecting an exempted _artifact_) and the shared gate (skip enforcing an exempted _check_) — plus an org-wide `verify`.
- **Ratchet (hard)**: for every capability with a runnable check:
  - not exempt + check passes → ok
  - not exempt + check fails → **fail** (normal gate failure)
  - exempt + check fails → ok (the exemption holds; warn)
  - exempt + check passes → **fail** (stale exemption — must be removed)
  - exemption names a capability absent from the registry → **fail** (typo guard)
  - exemption lacks a reason → **fail** (the ledger must explain itself)

## Capability registry (single source)

`nicerobot/tools.build/standards/capabilities.yaml` — the one canonical registry of every capability/convention, consumed by both the gate (tools.build) and distribute/verify (tools.repository). Three kinds, dotted namespace:

- `artifact:*` — managed files distribute injects: `artifact:makefile`, `artifact:golangci`, `artifact:workflow:go`, `artifact:workflow:actions`, `artifact:workflow:docs` (extend as the bundle grows).
- `gate:*` — mechanical checks the shared gate runs: `gate:lint`, `gate:staticcheck`, `gate:vulncheck`, `gate:coverage`, `gate:format`, `gate:vet`.
- `convention:*` — higher-level conventions verified by `gomatic/analyzers/*/v1` (see Deferred). **Reserved now** so the schema and ratchet are forward-compatible; each is _inert_ until its analyzer ships, at which point the ratchet begins applying to it.

Each registry entry records its `kind`, a one-line `description`, and (for `gate:`/`convention:`) the `raw` make target that runs just that check (the staleness probe).

## Marker schema

`.standards.yaml` at repo root — hand-authored, **not** managed by distribute-build (so it survives every distribution):

```yaml
# Capabilities this repo does NOT yet satisfy. The gate skips enforcing each and
# distribute skips injecting its artifact; the ratchet fails if any now passes.
exempt:
  gate:coverage: "legacy paths uncovered; backfill tracked in <issue>"
  artifact:workflow:go: "Makefile not yet modernized to the shared gate"
  convention:sentinel-errors: "uses fmt.Errorf throughout; migration pending"
```

Every value is a non-empty reason string.

## Gate integration (tools.build, distributed `build/go/Makefile`)

Backward compatible: **no `.standards.yaml` → byte-identical behavior to today.**

- A `standards-validate` step (prerequisite of `check`/`ci`) asserts every `exempt:` key exists in the registry and has a non-empty reason; unknown key or empty reason fails.
- Each gate step is split into an inner `X-raw` target (the real work) and an outer `X` that routes through the ratchet wrapper `$(call standards-run,gate:X,$(MAKE) X-raw)`:
  - capability not in `EXEMPT` → run `X-raw`, pass its exit through (today's behavior).
  - in `EXEMPT` + `X-raw` fails → print "exempt (known gap)" and succeed.
  - in `EXEMPT` + `X-raw` passes → print "stale exemption" and **fail**.
- `EXEMPT` is computed once via `yq` reading `.standards.yaml` (yq is already in the gate image). The wrapper is a make `define` in the distributed Makefile — no external script, so it works unchanged inside the CI image and in local `${GOBIN}` runs.

## distribute integration (tools.repository)

`ApplyBundle` already classifies targets and skips hand-authored files. Add: load the repo's `.standards.yaml`; for any planned target whose capability is exempted (`artifact:*`), **skip** writing it and record it as `exempt` in the result (distinct from `skipped`/hand-authored). Capability mapping: `Makefile→artifact:makefile`, `.golangci.yaml→artifact:golangci`, `.github/workflows/<w>.yml→artifact:workflow:<w>`. Registry membership of exempt keys is validated (unknown → error), reusing the shared registry loader.

## verify command (tools.repository)

`git repo standards verify [--org <owner>]` — read-only org sweep. For each repo with a `.standards.yaml`: validate it against the registry, then for each exempted `gate:`/`convention:` capability run its registry `raw` target and report any that now pass (stale). Aggregates an org-wide ledger: per repo, the held exemptions (with reasons) and the stale ones. Exit nonzero if any stale exemption exists anywhere — the org-wide arm of the ratchet. (Reuses the in-repo gate's `raw` targets rather than re-implementing each check.)

## Components & boundaries

| Unit | Home | Responsibility |
| --- | --- | --- |
| `standards/capabilities.yaml` | tools.build | canonical capability/convention registry (data) |
| `.standards.yaml` | each repo | per-repo exemption ledger (data) |
| `standards-run` wrapper + `standards-validate` | tools.build `build/go/Makefile` | gate ratchet + registry/reason validation |
| registry loader + exemption reader | tools.repository `internal/standards` | parse registry + marker; shared by distribute & verify |
| distribute exempt-skip | tools.repository `internal/buildbundle` | skip injecting exempted artifacts |
| `standards verify` | tools.repository `internal/app/commands/standards` | org-wide staleness sweep |

## Testing

- `internal/standards` (Go): registry parse, marker parse, capability validation, exemption classification — table-driven, 100% coverage, injected FS.
- distribute exempt-skip: extend `buildbundle` tests — exempted artifact is skipped + recorded; unknown exempt key errors.
- verify: fake repo set with held + stale exemptions; assert exit code and report.
- gate ratchet: verified against the 21 `go-*` repos — **no `.standards.yaml` → `make check` stays green and unchanged**; a temporary marker exempting a passing gate makes `make check` fail (stale); exempting a deliberately-failed gate passes.

## Deferred (separate spec, queued)

Extract the convention analyzers in `robertcnix/fmt.fmtctl internal/domain/code/languages/go/lint/` into `gomatic/analyzers/<name>/v1` modules, each exposing a `golang.org/x/tools/go/analysis.Analyzer` (testable via `analysistest` to 100%), aggregated by one pinned `gomatic-vet` multichecker `${GOBIN}` tool run as a gate step. This spec only **reserves** the `convention:*` namespace; the analyzers and their gate wiring are a separate brainstorm→spec→implement cycle.

## Non-goals

- Modernizing the 9 unmodernized Go repos (separate work; this only lets them opt out cleanly).
- A coarse "skip this whole repo" flag (manifest `excludedRepos` already exists for total exclusion).
- Changing how non-Go repos (`docs.*`/`www.*`/`infra.*`) are handled (their primaries already select non-Go bundles).
