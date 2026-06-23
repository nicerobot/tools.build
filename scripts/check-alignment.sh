#!/bin/bash
# check-alignment — assert the single-source contract (spec D2 / AC2):
#   1. every tool the go build Makefile INVOKES (TOOL_BASENAMES) is PROVIDED by
#      the go-tooling go.mod `tool` block. The canonical tool set + its versions
#      live ONLY in go-tooling/go.mod now; the Makefile no longer duplicates that
#      list (it installs from the stanza into $GOBIN), it only references binary
#      names — so the invariant is a SUBSET check, not list equality. This catches
#      a Makefile that calls a tool the central image would not bake.
#   2. build/go/.golangci.yaml is byte-identical to go-tooling/.golangci.yml.
# Co-location makes alignment a local check, not cross-repo verification. Run by
# tools.build CI; fails loudly on any drift.
set -o errexit
set -o nounset
set -o pipefail

# Unset CDPATH so `cd` never echoes the resolved directory (it does when CDPATH
# is set in the environment), which would otherwise corrupt the captured path.
unset CDPATH

here="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly here
readonly gomod="${here}/go-tooling/go.mod"
readonly makefile="${here}/build/go/Makefile"
readonly canonical_cfg="${here}/go-tooling/.golangci.yml"
readonly consumer_cfg="${here}/build/go/.golangci.yaml"

# Binary names PROVIDED by the go-tooling go.mod `tool (...)` block. The binary a
# `go install` produces is the last path segment, or the segment before a
# trailing major-version element (.../goreleaser/v2 -> goreleaser, .../cmd/gosec
# -> gosec). Mirror that rule so the set matches what lands in $GOBIN.
gomod_bins() {
  awk '/^tool \(/{f=1;next} /^\)/{f=0} f{gsub(/[ \t]/,"");print}' "${gomod}" |
    awk -F/ '{ last=$NF; if (last ~ /^v[0-9]+$/) last=$(NF-1); print last }' |
    sort -u
}

# Binary names the Makefile INVOKES, listed in its TOOL_BASENAMES variable
# (a single space-separated assignment).
makefile_bins() {
  awk '/^TOOL_BASENAMES[ \t]*:?=/ { sub(/^[^=]*=[ \t]*/, ""); n = split($0, a, " "); for (i = 1; i <= n; i++) if (a[i] != "") print a[i] }' "${makefile}" | sort -u
}

status=0

echo '== tool-set alignment (build/go/Makefile invokes ⊆ go-tooling go.mod provides) =='
missing="$(comm -23 <(makefile_bins) <(gomod_bins) || true)"
if [ -z "${missing}" ]; then
  echo "ok: all $(makefile_bins | wc -l | tr -d ' ') invoked tools are provided by the go-tooling stanza"
else
  echo >&2 'ERROR: build/go/Makefile invokes tools the go-tooling stanza does not provide:'
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
