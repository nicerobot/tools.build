#!/bin/bash
# install-tools.sh — install the pinned tool set (tools.txt) into $GOBIN.
#
# Runs `go install path@version` for every manifest spec, so each tool is built
# in its own pinned module context (no shared go.mod here). The shared go gate
# (build/go/Makefile) resolves every tool from `go env GOBIN` ONLY, so GOBIN must
# be set: if it is unset this bootstraps $HOME/go/bin with `go env -w` (override
# by setting GOBIN first, e.g. `go env -w GOBIN=/your/dir`). The go-tooling image
# sets GOBIN before calling this, so local and CI install identically.
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
if [[ -z "${gobin}" ]]; then
  gobin="${HOME}/go/bin"
  echo "GOBIN was unset; persisting GOBIN=${gobin} (go env -w) so the gate can find the tools."
  go env -w GOBIN="${gobin}"
fi
readonly gobin

echo "installing the pinned tool set into ${gobin} ..."
while IFS= read -r spec; do
  echo "==> ${spec}"
  go install "${spec}"
done < <(manifest_specs)
echo "done. add ${gobin} to PATH to run the tools by name."
