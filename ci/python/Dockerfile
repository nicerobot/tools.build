# python — ruff lint + format gate.
#
# ruff is the single fast tool for both linting and format-checking Python, so
# one image covers what flake8 + black + isort used to. The check only enforces
# (no rewrites); run `ruff format` / `ruff check --fix` locally to fix.
FROM python:3.13-slim

RUN pip install --no-cache-dir ruff==0.9.6

COPY --chmod=0755 check /usr/local/bin/check

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/check"]
