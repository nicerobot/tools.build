# Changelog

## [2.11.0](https://github.com/nicerobot/tools.build/compare/v2.10.0...v2.11.0) (2026-08-02)


### Features

* stickler v0.10.0 + yze v0.31.0 — binaries gate, fuzz pair, enumdiscrim, errtext ([3efa976](https://github.com/nicerobot/tools.build/commit/3efa9765b746de20bd9d641d1853a207095bfcd0))

## [2.10.0](https://github.com/nicerobot/tools.build/compare/v2.9.0...v2.10.0) (2026-08-02)


### Features

* yze v0.30.0 + stickler v0.9.0 — the CLI family at every depth ([6907a98](https://github.com/nicerobot/tools.build/commit/6907a986bd8af06211b71d596326ca3512858cee))

## [2.9.0](https://github.com/nicerobot/tools.build/compare/v2.8.0...v2.9.0) (2026-08-01)


### Bug Fixes

* **go-tooling:** make the toolchain CVE gate honest and green ([a22b458](https://github.com/nicerobot/tools.build/commit/a22b458de2a5bc55b16f65e25951c16228b3c00d))
* **vulncheck:** fail when govulncheck itself fails to scan ([4e0ec54](https://github.com/nicerobot/tools.build/commit/4e0ec541f8bfeae6e54d23a7a727a3db28d4f4f8))

## [2.8.0](https://github.com/nicerobot/tools.build/compare/v2.7.0...v2.8.0) (2026-08-01)


### Bug Fixes

* **release:** force the tag refspec so a manually cut tag can move its major alias ([89e9aaf](https://github.com/nicerobot/tools.build/commit/89e9aaf2dc2ad1d32d1fa52b9952c5b2bda61cde))
* **release:** publish base images before the images that build FROM them ([4f6e7fa](https://github.com/nicerobot/tools.build/commit/4f6e7fac56410754b669c5dac1172adf089ea78b))

## [2.7.0](https://github.com/nicerobot/tools.build/compare/v2.6.1...v2.7.0) (2026-08-01)


### Features

* **tooling:** pin stickler v0.8.6 — the analyzers: block reaches yze ([28eaec9](https://github.com/nicerobot/tools.build/commit/28eaec9e322fcb14a0b298a885f438072b65014c))
* **tooling:** pin yze v0.29.1 — errtested and invariant see external tests ([4af38b0](https://github.com/nicerobot/tools.build/commit/4af38b001e571aed18429940259777652a62e8fc))
* **tooling:** pin yze v0.29.0, carrying cliopinion ([2584321](https://github.com/nicerobot/tools.build/commit/25843211673fa665ad94dde7cda09a32e8aa6bd2))
* **go-gate:** land exhaustive, measured and soft ([6d67bf1](https://github.com/nicerobot/tools.build/commit/6d67bf19bca8a38277d5cf1c064f1b9a2230a425))
* **tooling:** adopt the suite that can see test files ([bad82be](https://github.com/nicerobot/tools.build/commit/bad82be0e25cc69d05ab4436c24361ffcb5de9e3))
* **go-gate:** add deadcode + tidy + exhaustive gates, shuffled/repeated tests ([5f9eb47](https://github.com/nicerobot/tools.build/commit/5f9eb47230b1eed2d576efc51343f5675c9f7f0b))
* **gate:** cross-compile libraries too, so one cannot pass while consumers cannot build it ([db8ba08](https://github.com/nicerobot/tools.build/commit/db8ba08eca68e74ef3532400866aa634f94fc606))
* **bundle:** publish the tag's artifacts instead of minting a version nothing builds ([43872ca](https://github.com/nicerobot/tools.build/commit/43872ca6fd5730509c895d4c57de528143e456b6))
* **bundle:** hugo-module bundle carrying a github-actions Dependabot config ([acb8557](https://github.com/nicerobot/tools.build/commit/acb85571d0285b8e7fe10cdb5a945ea89bfc2ef8))
* **bundle:** managed Dependabot version-update config per ecosystem ([43f5828](https://github.com/nicerobot/tools.build/commit/43f5828674c092e3a802175ca9992e574685d91f))

### Bug Fixes

* **go-gate:** scope deadcode to this repo's own reachable code ([adfd48c](https://github.com/nicerobot/tools.build/commit/adfd48c6dfbbb3592de7b65e425a51b60d891a3d))
* **release:** an empty goreleaser config means nothing to publish ([079a6f9](https://github.com/nicerobot/tools.build/commit/079a6f90e345c6f52d3fe4f4f5dfaf06103526e2))
* **ci/go:** fail closed when go list cannot enumerate packages ([8d14100](https://github.com/nicerobot/tools.build/commit/8d14100fa21fff1481e3f13478983d5af21baaec))
* **gate:** exclude coverage/ from the TypeScript check ([7fecaf5](https://github.com/nicerobot/tools.build/commit/7fecaf541aef996af361296657e7bb38440cfdeb))
* **bundle:** probe for the goreleaser config in a step, not a job-level if ([1fd0734](https://github.com/nicerobot/tools.build/commit/1fd07347aafd4da07cfa8d517dbb9576c78b7efc))
* **bundle:** point dependabot at "/" and "/*" so subdirectory manifests are found ([f313e06](https://github.com/nicerobot/tools.build/commit/f313e0646df8267a17fbb0564aec6965e305ccf3))
* **standards:** register the internal-content analyzer capability ([2eb42a1](https://github.com/nicerobot/tools.build/commit/2eb42a1a0e2a020b1da91c6c1fce08ad3c6ef8cf))

## [2.6.1](https://github.com/nicerobot/tools.build/compare/v2.6.0...v2.6.1) (2026-07-19)


### Bug Fixes

* **ci:** typescript gate excludes the Hugo public/ output tree ([db73157](https://github.com/nicerobot/tools.build/commit/db73157a574923dd30eacf270d6c38d0110083ba))

## [2.6.0](https://github.com/nicerobot/tools.build/compare/v2.5.0...v2.6.0) (2026-07-17)


### Features

* **release:** move the floating vMAJOR git tag automatically; gates track :vMAJOR images ([#7](https://github.com/nicerobot/tools.build/issues/7)) ([c115b7b](https://github.com/nicerobot/tools.build/commit/c115b7bebe7927c60c135d9f5ea7133f1e327ad0))

## [2.5.0](https://github.com/nicerobot/tools.build/compare/v2.4.0...v2.5.0) (2026-07-17)

### Features

- **ci:** serve gates from the published pinned images; exempt CHANGELOG.md from the docs gate ([#5](https://github.com/nicerobot/tools.build/issues/5)) ([e90e572](https://github.com/nicerobot/tools.build/commit/e90e57229728777afc03e3fd1c5769df7b144400))

## [2.4.0](https://github.com/nicerobot/tools.build/compare/v2.3.0...v2.4.0) (2026-07-17)

### Features

- **ci:** node, java, and cpp gate images; GATE=1 in every gate; multi-arch developer gates ([#4](https://github.com/nicerobot/tools.build/issues/4)) ([03ed7bb](https://github.com/nicerobot/tools.build/commit/03ed7bbd4f518c1b8d5c3289bd3958cff3e69daf))
- **go:** scope `go vet` via VET_PKGS to exclude committed generated trees ([de66508](https://github.com/nicerobot/tools.build/commit/de66508c99e94b6fe471c5b504073789f2297aba))
- **go:** scope staticcheck via STATICCHECK_PKGS to exclude committed generated trees (mirrors VET_PKGS) ([4f9bd6f](https://github.com/nicerobot/tools.build/commit/4f9bd6f4754e8399b148997497efadc3baeb67dc))

### Bug Fixes

- **go-tooling:** pin yq and make the standards ratchet fail closed ([f50fe7b](https://github.com/nicerobot/tools.build/commit/f50fe7b8c0db98384a8c77fff35c5cfb9742828d))
- **typescript:** exclude committed build artifacts and generated code from the biome gate ([619ed64](https://github.com/nicerobot/tools.build/commit/619ed64c63489767cda076a96db90720a82a01c2))
