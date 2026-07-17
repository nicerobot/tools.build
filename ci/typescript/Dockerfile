# typescript — Biome lint + format gate for JavaScript/TypeScript.
#
# Biome is a single fast binary that both lints and format-checks JS/TS/JSX/TSX,
# replacing an ESLint + Prettier pair with one tool and no plugin sprawl.
# `biome ci` is its non-rewriting CI mode (lint + format check together).
FROM node:22-bookworm-slim

# GATE=1 marks "inside the gate image" so a consumer Makefile's `ci` target can
# run the real steps here and re-exec into this image everywhere else.
ENV GATE=1

RUN npm install -g @biomejs/biome@1.9.4

COPY --chmod=0755 check /usr/local/bin/check

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/check"]
