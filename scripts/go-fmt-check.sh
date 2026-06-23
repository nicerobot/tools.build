#!/bin/bash
# go-fmt-check — fail if any Go file under the current module is not gofumpt-clean.
#
# The formatter command is passed as arguments (e.g. `go tool gofumpt`, or an
# absolute $GOBIN path), so the caller controls which pinned gofumpt is used. A
# module with no .go files passes trivially (gofumpt lists nothing).
set -o errexit
set -o nounset
set -o pipefail

if [[ "$#" -eq 0 ]]; then
  echo >&2 'usage: go-fmt-check <gofumpt-command> [args...]'
  exit 2
fi

unformatted="$("$@" -l .)"
if [[ -n "${unformatted}" ]]; then
  echo >&2 'not gofumpt-formatted:'
  echo >&2 "${unformatted}"
  exit 1
fi
echo 'fmt-check: clean'
