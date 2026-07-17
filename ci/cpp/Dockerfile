# cpp — C/C++ quality gate.
#
# Runs the consumer's `make ci` target with a pinned CMake + GCC toolchain.
# git + ca-certificates are present because consumer builds may fetch pinned
# sources via CMake FetchContent (e.g. the ANTLR C++ runtime). The gate and a
# local containerized `make ci` are identical.
FROM debian:bookworm-slim

# GATE=1 marks "inside the gate image" so a consumer Makefile's `ci` target can
# run the real steps here and re-exec into this image everywhere else.
ENV GATE=1

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends make cmake g++ git ca-certificates; \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 check /usr/local/bin/check

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/check"]
