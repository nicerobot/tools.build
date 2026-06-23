#!/bin/bash
# go-tooling-demo — run the go-tooling image's gate against a throwaway sample
# module, proving the bundled toolchain works end to end. Takes the image ref.
set -o errexit
set -o nounset
set -o pipefail

image="${1:?usage: go-tooling-demo <image:tag>}"

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

printf 'package main\n\nimport "fmt"\n\nfunc main() { fmt.Println("ok") }\n' >"${tmp}/main.go"
go -C "${tmp}" mod init demo.example >/dev/null

docker run --rm -v "${tmp}:/src" -w /src "${image}" \
  make -f /opt/go-tooling/tools.mk fmt-check lint analyze
