# python — uv-based quality gate.
#
# Runs the consumer's shared `make ci` target (the distributed build/python
# Makefile): ruff format + lint, ty type-check, pytest — all via `uv run`, which
# resolves the tool versions the consumer pinned in its pyproject and syncs the
# project environment. The image carries only uv + make; everything else uv
# fetches per the consumer's lock.
FROM python:3.13-slim

# make drives the shared targets; uv owns the Python toolchain + venv.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends make; \
    rm -rf /var/lib/apt/lists/*; \
    pip install --no-cache-dir uv==0.11.23

COPY --chmod=0755 check /usr/local/bin/check

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/check"]
