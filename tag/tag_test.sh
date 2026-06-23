#!/bin/bash
# tag_test — verify tag.sh against the auto-versioning contract. Exercises the two
# pure seams (next-version, detect-bump) over a fixture matrix, then runs the full
# `run` flow against a throwaway local repo wired to a bare remote so the tag push
# is verified end to end — no network, no GitHub.
#
# Usage:
#   tag_test.sh                  # run every case; exit 0 only if all pass
#
set -o errexit
set -o nounset
set -o pipefail

# Unset CDPATH so `cd` never echoes the resolved directory (it does when CDPATH
# is set in the environment), which would otherwise corrupt the captured path.
unset CDPATH

here="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly here
readonly tag="${here}/tag.sh"
fails=0

# Compare in the main shell, counting into the global tally and continuing so the
# whole matrix is reported. Used by the pure-seam tests.
check() {
  local label=${1} expected=${2} actual=${3}
  [[ ${actual} == "${expected}" ]] && {
    printf '  ✓ %s\n' "${label}"
    return 0
  }
  printf '  ✗ %s: expected %q, got %q\n' "${label}" "${expected}" "${actual}"
  ((fails++)) || true
}

# Assert `cmd...` exits non-zero (a rejection path), counting into the tally.
check-fail() {
  local label=${1}
  shift
  "${@}" >/dev/null 2>&1 && {
    printf '  ✗ %s: expected non-zero exit\n' "${label}"
    ((fails++)) || true
    return 0
  }
  printf '  ✓ %s\n' "${label}"
}

# Compare inside an isolated subshell: on mismatch print and exit the subshell
# non-zero so the parent's `|| ((fails++))` records exactly one failure per case.
must() {
  local label=${1} expected=${2} actual=${3}
  [[ ${actual} == "${expected}" ]] && {
    printf '  ✓ %s\n' "${label}"
    return 0
  }
  printf '  ✗ %s: expected %q, got %q\n' "${label}" "${expected}" "${actual}"
  exit 1
}

test-next-version() {
  printf 'next-version:\n'
  check 'patch bumps patch' v1.2.4 "$(bash "${tag}" next-version v1.2.3 patch)"
  check 'minor bumps minor, zeroes patch' v1.3.0 "$(bash "${tag}" next-version v1.2.3 minor)"
  check 'major is never touched (minor)' v9.1.0 "$(bash "${tag}" next-version v9.0.7 minor)"
  check 'double-digit components' v1.11.0 "$(bash "${tag}" next-version v1.10.42 minor)"
  check-fail 'rejects non-semver input' bash "${tag}" next-version 1.2.3 patch
  check-fail 'rejects unknown bump level' bash "${tag}" next-version v1.2.3 major
}

test-detect-bump() {
  printf 'detect-bump:\n'
  check 'fix only → patch' patch "$(printf 'fix: a\nchore: b\n' | bash "${tag}" detect-bump)"
  check 'a feat → minor' minor "$(printf 'fix: a\nfeat: b\n' | bash "${tag}" detect-bump)"
  check 'scoped feat → minor' minor "$(printf 'feat(api): b\n' | bash "${tag}" detect-bump)"
  check 'breaking type → minor (capped)' minor "$(printf 'refactor(core)!: drop x\n' | bash "${tag}" detect-bump)"
  check 'no commits → patch' patch "$(printf '' | bash "${tag}" detect-bump)"
  check 'non-conventional → patch' patch "$(printf 'merge branch main\n' | bash "${tag}" detect-bump)"
}

# Run `body` (a function name) in an isolated repo + bare remote, always cleaning
# up. The subshell's exit status is the body's, so a `must` failure surfaces here.
with-repo() {
  local body=${1} work remote
  work=$(mktemp -d)
  remote=$(mktemp -d)
  (
    git init --quiet --bare "${remote}"
    cd "${work}"
    git init --quiet
    git config user.name test
    git config user.email test@example.com
    git remote add origin "${remote}"
    git commit --quiet --allow-empty -m 'feat: initial'
    git branch -M main
    git push --quiet origin main
    "${body}"
  ) || ((fails++))
  rm -rf "${work}" "${remote}"
  return 0
}

case-seed() {
  bash "${tag}" run >/dev/null
  must 'seeds untagged repo at v0.1.0' v0.1.0 "$(git tag)"
}

case-bump() {
  git tag v1.4.2
  git push --quiet origin v1.4.2
  git commit --quiet --allow-empty -m 'feat: add thing'
  bash "${tag}" run >/dev/null
  must 'feat since v1.4.2 → v1.5.0' v1.5.0 "$(git describe --tags --abbrev=0)"
}

case-noop() {
  git tag v2.0.0
  git push --quiet origin v2.0.0
  bash "${tag}" run >/dev/null
  must 'no new commits → no new tag' v2.0.0 "$(git tag --list 'v*' | sort | tail -n1)"
}

case-optout() {
  git tag v3.0.0
  git push --quiet origin v3.0.0
  git commit --quiet --allow-empty -m 'feat: would bump but for opt-out'
  : >.no-autorelease
  bash "${tag}" run >/dev/null
  must 'opt-out marker → no new tag' v3.0.0 "$(git tag --list 'v*' | sort | tail -n1)"
}

test-next-version
test-detect-bump
printf 'run (seed):\n'
with-repo case-seed
printf 'run (incremental):\n'
with-repo case-bump
printf 'run (nothing to release):\n'
with-repo case-noop
printf 'run (opt-out marker):\n'
with-repo case-optout

((fails == 0)) || {
  printf '\n✗ %d check(s) failed\n' "${fails}"
  exit 1
}
printf '\n✓ all checks passed\n'
