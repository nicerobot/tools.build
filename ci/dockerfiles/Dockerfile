# dockerfiles — hadolint gate for every Dockerfile in the repo.
#
# hadolint enforces Dockerfile best practices (pinned bases, --no-install-
# recommends, cleaned apt lists, no `latest`, ...). The gomatic policy in
# hadolint.yaml turns OFF only OS-package version pinning (DL3008/DL3018), which
# rots fast against rolling distro repos — the base image is pinned instead. The
# check script is POSIX sh, so the base needs nothing added (and stays non-root,
# satisfying hadolint's own DL3002).
FROM hadolint/hadolint:v2.12.0-alpine

# GATE=1 marks "inside the gate image" so a consumer Makefile's `ci` target can
# run the real steps here and re-exec into this image everywhere else.
ENV GATE=1

COPY hadolint.yaml /etc/hadolint.yaml
COPY --chmod=0755 check /usr/local/bin/check

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/check"]
