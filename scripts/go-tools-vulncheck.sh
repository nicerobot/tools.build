#!/bin/bash
# go-tools-vulncheck — govulncheck (binary mode) over every installed pinned tool.
#
# Replaces the old shared-module `-scan=package` stanza scan now that each tool is
# installed via `go install path@version` with no shared go.mod. Scanning the
# baked binaries (`-mode=binary`) is reachability-based and precise: a CVE is
# attributed to the exact tool whose binary actually reaches the vulnerable
# symbol. Reports every tool, then exits non-zero if any vulnerability is found —
# unless that exact binary/id pair carries a reviewed exemption in
# go-tooling/security-exemptions.txt. An exemption that stops matching is itself a
# failure (STALE), so the ledger cannot silently decay into a blanket allowlist.
set -o errexit
set -o nounset
set -o pipefail

unset CDPATH

here="$(cd -- "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
readonly here
# shellcheck source=../go-tooling/tools-lib.sh
# shellcheck disable=SC1091 # sourced lib is its own shellcheck input
source "${here}/go-tooling/tools-lib.sh"

gobin="$(go env GOBIN)"
[[ -n "${gobin}" ]] || gobin="${HOME}/go/bin"
readonly gobin
readonly govulncheck="${gobin}/govulncheck"

if [[ ! -x "${govulncheck}" ]]; then
  echo "govulncheck not found in ${gobin} — run 'make tools' first." >&2
  exit 1
fi

# scan_tool runs govulncheck over one binary and reconciles what it reports
# against that binary's reviewed exemptions in security-exemptions.txt. It prints
# the full report whenever anything is unresolved and returns non-zero when the
# binary has a vulnerability that is NOT exempt, or an exemption that no longer
# matches anything (a stale entry, which must be deleted rather than left to rot).
scan_tool() {
  local name="$1" bin="$2"
  local report reported exempt_ids unresolved='' stale='' id

  echo "== govulncheck -mode=binary ${name}"
  exempt_ids="$(exempt_ids_for "${name}")"

  if report="$("${govulncheck}" -mode=binary "${bin}" 2>&1)"; then
    if [[ -z "${exempt_ids}" ]]; then
      echo "No vulnerabilities found."
      return 0
    fi
    echo "${report}"
    for id in ${exempt_ids}; do
      echo "STALE EXEMPTION: ${name} ${id} no longer reported — delete it from security-exemptions.txt"
    done
    return 1
  fi

  echo "${report}"
  reported="$(grep -oE 'GO-[0-9]{4}-[0-9]+' <<<"${report}" | sort -u)"

  for id in ${reported}; do
    if grep -qxF "${id}" <<<"${exempt_ids}"; then
      echo "EXEMPT: ${name} ${id} — $(exempt_reason "${name}" "${id}")"
    else
      unresolved+="${id} "
    fi
  done
  for id in ${exempt_ids}; do
    grep -qxF "${id}" <<<"${reported}" || stale+="${id} "
  done

  [[ -z "${stale}" ]] || echo "STALE EXEMPTION: ${name} ${stale% } no longer reported — delete it from security-exemptions.txt"
  [[ -z "${unresolved}" ]] || echo "UNRESOLVED: ${name} ${unresolved% }"
  [[ -z "${unresolved}${stale}" ]]
}

found=0
while IFS= read -r spec; do
  name="$(tool_bin "${spec}")"
  bin="${gobin}/${name}"
  if [[ ! -x "${bin}" ]]; then
    echo "skip (not installed): ${bin}"
    continue
  fi
  scan_tool "${name}" "${bin}" || found=1
done < <(manifest_specs)

exit "${found}"
