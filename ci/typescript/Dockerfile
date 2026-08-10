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

# The ruleset is BAKED, not discovered. ci/docs already works this way — it
# carries /etc/gomatic.markdownlint-cli2.jsonc and /etc/gomatic.prettierrc.json
# — while this gate carried none, so every repository was judged against
# biome's undeclared built-in defaults and not one of them had a biome.json.
# An unowned default is not a standard: nobody chose it, nobody can change it in
# one place, and a biome release moves it silently.
COPY biome.json /etc/gomatic.biome.json

COPY --chmod=0755 check /usr/local/bin/check

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/check"]
