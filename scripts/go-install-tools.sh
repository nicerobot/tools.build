#!/bin/bash
# go-install-tools — install the pinned Go tool set into ${GOBIN}.
#
# Stable entrypoint for consumers (`$(TOOLS_BUILD)/scripts/go-install-tools.sh`),
# delegating to the manifest installer that the go-tooling image also uses — so a
# developer's ~/go/bin and CI install the identical pinned versions from the one
# source of truth, go-tooling/tools.txt.
set -o errexit
set -o nounset
set -o pipefail

unset CDPATH

here="$(cd -- "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
readonly here

exec "${here}/go-tooling/install-tools.sh"
