#!/bin/bash
# install-tools.sh — install the pinned Node tool set (tools.txt) into
# ${NODE_TOOLS_PREFIX}.
#
# The Node counterpart of go-tooling/install-tools.sh, with the same contract:
# one manifest is the single source of every tool version, installed identically
# on a developer's machine and in the image, so the two cannot drift.
#
# Installs into a PREFIX of its own rather than the system-wide default, so the
# tools are addressable as one directory — that is what lets a consumer Makefile
# resolve a tool from an exact location instead of from PATH, where whatever the
# project happens to have installed would answer first.
set -o errexit
set -o nounset
set -o pipefail

unset CDPATH

here="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly here

# Default matches the image's layout; override to install elsewhere locally.
prefix="${NODE_TOOLS_PREFIX:-/opt/node-tools}"
readonly prefix

mkdir -p "${prefix}"

# strip_comments yields the manifest's specs: blank lines and # comments out.
strip_comments() {
  sed -E 's/#.*$//; s/[[:space:]]+$//' "${1}" | grep -v '^[[:space:]]*$' || true
}

specs=()
while IFS= read -r spec; do
  test -n "${spec}" || continue
  specs+=("${spec}")
done < <(strip_comments "${here}/tools.txt")

test "${#specs[@]}" -gt 0 || {
  echo "no tool specs in ${here}/tools.txt" >&2
  exit 1
}

echo "==> installing ${#specs[@]} tool(s) into ${prefix}"
for spec in "${specs[@]}"; do
  echo "==> ${spec}"
done

# One npm invocation for the whole set: npm resolves them together, and a
# per-tool loop would reinstall shared transitive packages once per tool.
#
# --no-audit and --no-fund because this is a tool install, not a project
# install: an audit report here names vulnerabilities in build tooling, which is
# exactly the noise this manifest exists to keep out of consumer repositories,
# and it is dealt with by changing a pin in tools.txt.
npm install --global --prefix "${prefix}" --no-audit --no-fund "${specs[@]}"

echo "done. add ${prefix}/bin to PATH to run the tools by name."
