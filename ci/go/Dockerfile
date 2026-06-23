# go — the Go quality gate, dockerized for local/CI parity.
#
# Runs the shared Makefile `ci` target (lint, staticcheck, vulncheck, 100% cover,
# race tests, cross-compile) against the repo mounted at /work. A repo with no
# first-party packages (gomatic/build itself) instead proves the pinned toolchain
# builds from vendor — the check script decides which case applies. Vendored deps
# mean no network is needed. The base floats to the latest 1.26.x patch on every
# rebuild, so a stdlib CVE fix is picked up with zero source changes.
FROM golang:1.26

COPY --chmod=0755 check /usr/local/bin/check

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/check"]
