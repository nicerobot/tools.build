# syntax=docker/dockerfile:1
#
# Go quality toolchain image.
#
# Stage 1 installs every tool pinned in tools.txt into static binaries with the
# SAME install-tools.sh a developer runs locally, then verify-tools.sh asserts the
# baked versions match the manifest — so the image and ~/go/bin are byte-identical.
# Stage 2 is the full official Go image (consumers still need `go` itself to
# build/test/vet) with those binaries on $PATH plus the includable tools.mk and
# default configs under /opt/go-tooling.

# Latest official Go image. The bundled tools require Go >= 1.25.
# Override at build time: docker build --build-arg GO_VERSION=1.26 ...
ARG GO_VERSION=1.26

FROM golang:${GO_VERSION} AS tools

ENV GOBIN=/tools/bin \
    CGO_ENABLED=0
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

# Precompiled tool binaries — /go/bin is already on PATH in the golang image.
COPY --from=tools /tools/bin/ /go/bin/

# Pin GOBIN to where the tools are baked. The shared build/go/Makefile resolves
# every tool from $(go env GOBIN) ONLY (no PATH/GOPATH fallback) and hard-fails if
# a tool is absent; setting GOBIN here makes that resolution succeed in CI against
# these baked binaries, exactly as a developer's populated $GOBIN does locally.
ENV GOBIN=/go/bin

# Includable makefile, default linter configs, and the action entrypoint.
ENV GO_TOOLING_DIR=/opt/go-tooling
COPY tools.mk .golangci.yml entrypoint.sh ${GO_TOOLING_DIR}/
RUN chmod +x ${GO_TOOLING_DIR}/entrypoint.sh

# Consuming CI checks out the repo here (Docker GitHub Actions override this
# with /github/workspace automatically).
WORKDIR /src
