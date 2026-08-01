#!/bin/bash
# tools-lib.sh — shared parsing for the pinned tool manifest (tools.txt) and its
# two security sidecars (security-pins.txt, security-exemptions.txt).
#
# Sourced by install-tools.sh (and the repo-root maintenance scripts) so every
# manifest is read exactly one way everywhere. Defines TOOLS_MANIFEST plus
# manifest_specs (the `path@version` lines), manifest_paths (versionless import
# paths) and tool_bin (the installed binary name for a path); and
# SECURITY_PINS / SECURITY_EXEMPTIONS plus security_pins_for and exempt_ids_for.
set -o errexit
set -o nounset
set -o pipefail

unset CDPATH

# tools_lib_dir is the directory holding this library and tools.txt beside it.
tools_lib_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
readonly tools_lib_dir
readonly TOOLS_MANIFEST="${tools_lib_dir}/tools.txt"
readonly SECURITY_PINS="${tools_lib_dir}/security-pins.txt"
readonly SECURITY_EXEMPTIONS="${tools_lib_dir}/security-exemptions.txt"

# strip_comments emits a file's meaningful lines, dropping blank and `#` lines.
# A missing file yields nothing, so a sidecar is optional by construction.
strip_comments() {
  [[ -f "$1" ]] || return 0
  grep -vE '^[[:space:]]*(#|$)' "$1" || true
}

# manifest_specs emits each `importpath@version` spec, skipping blank and
# comment lines.
manifest_specs() {
  strip_comments "${TOOLS_MANIFEST}"
}

# security_pins_for emits the `module@version` dependency floors recorded for one
# tool import path (versionless), one per line; nothing when the tool has none.
security_pins_for() {
  strip_comments "${SECURITY_PINS}" | awk -v tool="$1" '$1 == tool { print $2 }'
}

# exempt_ids_for emits the reviewed-exempt vulnerability ids for one binary name,
# one per line; nothing when the binary has none.
exempt_ids_for() {
  strip_comments "${SECURITY_EXEMPTIONS}" | awk -v bin="$1" '$1 == bin { print $2 }'
}

# exempt_reason prints the recorded reason for one binary/id pair.
exempt_reason() {
  strip_comments "${SECURITY_EXEMPTIONS}" |
    awk -v bin="$1" -v id="$2" '$1 == bin && $2 == id { $1=""; $2=""; sub(/^ +/, ""); print; exit }'
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
