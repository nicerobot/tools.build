# typescript — Biome lint + format gate for JavaScript/TypeScript.
#
# Biome is a single fast binary that both lints and format-checks JS/TS/JSX/TSX,
# replacing an ESLint + Prettier pair with one tool and no plugin sprawl.
# `biome ci` is its non-rewriting CI mode (lint + format check together).
#
# The base is node-tooling, which bakes the pinned Node CLIs from its tools.txt
# — biome among them. The version lived in a bare `npm install -g` here until
# that manifest existed; it is one line in one file now, the way every Go tool
# version is.
FROM ghcr.io/nicerobot/tools.build/node-tooling:v2

# GATE=1 marks "inside the gate image" so a consumer Makefile's `ci` target can
# run the real steps here and re-exec into this image everywhere else.
ENV GATE=1

COPY --chmod=0755 check /usr/local/bin/check

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/check"]
