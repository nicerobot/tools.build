#!/bin/bash
# go-tools-vulncheck — govulncheck (binary mode) over every installed pinned tool.
#
# Replaces the old shared-module `-scan=package` stanza scan now that each tool is
# installed via `go install path@version` with no shared go.mod. Scanning the
# baked binaries (`-mode=binary`) is reachability-based and precise: a CVE is
# attributed to the exact tool whose binary actually reaches the vulnerable
# symbol. Reports every tool, then exits non-zero if any vulnerability is found.
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
readonly govulncheck="${gobin}/govulncheck"

if [[ ! -x "${govulncheck}" ]]; then
  echo "govulncheck not found in ${gobin} — run 'make tools' first." >&2
  exit 1
fi

found=0
while IFS= read -r spec; do
  bin="${gobin}/$(tool_bin "${spec}")"
  if [[ ! -x "${bin}" ]]; then
    echo "skip (not installed): ${bin}"
    continue
  fi
  echo "== govulncheck -mode=binary $(tool_bin "${spec}")"
  "${govulncheck}" -mode=binary "${bin}" || found=1
done < <(manifest_specs)

exit "${found}"
