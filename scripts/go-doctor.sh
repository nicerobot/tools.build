#!/bin/bash
# go-doctor — verify $GOBIN tool versions match the manifest, and warn when a
# Homebrew copy shadows one.
#
# First it runs verify-tools.sh: the proof that ~/go/bin holds exactly the
# versions in go-tooling/tools.txt (and therefore the same versions CI uses). Then
# it warns about bare-name shadowing: the go gate path-pins every tool to
# $(go env GOBIN), so a brew copy never affects it — but agents and humans that
# invoke a tool by BARE NAME pick whatever is first on PATH. The shadow check is
# warn-only; a version mismatch from verify is a hard failure.
set -o errexit
set -o nounset
set -o pipefail

unset CDPATH

here="$(cd -- "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
readonly here
# shellcheck source=../go-tooling/tools-lib.sh
# shellcheck disable=SC1091 # sourced lib is its own shellcheck input
source "${here}/go-tooling/tools-lib.sh"

# Hard gate: installed binaries must match the pinned manifest.
"${here}/go-tooling/verify-tools.sh"

if ! command -v brew >/dev/null 2>&1; then
  echo 'doctor: Homebrew not found — no shadow check needed.'
  exit 0
fi

prefix="$(brew --prefix 2>/dev/null || true)"
readonly prefix

shadowed=0
while IFS= read -r path; do
  tool="$(tool_bin "${path}")"
  resolved="$(command -v "${tool}" 2>/dev/null || true)"
  case "${resolved}" in
    "${prefix}"/*)
      echo "WARNING: '${tool}' resolves to a Homebrew copy at ${resolved} — the gate uses the pinned \$GOBIN/${tool}."
      shadowed=1
      ;;
  esac
done < <(manifest_paths)

if [[ "${shadowed}" -eq 0 ]]; then
  echo 'doctor: no Homebrew-shadowed tools — bare-name runs resolve to the pinned GOBIN.'
else
  echo "  -> 'brew uninstall <tool>' (and put \$GOBIN ahead on PATH) to stop the shadow."
fi
