#!/bin/bash
# go-doctor — warn when a Homebrew copy shadows a pinned $GOBIN tool.
#
# The go gate path-pins every tool to $(go env GOBIN), so a brew copy never
# affects it — but agents and humans that invoke a tool by BARE NAME pick whatever
# is first on PATH. This reports any canonical tool (derived from go-tooling's
# `tool (...)` stanza) whose bare-name resolution lands in the Homebrew prefix.
# Warn-only; it never fails.
set -o errexit
set -o nounset
set -o pipefail

unset CDPATH

here="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly here
readonly gomod="${here}/go-tooling/go.mod"

if ! command -v brew >/dev/null 2>&1; then
  echo 'doctor: Homebrew not found — nothing to check.'
  exit 0
fi

prefix="$(brew --prefix 2>/dev/null || true)"
readonly prefix

# Binary names provided by the stanza: the last path segment, or the one before a
# trailing major-version element (.../goreleaser/v2 -> goreleaser).
tool_binaries() {
  awk '/^tool \(/{f=1;next} /^\)/{f=0} f{gsub(/[ \t]/,"");print}' "${gomod}" |
    awk -F/ '{ last=$NF; if (last ~ /^v[0-9]+$/) last=$(NF-1); print last }' |
    sort -u
}

shadowed=0
while IFS= read -r tool; do
  resolved="$(command -v "${tool}" 2>/dev/null || true)"
  case "${resolved}" in
    "${prefix}"/*)
      echo "WARNING: '${tool}' resolves to a Homebrew copy at ${resolved} — the gate uses the pinned \$GOBIN/${tool}."
      shadowed=1
      ;;
  esac
done < <(tool_binaries)

if [[ "${shadowed}" -eq 0 ]]; then
  echo 'doctor: no Homebrew-shadowed tools — bare-name runs resolve to the pinned GOBIN.'
else
  echo "  -> 'brew uninstall <tool>' (and put \$GOBIN ahead on PATH) to stop the shadow."
fi
