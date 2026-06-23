#!/bin/bash
# go-tidy-check — fail if go.mod / go.sum in the current dir are not tidy.
#
# Snapshots both files, runs `go mod tidy`, and fails if either changed —
# restoring the originals either way so the working tree is never left mutated.
set -o errexit
set -o nounset
set -o pipefail

cp go.mod go.mod.bak
had_sum=0
if [[ -f go.sum ]]; then
  had_sum=1
  cp go.sum go.sum.bak
fi

go mod tidy

rc=0
diff -q go.mod go.mod.bak >/dev/null 2>&1 || rc=1
if [[ "${had_sum}" -eq 1 ]]; then
  diff -q go.sum go.sum.bak >/dev/null 2>&1 || rc=1
elif [[ -f go.sum ]]; then
  rc=1
fi

mv go.mod.bak go.mod
if [[ "${had_sum}" -eq 1 ]]; then
  mv go.sum.bak go.sum
else
  rm -f go.sum
fi

if [[ "${rc}" -eq 1 ]]; then
  echo >&2 "go.mod/go.sum are not tidy — run 'make tidy'"
fi
exit "${rc}"
