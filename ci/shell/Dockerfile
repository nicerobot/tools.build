# shell — shellcheck + shfmt gate for every shell script in the repo.
#
# shellcheck catches bugs; shfmt enforces formatting at 2-space indent to match
# the repo .editorconfig ([*.sh] indent_style = space, indent_size = 2). Both
# binaries are static, so they drop straight into the shellcheck base image.
FROM koalaman/shellcheck-alpine:v0.10.0

# shfmt is a single static Go binary; copy it from its published image.
COPY --from=mvdan/shfmt:v3.10.0 /bin/shfmt /usr/local/bin/shfmt

# bash + GNU coreutils/findutils/grep for the check script (the base is busybox).
RUN apk add --no-cache bash coreutils findutils grep

COPY --chmod=0755 check /usr/local/bin/check

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/check"]
