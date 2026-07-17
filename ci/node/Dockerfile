# node — Node.js quality gate.
#
# Runs the consumer's `make ci` target with the pinned Node toolchain, after an
# `npm ci` against the consumer's committed package-lock.json — so the gate and
# a local containerized `make ci` are identical. The image carries only Node +
# npm + make; every project dependency comes from the consumer's lock.
FROM node:22-bookworm-slim

# GATE=1 marks "inside the gate image" so a consumer Makefile's `ci` target can
# run the real steps here and re-exec into this image everywhere else.
ENV GATE=1

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends make; \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 check /usr/local/bin/check

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/check"]
