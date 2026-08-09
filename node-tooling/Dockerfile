# node-tooling — Node CLI toolchain image.
#
# Bakes the pinned tool set from tools.txt into ${NODE_TOOLS_BIN}, then asserts
# the installed versions match the manifest — the same shape as go-tooling, and
# for the same reason: a consumer repository should declare no build tooling of
# its own, so its lockfile carries only what the application actually ships.
#
# That is not tidiness. Every www.* repo declared wrangler, so wrangler ->
# miniflare -> undici and vite -> postcss -> nanoid were reported as security
# advisories against the SITE, and Dependabot failed on repositories that ship
# none of it — including one with zero runtime dependencies. Those advisories
# belong to the tool, and are now dealt with here, once.
FROM node:22-bookworm-slim

# Where the pinned tools live. A directory of their own, not the system default,
# so a consumer can resolve a tool from an exact path rather than from PATH —
# where a project's own node_modules would answer first and the pin would mean
# nothing.
ENV NODE_TOOLS_PREFIX=/opt/node-tools \
    NODE_TOOLS_BIN=/opt/node-tools/bin
ENV PATH=${NODE_TOOLS_BIN}:${PATH}

WORKDIR /src

# The manifest and both scripts travel together: verify-tools.sh reads the same
# tools.txt install-tools.sh consumed, so the assertion is against the manifest
# that was actually installed rather than a copy that might not have shipped.
COPY tools.txt install-tools.sh verify-tools.sh ./
RUN chmod +x ./install-tools.sh ./verify-tools.sh \
    && ./install-tools.sh \
    && ./verify-tools.sh

WORKDIR /work
