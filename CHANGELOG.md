# Changelog

## [3.0.0](https://github.com/nicerobot/tools.build/compare/v2.3.0...v3.0.0) (2026-07-06)


### ⚠ BREAKING CHANGES

* yze is hard everywhere — the rollout soft phase is over

### Features

* yze is hard everywhere — the rollout soft phase is over ([92b87e1](https://github.com/nicerobot/tools.build/commit/92b87e129cf68a532d2667470aa9c817629f10c9))


### Bug Fixes

* **deps:** bump goreleaser v2.16.0 → v2.17.0 — clears GO-2026-5052 (go-pkcs12) and GO-2026-5026 (x/net) ([fd8f53f](https://github.com/nicerobot/tools.build/commit/fd8f53fe796aad9aeb15f0e735fb6b1bfb47e306))
* enable cgo in the tools stage so yze (libpg_query) builds ([ede002c](https://github.com/nicerobot/tools.build/commit/ede002c8dd39d98faefeed2f29ba9f7b5ecf5dc5))
* mark mounted repos git-safe system-wide so buildvcs stamping works in CI ([7f76721](https://github.com/nicerobot/tools.build/commit/7f76721c2b24c408ae40b638042a8ebcf74dcc48))
* vulncheck installs public tools via anonymous clone (GOPRIVATE); register the classification capability ([1467c69](https://github.com/nicerobot/tools.build/commit/1467c694cd347b26173f6d135434136c4dea0f7a))
