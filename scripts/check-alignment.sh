#!/bin/bash
# check-alignment — assert the single-source contract (spec D2 / AC2):
#   1. every tool the go build Makefile INVOKES (via $(gobin-or-die)/<name>) is
#      PROVIDED by the go-tooling tools.txt manifest. The canonical tool set + its
#      versions live ONLY in go-tooling/tools.txt now; the Makefile no longer
#      duplicates that list (it resolves binaries from ${GOBIN}), it only references
#      binary names — so the invariant is a SUBSET check, not list equality. This
#      catches a Makefile that calls a tool the central image would not bake.
#   2. build/go/.golangci.yaml is byte-identical to go-tooling/.golangci.yml.
# Co-location makes alignment a local check, not cross-repo verification. Run by
# tools.build CI; fails loudly on any drift.
set -o errexit
set -o nounset
set -o pipefail

# Unset CDPATH so `cd` never echoes the resolved directory (it does when CDPATH
# is set in the environment), which would otherwise corrupt the captured path.
unset CDPATH

here="$(cd -- "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
readonly here
readonly makefile="${here}/build/go/Makefile"
readonly canonical_cfg="${here}/go-tooling/.golangci.yml"
readonly consumer_cfg="${here}/build/go/.golangci.yaml"
# shellcheck source=../go-tooling/tools-lib.sh
# shellcheck disable=SC1091 # sourced lib is its own shellcheck input
source "${here}/go-tooling/tools-lib.sh"

# Binary names PROVIDED by the tools.txt manifest (the names that land in ${GOBIN}).
manifest_bins() {
  while IFS= read -r path; do tool_bin "${path}"; done < <(manifest_paths) | sort -u
}

# Binary names the Makefile INVOKES, taken from its $(gobin-or-die)/<name> tool
# variable assignments (the only way the gate names a tool in the ${GOBIN} model).
makefile_bins() {
  grep -oE 'gobin-or-die\)/[A-Za-z0-9_-]+' "${makefile}" | sed 's#.*/##' | sort -u
}

status=0

echo '== tool-set alignment (build/go/Makefile invokes ⊆ go-tooling tools.txt provides) =='
missing="$(comm -23 <(makefile_bins) <(manifest_bins) || true)"
if [ -z "${missing}" ]; then
  echo "ok: all $(makefile_bins | wc -l | tr -d ' ') invoked tools are provided by the tools.txt manifest"
else
  echo >&2 'ERROR: build/go/Makefile invokes tools the tools.txt manifest does not provide:'
  echo >&2 "${missing}"
  status=1
fi

echo '== golangci config identity (canonical <-> consumer) =='
if cmp -s "${canonical_cfg}" "${consumer_cfg}"; then
  echo 'ok: build/go/.golangci.yaml is identical to the canonical config'
else
  echo >&2 'ERROR: build/go/.golangci.yaml has drifted from go-tooling/.golangci.yml'
  status=1
fi

exit "${status}"
