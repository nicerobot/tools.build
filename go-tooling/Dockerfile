# syntax=docker/dockerfile:1
#
# Go quality toolchain image.
#
# Stage 1 installs every tool pinned in tools.txt into static binaries with the
# SAME install-tools.sh a developer runs locally, then verify-tools.sh asserts the
# baked versions match the manifest — so the image and ~/go/bin are byte-identical.
# Stage 2 is the full official Go image (consumers still need `go` itself to
# build/test/vet) with those binaries on ${PATH} plus the includable tools.mk and
# default configs under /opt/go-tooling.

# Latest official Go image. The bundled tools require Go >= 1.25.
# Override at build time: docker build --build-arg GO_VERSION=1.26 ...
ARG GO_VERSION=1.26

FROM golang:${GO_VERSION} AS tools

# Resolve the first-party gomatic tools (stickler, yze) straight from their public
# Git repos, bypassing the module proxy + checksum DB. They are version-pinned in
# tools.txt and only just went public, so sum.golang.org has not indexed them yet
# (and the proxy cached their prior private 404); a direct anonymous clone is
# deterministic where the proxy/sumdb path is not.
#
# CGO is REQUIRED: yze's SQL analyzer (yze-sql-keywordcase → go-sql) links
# pganalyze/pg_query_go, a cgo binding to libpg_query, so `go install yze` fails
# under CGO_ENABLED=0 (undefined pg_query.Parse/Scan/…). The golang base image
# ships gcc, and the final stage is the same base, so the cgo-linked binaries run
# there; the other (pure-Go) tools are unaffected by enabling cgo.
ENV GOBIN=/tools/bin \
    CGO_ENABLED=1 \
    GOPRIVATE=github.com/gomatic
WORKDIR /src

# Install the pinned tool set from the manifest, then assert it matches — the
# identical scripts and manifest used locally, so CI and ~/go/bin never diverge.
COPY tools.txt tools-lib.sh install-tools.sh verify-tools.sh ./
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    chmod +x ./install-tools.sh ./verify-tools.sh \
    && ./install-tools.sh \
    && ./verify-tools.sh

# ---------------------------------------------------------------------------
FROM golang:${GO_VERSION}

LABEL org.opencontainers.image.source="https://github.com/nicerobot/tools.build"
LABEL org.opencontainers.image.description="Go quality toolchain: formatters, linters, static & complexity analysis, security and vulnerability scanners precompiled with an includable Makefile."

# make (to drive tools.mk) + a C toolchain (race detector / cgo) + certs.
RUN apt-get update \
    && apt-get install -y --no-install-recommends make gcc ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Every consuming CI action mounts the repo from the runner (a different uid than
# the container's), so git flags the working tree as dubious ownership and Go's
# buildvcs stamping (go build / staticcheck compiling a test binary) fails with
# `error obtaining VCS status: exit status 128`. This surfaces only for repos whose
# build stamps VCS, so it looks repo-specific while being a fleet-wide condition.
# Mark all mounted repos safe SYSTEM-wide (writes /etc/gitconfig) so it holds for
# every user AND every entrypoint — an action that overrides ENTRYPOINT (e.g.
# ci/go's `check`) bypasses entrypoint.sh's per-workspace safe.directory.
RUN git config --system --add safe.directory '*'

# Precompiled tool binaries — /go/bin is already on PATH in the golang image.
COPY --from=tools /tools/bin/ /go/bin/

# Pin GOBIN to where the tools are baked. The shared build/go/Makefile resolves
# every tool from $(go env GOBIN) ONLY (no PATH/GOPATH fallback) and hard-fails if
# a tool is absent; setting GOBIN here makes that resolution succeed in CI against
# these baked binaries, exactly as a developer's populated ${GOBIN} does locally.
ENV GOBIN=/go/bin

# Includable makefile, default linter configs, and the action entrypoint.
ENV GO_TOOLING_DIR=/opt/go-tooling
COPY tools.mk .golangci.yml entrypoint.sh ${GO_TOOLING_DIR}/
RUN chmod +x ${GO_TOOLING_DIR}/entrypoint.sh

# Central stickler config (the GLOBAL layer `make lint` inherits — yze soft, etc.).
# stickler resolves its global config from ${XDG_CONFIG_HOME}/stickler/config.yaml,
# so baking the file and pointing XDG_CONFIG_HOME here makes the default
# deterministic in CI regardless of HOME. A repo's .stickler.yaml layers over it.
COPY stickler.config.yaml ${GO_TOOLING_DIR}/stickler/config.yaml
ENV XDG_CONFIG_HOME=${GO_TOOLING_DIR}

# Consuming CI checks out the repo here (Docker GitHub Actions override this
# with /github/workspace automatically).
WORKDIR /src
