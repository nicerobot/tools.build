# terraform — fmt check + tflint gate for Terraform configuration.
#
# `terraform fmt -check` enforces canonical formatting; tflint catches provider
# misconfiguration, deprecated syntax, and unused declarations that `fmt` and
# `validate` miss. tflint is a static Go binary copied from its published image.
FROM hashicorp/terraform:1.10

COPY --from=ghcr.io/terraform-linters/tflint:v0.54.0 /usr/local/bin/tflint /usr/local/bin/tflint

# bash for the check script (the terraform base is alpine/busybox).
RUN apk add --no-cache bash

COPY --chmod=0755 check /usr/local/bin/check

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/check"]
