# java — JVM quality gate.
#
# Runs the consumer's `make ci` target with the pinned Temurin JDK. Gradle
# itself comes from the consumer's committed wrapper (gradle-wrapper.properties
# pins the distribution), so the image carries only the JDK + make and the gate
# and a local containerized `make ci` are identical.
FROM eclipse-temurin:21-jdk-noble

# GATE=1 marks "inside the gate image" so a consumer Makefile's `ci` target can
# run the real steps here and re-exec into this image everywhere else.
ENV GATE=1

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends make git ca-certificates; \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 check /usr/local/bin/check

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/check"]
