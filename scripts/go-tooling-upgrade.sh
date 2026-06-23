#!/bin/bash
# go-tooling-upgrade — bump every tool in the current module's stanza to @latest,
# then tidy. Drives the canonical tool-version refresh for go-tooling.
set -o errexit
set -o nounset
set -o pipefail

while IFS= read -r tool; do
  echo "==> ${tool}@latest"
  go get -tool "${tool}@latest"
done < <(go list tool)

go mod tidy
