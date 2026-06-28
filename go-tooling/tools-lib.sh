#!/bin/bash
# tools-lib.sh — shared parsing for the pinned tool manifest (tools.txt).
#
# Sourced by install-tools.sh (and the repo-root maintenance scripts) so the
# manifest is read exactly one way everywhere. Defines TOOLS_MANIFEST and three
# helpers: manifest_specs (the `path@version` lines), manifest_paths (versionless
# import paths), and tool_bin (the installed binary name for a path).
set -o errexit
set -o nounset
set -o pipefail

unset CDPATH

# tools_lib_dir is the directory holding this library and tools.txt beside it.
tools_lib_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
readonly tools_lib_dir
readonly TOOLS_MANIFEST="${tools_lib_dir}/tools.txt"

# manifest_specs emits each `importpath@version` spec, skipping blank and
# comment lines.
manifest_specs() {
  grep -vE '^[[:space:]]*(#|$)' "${TOOLS_MANIFEST}"
}

# manifest_paths emits each tool's versionless import path (the part before @).
manifest_paths() {
  manifest_specs | sed 's/@.*//'
}

# tool_bin prints the installed binary name for an import path: the last path
# segment, or the segment before a trailing major-version element
# (.../goreleaser/v2 -> goreleaser).
tool_bin() {
  awk -F/ '{ last=$NF; if (last ~ /^v[0-9]+$/) last=$(NF-1); print last }' <<<"${1%@*}"
}
