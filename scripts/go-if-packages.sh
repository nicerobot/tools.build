#!/bin/bash
# go-if-packages — run a command only if the current module has first-party
# packages; otherwise skip cleanly.
#
# Lets a tools-only module (no .go packages, e.g. go-tooling) present the standard
# package-scoped gate targets (vet/lint/staticcheck/test/cover) without failing on
# `matched no packages`. If first-party packages exist, the command runs as given.
set -o errexit
set -o nounset
set -o pipefail

if [[ "$#" -eq 0 ]]; then
  echo >&2 'usage: go-if-packages <command> [args...]'
  exit 2
fi

if [[ -z "$(go list ./... 2>/dev/null)" ]]; then
  echo "no first-party packages — skipping: $*"
  exit 0
fi

exec "$@"
