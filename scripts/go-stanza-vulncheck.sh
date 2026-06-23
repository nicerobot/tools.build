#!/bin/bash
# go-stanza-vulncheck — govulncheck scan of a tools-only module's `tool (...)`
# stanza.
#
# govulncheck cannot module-scan a package-less module, so scan the tool packages
# themselves — deriving the list straight from the stanza (`go list tool`) so it
# can never drift. Package-level scan (not symbol) is robust across the large tool
# graphs and conservative (flags any imported vulnerable package). Mirrors the
# scheduled vulncheck.yml workflow. Runs against the module in the current dir.
set -o errexit
set -o nounset
set -o pipefail

tools="$(go list tool)"
if [[ -z "${tools}" ]]; then
  echo 'no tools in the stanza — nothing to scan'
  exit 0
fi

echo "${tools}" | xargs go tool govulncheck -scan=package
