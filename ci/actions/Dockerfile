# actions — actionlint gate for GitHub Actions workflow files.
#
# actionlint statically checks .github/workflows/*.yml for syntax errors, bad
# expressions, unknown contexts, and shellcheck issues in `run:` blocks, so a
# broken workflow is caught before it is merged (and fails silently in CI). The
# check script is POSIX sh, so the base needs nothing added (and stays non-root).
FROM rhysd/actionlint:1.7.7

# GATE=1 marks "inside the gate image" so a consumer Makefile's `ci` target can
# run the real steps here and re-exec into this image everywhere else.
ENV GATE=1

COPY --chmod=0755 check /usr/local/bin/check

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/check"]
