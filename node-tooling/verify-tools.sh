#!/bin/bash
# verify-tools.sh — assert every installed tool matches tools.txt.
#
# The Node counterpart of go-tooling/verify-tools.sh. It reads each installed
# package's own package.json rather than running `<tool> --version`, because the
# manifest names PACKAGES and a CLI's version flag is bespoke per tool (and some
# print a banner, or phone home, or need a subcommand). package.json is uniform.
#
# This is the proof that a developer's prefix and the image hold the SAME
# versions: run it in both places and it passes in both, or names exactly what
# drifted. Exits non-zero on any missing or mismatched tool.
set -o errexit
set -o nounset
set -o pipefail

unset CDPATH

here="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly here

prefix="${NODE_TOOLS_PREFIX:-/opt/node-tools}"
readonly prefix

strip_comments() {
  sed -E 's/#.*$//; s/[[:space:]]+$//' "${1}" | grep -v '^[[:space:]]*$' || true
}

# split_spec sets `name` and `want` from a package@version spec, handling scoped
# packages, whose name itself begins with @ and contains a slash.
name=''
want=''
split_spec() {
  local spec="${1}"
  local at="${spec##*@}"
  name="${spec%@*}"
  want="${at}"
}

# installed_version prints the version recorded in the installed package's own
# package.json, or nothing when the package is absent.
installed_version() {
  local pkg="${1}" manifest
  manifest="${prefix}/lib/node_modules/${pkg}/package.json"
  test -f "${manifest}" || return 0
  node -e 'process.stdout.write(require(process.argv[1]).version)' "${manifest}" 2>/dev/null || true
}

failed=0
while IFS= read -r spec; do
  test -n "${spec}" || continue
  split_spec "${spec}"
  got="$(installed_version "${name}")"
  if [[ -z "${got}" ]]; then
    printf 'MISSING  %-28s want %s\n' "${name}" "${want}" >&2
    failed=1
  elif [[ "${got}" != "${want}" ]]; then
    printf 'MISMATCH %-28s want %s, got %s\n' "${name}" "${want}" "${got}" >&2
    failed=1
  else
    printf 'ok       %-28s %s\n' "${name}" "${got}"
  fi
done < <(strip_comments "${here}/tools.txt")

test "${failed}" -eq 0 || {
  echo "installed Node tools do not match tools.txt" >&2
  exit 1
}
