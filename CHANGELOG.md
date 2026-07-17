# Changelog

## [2.5.0](https://github.com/nicerobot/tools.build/compare/v2.4.0...v2.5.0) (2026-07-17)


### Features

* **ci:** serve gates from the published pinned images; exempt CHANGELOG.md from the docs gate ([#5](https://github.com/nicerobot/tools.build/issues/5)) ([e90e572](https://github.com/nicerobot/tools.build/commit/e90e57229728777afc03e3fd1c5769df7b144400))

## [2.4.0](https://github.com/nicerobot/tools.build/compare/v2.3.0...v2.4.0) (2026-07-17)

### Features

- **ci:** node, java, and cpp gate images; GATE=1 in every gate; multi-arch developer gates ([#4](https://github.com/nicerobot/tools.build/issues/4)) ([03ed7bb](https://github.com/nicerobot/tools.build/commit/03ed7bbd4f518c1b8d5c3289bd3958cff3e69daf))
- **go:** scope `go vet` via VET_PKGS to exclude committed generated trees ([de66508](https://github.com/nicerobot/tools.build/commit/de66508c99e94b6fe471c5b504073789f2297aba))
- **go:** scope staticcheck via STATICCHECK_PKGS to exclude committed generated trees (mirrors VET_PKGS) ([4f9bd6f](https://github.com/nicerobot/tools.build/commit/4f9bd6f4754e8399b148997497efadc3baeb67dc))

### Bug Fixes

- **go-tooling:** pin yq and make the standards ratchet fail closed ([f50fe7b](https://github.com/nicerobot/tools.build/commit/f50fe7b8c0db98384a8c77fff35c5cfb9742828d))
- **typescript:** exclude committed build artifacts and generated code from the biome gate ([619ed64](https://github.com/nicerobot/tools.build/commit/619ed64c63489767cda076a96db90720a82a01c2))
