#!/bin/bash
# go-install-tools — install the pinned Go quality tool set into $GOBIN.
#
# Installs exactly the `tool (...)` stanza of go-tooling/go.mod (the single source
# of tool versions) as real binaries, via `go install tool`. The shared go gate
# (build/go/Makefile) resolves every tool from `go env GOBIN` ONLY, so GOBIN must
# be persistently set. If it is unset, this bootstraps a sensible default
# ($HOME/go/bin) with `go env -w` — override by setting GOBIN to your own
# directory first (`go env -w GOBIN=/your/dir`).
set -o errexit
set -o nounset
set -o pipefail

unset CDPATH

here="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly here
readonly gomod_dir="${here}/go-tooling"

gobin="$(go env GOBIN)"
if [[ -z "${gobin}" ]]; then
  gobin="${HOME}/go/bin"
  echo "GOBIN was unset; persisting GOBIN=${gobin} (go env -w) so the gate can find the tools."
  go env -w GOBIN="${gobin}"
fi
readonly gobin

echo "installing the pinned tool set into ${gobin} ..."
go -C "${gomod_dir}" install tool
echo "done. add ${gobin} to PATH to run the tools by name."
