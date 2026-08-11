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
- `style/useExportsLast` — the rule cannot distinguish an exported **type** from an exported value, and in TypeScript the exported interfaces are the module's contract. Every module in this fleet opens with a header comment and then that contract; enforcing exports-last would push each interface below the implementation that consumes it, which is the wrong way round for a reader. Measured on `tsvsheet.web`: seven of nine findings were `export interface`.
- `style/noExcessiveLinesPerFile` and `complexity/noExcessiveLinesPerFunction` — a line count is a weak proxy for the property actually worth gating, and this fleet already gates that property directly. The Go half gates **cognitive complexity** (`gocognit`, limit 7) and imposes no length limit of any kind; `complexity/noExcessiveCognitiveComplexity` is the TypeScript equivalent and stays on.

  This was decided by measurement, not preference. `tsvsheet.web` tripped both length rules — a 1084-line module and a 339-line `createApp` against caps of 300 and 50 — while `noExcessiveCognitiveComplexity` reported **nothing anywhere in the repository**. That rule was then confirmed live against a deliberately tangled probe function, so the silence is a real result: `createApp` is long but flat, a sequence of fifteen small closures over shared state, which is not the defect a length cap is aiming at. Splitting it to satisfy a number would have restructured an app's core for no measured gain in the thing being protected.

Test files, build scripts, entrypoints, config files, and `*.d.ts` carry narrower relaxations in `overrides` — each one is scoped to the file class that genuinely cannot satisfy the rule, never to a whole rule fleet-wide:

- **Test files** additionally relax `suspicious/useAwait`, because a test double implementing an async interface (`getFile`, `createWritable`, `write` — the File System Access API) is `async` to satisfy a _signature_, and the rule cannot see the interface being implemented. They also raise the `noSecrets` entropy threshold to 100, so synthetic fixtures stop scoring as credentials while every **pattern** detector keeps firing — an AWS key, a Slack token, or a password in a URL is still reported inside a test.
- **Build scripts** (`build.mjs`, `scripts/**`, `tools/**`) relax `noNodejsModules`, `noUnresolvedImports`, `noConsole` and `noAwaitInLoops`. Those rules exist because the fleet's TypeScript is browser code; a build script is Node by definition, reports its progress, and runs its steps in order on purpose.
- **Entry points** relax `noBarrelFile`, `noReExportAll`, `noDefaultExport` and `noMagicNumbers` — re-exporting a package's surface is what an entry point is _for_, so the rule fires on the file doing its job. The pattern set originally matched only `**/src/index.ts` and `**/src/index.tsx`, which missed two shapes the fleet actually ships: an entry point written in JavaScript, and one that sits a directory deeper because the package namespaces its source (`tsvsheet.js` declares `src/tsvsheet/index.js` as both `main` and `exports["."]`). Both now match, in `.ts`/`.tsx`/`.js`/`.mjs`, at `src/index.*` and at `src/**/index.*`. Measured against the fleet: this silenced exactly the barrel finding on declared entry points and changed no other count in any of the 23 repositories carrying a TypeScript or Node gate.
- **Declaration files** (`*.d.ts`) additionally relax `noExcessiveClassesPerFile`. A `.d.ts` describes a package's whole public type surface in one file by construction, so a per-file class count measures the size of the API rather than the cohesion of a module — the property the rule exists to protect is not the one being counted.
