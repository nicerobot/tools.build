# ci/typescript

The shared JavaScript/TypeScript gate: [`biome.json`](biome.json) is baked into the image at `/etc/gomatic.biome.json`, and [`check`](check) copies it into the workspace for the duration of one run. A repository's own `biome.json` is moved aside first, so the gate always measures against the fleet ruleset rather than a local relaxation of it.

## Never put a comment in `biome.json`

Biome accepts `//` comments in a `biome.json` without complaint — and then behaves **exactly as if the file did not exist**. It emits no parse error, no warning, and no non-zero exit; the whole ruleset silently reverts to biome's defaults.

Measured against the same probe file, with `--only=security/noSecrets`:

| config                        | diagnostics |
| ----------------------------- | ----------- |
| full config, comments removed | 6           |
| full config, one comment kept | 9           |
| no config file at all         | 9           |

A commented config is indistinguishable from no config. Shipping one would have voided every rule in this file across the fleet while the gate carried on reporting a healthy-looking pass — the worst failure mode a quality gate has, since it fails **open**. Rationale that wants prose goes in this README, which cannot disable anything.

## `noSecrets` and `entropyThreshold: 45`

`noSecrets` runs two independent passes:

- **Exact patterns** — AWS keys, Slack tokens and webhooks, JWTs, Google/Twitter/Facebook OAuth tokens, Twilio keys, RSA/OpenSSH/DSA/EC/PGP private-key blocks, passwords embedded in URLs. This is the pass that actually detects a leaked credential, and `entropyThreshold` **does not affect it** — those patterns fire at any threshold.
- **Generic string entropy** — a heuristic score over every string literal.

At biome's default of `41`, the entropy pass makes a DOM-heavy codebase unlintable: `tsvsheet.web` produced 54 findings and every single one was a CSS/ARIA selector (`[role="gridcell"]`), a TSV test fixture, or the text of a test's name. Not one was a secret.

`45` is the smallest value that eliminates the selector class, and it was chosen by measurement rather than taste. A probe holding the observed false positives alongside real credentials — an AWS key, a JWT, a Slack token, a password in a URL, and a 40-character opaque token deliberately matching no known pattern — still reports every real one at `45`. The entropy pass does not stop catching them until far higher: the JWT survives to roughly `65`, the opaque token past `90`. The change buys silence on selectors at zero measured cost in detection.

The rule is a backstop either way. Credential scanning proper is GitHub secret scanning plus the commit-time ban hook, both of which see the history a linter never does; biome's own documentation makes the same recommendation.

## Rules relaxed from `preset: all`, and why

- `correctness/useImportExtensions` — its autofix appends `.js` to relative TypeScript imports, which `tsc` rejects with TS5097 under this fleet's module settings. A fix that breaks the compiler is not a fix.
- `style/noTernary` — a simple `cond ? a : b` is clearer than the `if` it expands to. Nested and compound ternaries stay banned by `style/noNestedTernary`, which is the part that actually hurts readability.
- `style/useNamingConvention` — `strictCase` off, and object/type members may be `camelCase`, `snake_case`, `PascalCase`, or `CONSTANT_CASE`. These shapes cross a wire (TSV headers, JSON payloads, CSS custom properties) where the name is data, not a local style choice.

Test files, entrypoints, config files, and `*.d.ts` carry narrower relaxations in `overrides` — each one is scoped to the file class that genuinely cannot satisfy the rule, never to a whole rule fleet-wide.
