#!/bin/bash
# go-tooling-upgrade — bump every tool in tools.txt to its latest release.
#
# For each pinned spec it installs path@latest into $GOBIN, reads back the
# resolved version with `go version -m`, and rewrites the manifest line to that
# version — preserving the file's comments and grouping. After it runs, $GOBIN and
# tools.txt are both on the new versions (verify-tools.sh passes). Commit the
# manifest change and rebuild the image to roll the new versions to CI.
set -o errexit
set -o nounset
set -o pipefail

unset CDPATH

here="$(cd -- "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
readonly here
# shellcheck source=../go-tooling/tools-lib.sh
# shellcheck disable=SC1091 # sourced lib is its own shellcheck input
source "${here}/go-tooling/tools-lib.sh"

gobin="$(go env GOBIN)"
[[ -n "${gobin}" ]] || gobin="${HOME}/go/bin"
readonly gobin

updated="$(mktemp)"
trap 'rm -f "${updated}"' EXIT

while IFS= read -r line; do
  if [[ "${line}" =~ ^[[:space:]]*(#|$) ]]; then
    printf '%s\n' "${line}"
    continue
  fi
  path="${line%@*}"
  echo "==> ${path}@latest" >&2
  go install "${path}@latest" >&2
  version="$(go version -m "${gobin}/$(tool_bin "${path}")" | awk '$1 == "mod" { print $3; exit }')"
  printf '%s@%s\n' "${path}" "${version}"
done <"${TOOLS_MANIFEST}" >"${updated}"

cp "${updated}" "${TOOLS_MANIFEST}"
echo "updated ${TOOLS_MANIFEST}; run 'make verify' to confirm \$GOBIN matches." >&2
