#!/bin/bash
# install-tools.sh — install the pinned tool set (tools.txt) into ${GOBIN}.
#
# Runs `go install path@version` for every manifest spec, so each tool is built
# in its own pinned module context (no shared go.mod here) — except a tool listed
# in security-pins.txt, which is built through a throwaway module so a fixed
# transitive dependency can be forced at the same tool version. The shared go gate
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

# The pins sidecar is REQUIRED, not optional. strip_comments treats a missing
# file as "no pins", so a copy that failed to ship it (an image whose COPY was
# not updated) would quietly install the UNPATCHED tools and still pass
# verify-tools.sh — green, and wrong. Refuse to run instead. The file may hold
# only comments when nothing currently needs a floor.
if [[ ! -f "${SECURITY_PINS}" ]]; then
  echo "missing ${SECURITY_PINS} — the pinned tool set cannot be installed without it." >&2
  exit 1
fi

gobin="$(go env GOBIN)"
if [[ -z "${gobin}" ]]; then
  gobin="${HOME}/go/bin"
  echo "GOBIN was unset; persisting GOBIN=${gobin} (go env -w) so the gate can find the tools."
  go env -w GOBIN="${gobin}"
fi
readonly gobin

# install_patched builds one tool at its pinned version inside a throwaway module
# that additionally REQUIRES the dependency floors recorded for it in
# security-pins.txt. `go install path@version` cannot express that — it builds in
# the tool's own module context, so a vulnerable transitive dependency there is
# fixable only by the tool's author. Building through a module we own applies the
# fix at the SAME tool version, with no suppression: `make vulncheck` still scans
# the resulting binary and must report it clean.
install_patched() {
  local spec="$1"
  local path="${spec%@*}"
  local bin workdir
  bin="$(tool_bin "${spec}")"
  workdir="$(mktemp -d)"
  (
    cd "${workdir}"
    export GOFLAGS=-mod=mod
    go mod init toolbuild >/dev/null
    go get "${spec}" >/dev/null
    while IFS= read -r pin; do
      echo "    security pin: ${pin}"
      go get "${pin}" >/dev/null
    done < <(security_pins_for "${path}")
    go build -o "${gobin}/${bin}" "${path}"
  )
  rm -rf "${workdir}"
}

echo "installing the pinned tool set into ${gobin} ..."
while IFS= read -r spec; do
  echo "==> ${spec}"
  if [[ -n "$(security_pins_for "${spec%@*}")" ]]; then
    install_patched "${spec}"
  else
    go install "${spec}"
  fi
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
