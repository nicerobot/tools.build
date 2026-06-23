# gomatic/runtime — the shared RUNTIME base image for gomatic Go services.
#
# Counterpart to build.dockerfile (which bakes the BUILD toolchain). Every
# service's runtime Dockerfile was ~90% identical: the same unprivileged user,
# the same minimal base, the same USER/WORKDIR — and each repo pinned the same
# base independently, drifting over time. That is the per-repo churn gomatic/build
# exists to kill, applied to the image instead of the tools. Pin the base ONCE
# here (bump the digest in one place); consumers `FROM` this.
#
# distroless/static:nonroot is the minimal base every Go service shares: it
# carries ca-certificates + tzdata, an /etc/passwd with a nonroot user (uid
# 65532), and no shell or package manager. A consumer Dockerfile collapses to
# COPY + ENTRYPOINT:
#
#   FROM gomatic/runtime
#   ARG TARGETARCH
#   ARG ENTRYPOINT_BIN          # supplied by the shared `docker` make target
#   COPY dist/${ENTRYPOINT_BIN}-linux-${TARGETARCH} /bin/${ENTRYPOINT_BIN}
#   ENTRYPOINT ["/bin/myservice"]
#   CMD ["version"]
#
# Repo-specific extras stay in the consumer Dockerfile — gomatic/runtime carries
# only what is genuinely common. To lock the base, replace the tag below with a
# @sha256:... digest: the single place every consumer's runtime is pinned.

FROM gcr.io/distroless/static:nonroot

# distroless/static:nonroot already sets USER nonroot (uid 65532); make HOME and
# WORKDIR explicit so crash logs and relative paths resolve predictably.
ENV HOME=/home/nonroot
USER nonroot:nonroot
WORKDIR /home/nonroot

# No ENTRYPOINT: the consumer sets it to its own binary (so `ps`/crash logs show
# the real service name). The shared `docker` make target passes the binary via
# the ENTRYPOINT_BIN build-arg for the COPY path.
