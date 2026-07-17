# go — the Go quality gate, dockerized for local/CI parity.
#
# Runs the shared build/go/Makefile `ci` target (lint, staticcheck, vulncheck,
# 100% cover, race tests, cross-compile) against the repo mounted at /work. The
# base is the go-tooling image, which bundles `go` AND the pinned quality tools
# baked into ${GOBIN} (/go/bin) — so a consumer repo needs no tool stanza and no
# vendored tooling; the Makefile resolves every tool from ${GOBIN}. A repo with no
# first-party packages instead prints the pinned tool versions — the check script
# decides which case applies. The go-tooling base itself floats to the latest
# 1.26.x patch on every rebuild, so a stdlib CVE fix is picked up with zero
# source changes.
FROM ghcr.io/nicerobot/tools.build/go-tooling:v2

# GATE=1 marks "inside the gate image" so a consumer Makefile's `ci` target can
# run the real steps here and re-exec into this image everywhere else.
ENV GATE=1

COPY --chmod=0755 check /usr/local/bin/check

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/check"]
