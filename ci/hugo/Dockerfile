# hugo — build/validate gate for Hugo-based GitHub Pages sites (e.g. the public/
# Hugo site in every <repo>.docs).
#
# Builds every Hugo site in the repo with the EXTENDED Hugo (SCSS/Sass support),
# failing on any build error so a site that no longer compiles never reaches
# Pages. The check script is POSIX sh, so the alpine base needs nothing added.
FROM hugomods/hugo:exts-0.140.2

# GATE=1 marks "inside the gate image" so a consumer Makefile's `ci` target can
# run the real steps here and re-exec into this image everywhere else.
ENV GATE=1

COPY --chmod=0755 check /usr/local/bin/check

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/check"]
