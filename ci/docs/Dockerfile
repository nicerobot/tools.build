# docs — Markdown + Mermaid standards gate for specs/ .claude/ docs/ and **/*.md.
#
# Enforces three things on every doc:
#   1. markdownlint-cli2 with the gomatic ruleset — MD013 (line-length) is OFF,
#      because prose MUST be one physical line per paragraph (no hard wrap), so a
#      long line is correct, not a violation.
#   2. prettier --check with proseWrap:never — the active enforcement of the
#      no-hard-wrap rule: it reports any doc that is not already formatted (e.g.
#      hard-wrapped prose), so a dirtying doc fails the gate. Non-mutating.
#   3. every ```mermaid block actually renders (mmdc -> SVG via headless
#      chromium); a diagram that fails to parse fails the gate, so broken
#      diagrams never merge.
FROM node:22-bookworm-slim

ENV PUPPETEER_SKIP_DOWNLOAD=1 \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# chromium powers headless Mermaid rendering; gawk/findutils back the check
# script's block extraction and file discovery.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      chromium fonts-liberation ca-certificates gawk findutils; \
    rm -rf /var/lib/apt/lists/*; \
    npm install -g markdownlint-cli2@0.14.0 prettier@3.8.4 @mermaid-js/mermaid-cli@11.4.2

# markdownlint-cli2 only accepts a --config whose name ends with a recognized
# suffix (e.g. *.markdownlint-cli2.jsonc), so it is baked under that name.
COPY markdownlint.jsonc /etc/gomatic.markdownlint-cli2.jsonc
COPY prettier.json /etc/gomatic.prettierrc.json
COPY puppeteer.json /etc/puppeteer.json
COPY --chmod=0755 check /usr/local/bin/check

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/check"]
