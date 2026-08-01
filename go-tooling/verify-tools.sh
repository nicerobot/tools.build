#!/bin/bash
# verify-tools.sh — assert every installed tool in ${GOBIN} matches tools.txt.
#
# For each manifest spec it reads the binary's embedded main-module version with
# `go version -m` (uniform across every Go tool, unlike each tool's bespoke
# --version flag) and compares it to the pinned version. This is the proof that a
# developer's ~/go/bin and the CI image hold the SAME tool versions — run it in
# both places and it passes in both, or names exactly what drifted. Exits non-zero
# on any missing or mismatched tool.
set -o errexit
set -o nounset
set -o pipefail

unset CDPATH

here="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly here
# shellcheck source=tools-lib.sh
# shellcheck disable=SC1091 # sourced lib is its own shellcheck input
source "${here}/tools-lib.sh"

gobin="$(go env GOBIN)"
[[ -n "${gobin}" ]] || gobin="${HOME}/go/bin"
readonly gobin

# installed_version prints the version of the module the binary's main package
# came from, or "" when the binary is absent or carries no module metadata.
#
# Normally that is the `mod` line: `go install path@version` records the tool's
# own module as the main module. A tool built through a security-pins.txt
# throwaway module instead records `toolbuild (devel)` there, so its real version
# is on the `dep` line for the module owning the main package — the
# longest-matching prefix of the `path` line. Reading both keeps ONE verification
# rule covering both install paths, so a patched tool is still held to tools.txt.
installed_version() {
  go version -m "$1" 2>/dev/null | awk '
    $1 == "path" { pkg = $2 }
    $1 == "mod"  { main = $3 }
    $1 == "dep" && index(pkg, $2) == 1 && length($2) > length(best) { best = $2; fallback = $3 }
    END { print (main != "" && main != "(devel)") ? main : fallback }
  '
}

drift=0
while IFS= read -r spec; do
  want="${spec#*@}"
  bin="${gobin}/$(tool_bin "${spec}")"
  if [[ ! -x "${bin}" ]]; then
    echo "MISSING: ${bin} (want ${spec})"
    drift=1
    continue
  fi
  got="$(installed_version "${bin}")"
  if [[ "${got}" != "${want}" ]]; then
    echo "DRIFT:   $(tool_bin "${spec}") is ${got:-unknown}, manifest pins ${want}"
    drift=1
  fi
done < <(manifest_specs)

if [[ "${drift}" -eq 0 ]]; then
  echo "verify: all $(manifest_specs | wc -l | tr -d ' ') tools in ${gobin} match tools.txt."
else
  echo "verify: tool versions drifted from tools.txt — run 'make tools' to reinstall." >&2
  exit 1
fi
