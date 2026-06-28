#!/bin/bash
# tag — compute and push the next SemVer tag from Conventional Commits.
#
# On a merge to main this derives the next vMAJOR.MINOR.PATCH tag from the commit
# subjects since the latest tag, then creates and pushes an annotated tag. The
# bump is HARD-CAPPED at minor and NEVER touches major: a `feat:` is a minor, a
# fix/anything-else is a patch, and a breaking change (`type!:` or a
# `BREAKING CHANGE` footer) is still only a minor — a major release is a
# deliberate human act (and, for Go, also a `/vN` module-path migration), so it
# is never automated. With no existing tag the repo is seeded at SEED_VERSION.
#
# Usage:
#   tag.sh [run]                 # full flow: compute, tag, push (CI default)
#   tag.sh next-version V BUMP   # print the next version (V=vX.Y.Z, BUMP=minor|patch)
#   tag.sh detect-bump           # read commit subjects on stdin, print minor|patch
# Where (run mode, all optional, env-overridable):
#   SEED_VERSION       first tag when the repo has none.        Default: v0.1.0
#   NO_RELEASE_MARKER  opt-out file; if present, run is a no-op. Default: .no-autorelease
#   GIT_USER_NAME      committer name for the annotated tag.
#   GIT_USER_EMAIL     committer email for the annotated tag.
#
set -o errexit
set -o nounset
set -o pipefail

SEED_VERSION=${SEED_VERSION:-v0.1.0}
NO_RELEASE_MARKER=${NO_RELEASE_MARKER:-.no-autorelease}
GIT_USER_NAME=${GIT_USER_NAME:-github-actions[bot]}
GIT_USER_EMAIL=${GIT_USER_EMAIL:-41898282+github-actions[bot]@users.noreply.github.com}
readonly SEMVER_RE='^v[0-9]+\.[0-9]+\.[0-9]+$'
# Held in variables so the conditional parser does not choke on the literal
# parentheses (notably under bash 3.2). A breaking type token carries a `!`
# before the colon; a feature is `feat` with an optional `(scope)`.
readonly BREAKING_RE='^[a-z]+(\([^)]*\))?!:'
readonly FEAT_RE='^feat(\([^)]*\))?:'

# Pure: read commit subjects (one per line) on stdin, print the bump level. A
# breaking type token (`feat!:`, `refactor(api)!:`) or a `feat:` yields minor;
# everything else stays patch. Capped at minor by construction — never major.
detect-bump() {
  local line bump=patch
  while IFS= read -r line; do
    [[ ${line} =~ ${BREAKING_RE} ]] && {
      echo minor
      return 0
    }
    [[ ${line} =~ ${FEAT_RE} ]] && bump=minor
  done
  echo "${bump}"
}

# Pure: print the next version given a current vX.Y.Z and a bump (minor|patch).
# major is intentionally immutable.
next-version() {
  local current=${1} bump=${2} core major minor patch
  [[ ${current} =~ ${SEMVER_RE} ]] || {
    printf >&2 'tag: ✗ not a SemVer tag: %s\n' "${current}"
    return 2
  }
  core=${current#v}
  major=${core%%.*}
  minor=${core#*.}
  minor=${minor%%.*}
  patch=${core##*.}
  case "${bump}" in
    minor)
      ((minor++))
      patch=0
      ;;
    patch)
      ((patch++))
      ;;
    *)
      printf >&2 'tag: ✗ unknown bump level: %s\n' "${bump}"
      return 2
      ;;
  esac
  printf 'v%s.%s.%s\n' "${major}" "${minor}" "${patch}"
}

# Newest existing vX.Y.Z tag, or empty when the repo has none. The trailing
# `|| true` keeps a no-match grep (no tags yet) from tripping errexit.
latest-tag() {
  git tag --list 'v*' --sort=-version:refname |
    grep -E "${SEMVER_RE}" |
    head -n1 ||
    true
}

# Append a step output when running under Actions; a no-op locally.
emit() {
  [[ -n ${GITHUB_OUTPUT:-} ]] && printf '%s=%s\n' "${1}" "${2}" >>"${GITHUB_OUTPUT}"
  return 0
}

# Emit a CI notice when the range contains a breaking change, so the under-signal
# (a breaking change shipped as a mere minor) is at least visible in the log.
warn-breaking() {
  local range=${1}
  git log "${range}" --format='%B' |
    grep -qiE '(^|[[:space:]])BREAKING[ -]CHANGE' &&
    printf '::notice::%s\n' "breaking change detected; auto-release caps at minor — a major release needs a deliberate human tag (Go: also a /vN module-path migration)."
  return 0
}

create-and-push() {
  local version=${1}
  git config user.name "${GIT_USER_NAME}"
  git config user.email "${GIT_USER_EMAIL}"
  git tag --annotate "${version}" --message "${version}"
  git push origin "${version}"
}

run() {
  # Per-repo opt-out: a marker file in the workspace root disables auto-release
  # without removing the distributed workflow (which re-distribution would restore).
  [[ -f ${NO_RELEASE_MARKER} ]] && {
    printf '▸ %s present — auto-release opted out, nothing to do\n' "${NO_RELEASE_MARKER}"
    emit previous ''
    emit version ''
    emit bumped false
    return 0
  }

  git fetch --tags --quiet 2>/dev/null || true
  local prev next bump
  prev=$(latest-tag)

  [[ ${prev} ]] || {
    printf '▸ no existing tag — seeding %s\n' "${SEED_VERSION}"
    create-and-push "${SEED_VERSION}"
    emit previous ''
    emit version "${SEED_VERSION}"
    emit bumped true
    return 0
  }

  local count
  count=$(git rev-list --count "${prev}..HEAD")
  ((count > 0)) || {
    printf '▸ no commits since %s — nothing to release\n' "${prev}"
    emit previous "${prev}"
    emit version "${prev}"
    emit bumped false
    return 0
  }

  bump=$(git log --format='%s' "${prev}..HEAD" | detect-bump)
  next=$(next-version "${prev}" "${bump}")
  warn-breaking "${prev}..HEAD"
  printf '▸ %s → %s (%s)\n' "${prev}" "${next}" "${bump}"
  create-and-push "${next}"
  emit previous "${prev}"
  emit version "${next}"
  emit bumped true
}

case "${1:-run}" in
  run) run ;;
  detect-bump) detect-bump ;;
  next-version) next-version "${2:-}" "${3:-}" ;;
  *)
    printf >&2 'usage: tag.sh [run|detect-bump|next-version V BUMP]\n'
    exit 2
    ;;
esac
