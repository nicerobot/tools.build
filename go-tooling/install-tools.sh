#!/bin/bash
# install-tools.sh — install the pinned tool set (tools.txt) into ${GOBIN}.
#
# Runs `go install path@version` for every manifest spec, so each tool is built
# in its own pinned module context (no shared go.mod here). The shared go gate
# (build/go/Makefile) resolves every tool from `go env GOBIN` ONLY, so GOBIN must
# be set: if it is unset this bootstraps ${HOME}/go/bin with `go env -w` (override
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

# Install the central stickler config (the GLOBAL layer `make lint` inherits) so a
# developer's local lint matches CI — stickler reads ${XDG_CONFIG_HOME}/stickler/
# config.yaml, defaulting to ~/.config. A repo's .stickler.yaml layers over it.
# Skipped when the source is absent: the go-tooling image's tools stage runs this
# to build binaries and does not COPY the config (its final stage installs it).
if [[ -f "${here}/stickler.config.yaml" ]]; then
  stickler_config_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/stickler"
  mkdir -p "${stickler_config_dir}"
  cp "${here}/stickler.config.yaml" "${stickler_config_dir}/config.yaml"
  echo "installed central stickler config -> ${stickler_config_dir}/config.yaml"
fi

echo "done. add ${gobin} to PATH to run the tools by name."
