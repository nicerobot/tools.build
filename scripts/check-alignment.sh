#!/bin/bash
# check-alignment — assert the single-source contract (spec D2 / AC2):
#   1. the go-make Makefile's TOOL_PKGS == the go-tooling go.mod `tool` block,
#   2. go-make/golangci.yaml is byte-identical to go-tooling/.golangci.yml.
# Co-location makes alignment a local check, not cross-repo verification. Run by
# build-tools CI; fails loudly on any drift.
set -o errexit
set -o nounset
set -o pipefail

here="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly here
readonly gomod="${here}/go-tooling/go.mod"
readonly makefile="${here}/go-make/Makefile"
readonly canonical_cfg="${here}/go-tooling/.golangci.yml"
readonly consumer_cfg="${here}/go-make/golangci.yaml"

# Tool import paths declared in the go-tooling go.mod `tool (...)` block.
gomod_tools() {
  awk '/^tool \(/{f=1;next} /^\)/{f=0} f{gsub(/[ \t]/,"");print}' "${gomod}" | sort -u
}

# Tool import paths listed in the Makefile TOOL_PKGS variable. The list is a
# backslash-continued assignment; collect every slash-bearing token from the
# TOOL_PKGS line until the first line without a trailing backslash.
makefile_tools() {
  awk '
    /^TOOL_PKGS[ \t]*:?=/ {inblk=1}
    inblk {
      had_cont = /\\[ \t]*$/
      gsub(/\\/, "")
      for (i = 1; i <= NF; i++) if ($i ~ /\//) print $i
      if (!had_cont) exit
    }
  ' "${makefile}" | sort -u
}

status=0

echo '== tool-set alignment (go-make Makefile <-> go-tooling go.mod) =='
if diff <(gomod_tools) <(makefile_tools); then
  echo "ok: $(gomod_tools | wc -l | tr -d ' ') tools aligned"
else
  echo >&2 'ERROR: TOOL_PKGS drift (< = only in go.mod, > = only in Makefile)'
  status=1
fi

echo '== golangci config identity (canonical <-> consumer) =='
if cmp -s "${canonical_cfg}" "${consumer_cfg}"; then
  echo 'ok: go-make/golangci.yaml is identical to the canonical config'
else
  echo >&2 'ERROR: go-make/golangci.yaml has drifted from go-tooling/.golangci.yml'
  status=1
fi

exit "${status}"
