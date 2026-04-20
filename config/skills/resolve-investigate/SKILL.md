---
name: resolve-investigate
description: "Bug investigator. Signal-driven triage, cheapest path first, escalation on failure."
user-invocable: false
model: opus
context: fork
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - ToolSearch
---

# INVESTIGATE -- Signal-Driven Diagnosis

Parse `{slug}` (first token) and `{bug description}` (rest) from `$ARGUMENTS`.

**Keyword matching rule (applies globally to all signals and pattern matching):**

- **Case-insensitive**
- **Accent-insensitive**: `usuários` matches `usuarios`, `produção` matches `producao`, `não` matches `nao`. Normalize both the keyword and bug text via diacritic stripping (NFD + remove combining marks) before comparison.
- **Exact-word match only (NO prefix extension)**: each keyword matches as a complete word or complete contiguous phrase. `prod` matches the word `prod` only — NOT `production`, NOT `product`. If multiple variants should match (e.g., `prod` AND `production`), list them **as separate keywords** in the signal definition.
- **Multi-word keywords** must appear contiguously as a phrase (e.g., `race condition` matches `race condition` but not `race ... condition`).
- **Word boundaries**: a "word" starts/ends at whitespace, punctuation, or string boundary. `prod` inside `production` does NOT match because there's no boundary between `prod` and `uction`.
- **Identifier normalization**: hyphens in identifiers (`social-api`) are normalized to underscores (`social_api`) on BOTH sides (signal name generation AND `requires-signals` lookup) to avoid mismatches.

**Glob dialect (for scope.txt and Test Dirs):** fnmatch-style. `*` (not crossing `/`), `**` (recursive), `?` (single char). NO character classes (`[a-z]`), NO extglob (`+(...)`, `@(...)`). Keep patterns simple.

## Boundaries

- **Authority:** You may ONLY set Status to `DIAGNOSED`. Never write FIXING, VERIFIED, CERTIFYING, or FAILED.
- **Scope:** You may Write `diagnosis.md`, `scope.txt`, `next-action.md`, `gate-pending.md`, and new test files. NEVER Edit production code except via Phase B Trivial Escape Hatch.
- **Lazy tools:** sequential-thinking, memory, Playwright, context7 are NOT in default allowed-tools. Load via `ToolSearch` only in Phase D.
- **No direct user dialogue:** you run in forked context. For user input, use the **gate pattern** (write `gate-pending.md`, return `{slug}: GATE`). The orchestrator handles `AskUserQuestion` and re-invokes you with the response.

---

## Phase A -- Signal Extraction (ALWAYS, ~30s)

Goal: classify cheaply from observable features. Write `.workflow/resolve/{slug}/scope.txt`. Keep signals in working memory.

### A.1 -- Read inputs (one pass)

1. Read the project's `CLAUDE.md` from the current working directory
2. Parse `{slug}` and `{bug description}` from `$ARGUMENTS`
3. If `$ARGUMENTS` contains the marker `PHASE_D:` → skip directly to Phase D. If `fix-notes.md` exists, read it first.
4. **Gate continuation dispatch:** if `.workflow/resolve/{slug}/gate-response.md` exists:
   - Read it, delete it, parse `selected:`, `feedback:`, `step:` fields
   - **Switch on `step:`**:
     - `step: vague` → resume at A.7 with the selected option
     - `step: strike-3` → resume at C.5 strike-3 handling with the selected option
     - `step: by-design` → resume at D.5.5 with the selected option
     - _Any other value_ → log warning ("unknown gate step: {step}"), fall through to full Phase A re-extraction
   - After resume handling, continue the normal phase flow

### A.2 -- Extract universal signals

Scan the bug description against this table. Signals are deterministic keyword/regex matches, NOT LLM judgment.

| Signal                   | Detection rule                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | Effect                                                                                                                                                                                                                                                                                                                                                            |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `stack_trace`            | Regex `[\w/.-]+\.(ts\|tsx\|js\|jsx\|py\|go\|rs\|java\|rb)(:\d+\|,?\s*line\s+\d+)` — captures `file.ts:42`, `File "foo.py", line 42`, `file.rb:42:in`. **If multiple matches, select the first one that does NOT start with `node_modules/`, `node:internal/`, or `/usr/`.**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Pre-fill hotspot; skip repro design                                                                                                                                                                                                                                                                                                                               |
| `error_literal`          | **Detect in order, stop at first hit**: (1) **double-quoted** `"..."` OR **backtick** `` `...` `` with inner content >= 8 chars (excluding quote chars); (2) **single-quoted** `'...'` with inner content >= 8 chars AND preceded by `=`, `:`, space after `(`, or line start (avoids accidental spans across apostrophes like `Can't`); (3) text after `Error:` / `Erro:` / `Exception:` / `panic[:\s]` up to newline or period; (4) uppercase constants matching `[A-Z]+_[A-Z0-9_]+` **(must contain at least one underscore)** — e.g., `INVALID_ARGUMENT` ✓, `REQUEST` ✗                                                                                                                                                                                                             | Pre-load `grep -rn "{literal}"` as first investigation action                                                                                                                                                                                                                                                                                                     |
| `likely_single_line_fix` | Keywords (PT+EN, narrow): `typo`, `errado`, `renomear`, `trocar`, `rename`, `missing import`, `off by one`, `off-by-one`, `wrong variable`, `wrong constant`, `wrong key`, OR compile/runtime patterns: `Type '.*' is not assignable`, `Cannot find`, `Property '.*' does not exist`, `Expected \d+ arguments`, `Cannot read propert(y\|ies)`, `is not a function`, `is not defined`, `undefined is not an object`, `KeyError`, `IndexError`, `AttributeError`, `NameError`, `ValueError`, `TypeError`, `RangeError`, `ReferenceError`, `SyntaxError`. **Must combine with `stack_trace` to count.**                                                                                                                                                                                    | Enables Phase B                                                                                                                                                                                                                                                                                                                                                   |
| `browser_visual`         | Keywords: `visual`, `css`, `layout`, `hover`, `scroll`, `overflow`, `z-index`, `responsive`, `tela`, `aparece`, `botão`, `button`, `click`, `onclick`, `não faz nada`, `modal`, `dropdown`, `popup`, `mobile layout`, `mobile css`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | Force Phase D + Playwright                                                                                                                                                                                                                                                                                                                                        |
| `prod_only`              | Keywords (exact-word): `production`, `produção`, `prod`, `em produção`, `em producao`, `só em prod`, `funciona local`, `local funciona`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | Force prod log check (command from CLAUDE.md `## Deploy`)                                                                                                                                                                                                                                                                                                         |
| `intermittent`           | Keywords: `às vezes`, `de vez em quando`, `intermitente`, `1 em cada`, `uma em cada`, `não consigo reproduzir`, `flaky`, `sometimes`, `random`, `race condition`, `alguns usuários`, `some users`, `nem sempre`, `not always`, `only for some`, `só pra alguns`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | See A.6 routing (Phase D only if NO `stack_trace`)                                                                                                                                                                                                                                                                                                                |
| `likely_not_code`        | `stack_trace == false` AND keywords: `deploy`, `redeploy`, `env var`, `secret`, `rotate`, `rotacionar`, `token expirado`, `terraform`, `gcloud`, `cloud run`, `firebase config`, `firestore.rules`, `indices`, `rebuild`, `bundle`, `credenciais`, `workflow`, `github actions`, `ci pipeline`, `.yml`, `.yaml`, `.toml`, `.tf`, `.rules`                                                                                                                                                                                                                                                                                                                                                                                                                                               | Route to Phase C **investigation-only** (no RED test), force `Fix Type != code`                                                                                                                                                                                                                                                                                   |
| `vague`                  | `stack_trace == false` AND `error_literal == false` AND **no `file:line` pattern anywhere** AND fewer than 5 significant words (excluding stop words: `o, a, de, em, the, a, is, in, of, to, at`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | See A.6 routing (Vague Gate only if no other signal fires)                                                                                                                                                                                                                                                                                                        |
| `regression_hint`        | Keywords: `desde`, `depois do`, `after commit`, `ontem`, `hoje`, `yesterday`, `this morning`, `agora pouco`, `just now`, `earlier today`, OR unvalidated SHA pattern `\b[0-9a-f]{7,40}\b`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | Load `git log --since="2 days ago" --oneline` as lightweight context in Phase C.2                                                                                                                                                                                                                                                                                 |
| `regression_sha`         | SHA candidate from `regression_hint` AND **validated via `git cat-file -e {sha}`** (exit == 0)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | Trigger A.4 full git context load (git show + diff + scope widening)                                                                                                                                                                                                                                                                                              |
| `user_provided_repro`    | Numbered steps (`1.`, `2.`, `3.`) OR phrases "passos para reproduzir" / "steps to reproduce"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | Skip repro design; copy steps verbatim into QA flow                                                                                                                                                                                                                                                                                                               |
| `phase_d_resume`         | `$ARGUMENTS` contains `PHASE_D:` marker                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | Skip A/B/C, go to Phase D, read `fix-notes.md` first                                                                                                                                                                                                                                                                                                              |
| `feature_request`        | `stack_trace == false` AND `error_literal == false` AND any of these REQUEST phrases present (multi-word, exact contiguous phrase, case/accent-insensitive): `quero um`, `quero uma`, `quero adicionar`, `quero criar`, `quero implementar`, `queria um`, `queria uma`, `queria adicionar`, `gostaria de adicionar`, `gostaria que tivesse`, `gostaria de ter`, `gostaria que ordenasse`, `seria bom ter`, `poderia ter`, `preciso de uma`, `preciso de um`, `nova feature`, `nova página`, `nova tela`, `novo botão`, `nova funcionalidade`, `I want a`, `I want an`, `I want to add`, `I would like to`, `I'd like to add`, `would like a`, `would like an`, `should also have`, `add a new`, `add an option`, `implement a`, `create a new`, `new feature`, `new button`, `new page` | Route to REDIRECT (A.6 rule 0). Single words like `quero` / `queria` are excluded (appear in bug reports). The indefinite-article pairs (`quero um`, `I want a`) are deliberately included: false-negative (phantom fix of a nonexistent feature committed as `fix:`) is far worse than false-positive (a real bug reaching `/build`, which will bounce it back). |

### A.3 -- Parse project-specific `## Resolve Patterns` section

1. Grep project CLAUDE.md for `## Resolve Patterns` (case-insensitive)
2. If present, parse four optional subsections:

**Domain Signals** (format: `- **{name}** — keywords: "..." → scope: {paths}`):

- For each entry, if any keyword appears in bug text, set `domain_{normalized_name}=true` and add scope paths.
- **Normalization:** lowercase, hyphens → underscores. E.g., `social-api` → `domain_social_api`, `Graph-API` → `domain_graph_api`.
- When evaluating archetype `requires-signals`, apply the same normalization to the lookup key. E.g., `requires-signals: domain_social-api` is normalized to `domain_social_api` before lookup.

**Bug Archetypes** (structured format, NOT a DSL):

```
- **{id}**
  - requires-signals: signal1, signal2
  - requires-error: "literal1" | "literal2"   (optional)
  - hypotheses:
    - (a) ...
    - (b) ...
```

Parse rule: archetype matches if ALL `requires-signals` are true AND (if `requires-error` present) **the bug text contains at least one of the listed literals** (case-insensitive substring — matched against raw bug text, NOT dependent on extracted `error_literal` signal). Archetypes are evaluated **in document order**; first matches come first in `archetype_matches`.

**Test Commands** (optional, format: `- {name}: \`command\``):

- `test`, `typecheck`, `dev-server`. These override auto-detection in Phase B/C.
- **Port extraction for dev-server:** parse trailing `(port N)` annotation — e.g., `dev-server: npm run dev (port 3001)` → `dev_port = 3001`. Default: 3000.

**Test Dirs** (optional, format: `- glob: {pattern}` or `- dir: {path}`):

- **If present, REPLACES defaults** (`**/*.test.*`, `**/*.spec.*`, `tests/`, `__tests__/`). Do not append.

If `## Resolve Patterns` absent: proceed with universal signals only (graceful degradation).

### A.4 -- Git context auto-load

If `regression_sha == true`:

1. Run `git show {sha} --stat --name-only`
2. Run `git diff {sha}^..{sha} --name-only`
3. Count files in the diff.
4. If > 10 files: add only the **first 10** to scope, set `scope_truncated = true` in working memory (becomes a `Concerns:` entry in diagnosis).
5. Otherwise: add all diff files to scope.

If `regression_hint == true` (even without validated SHA): in Phase C.2, run `git log --since="2 days ago" --oneline` and include output in investigation context. No scope widening.

### A.5 -- Write scope.txt

Write `.workflow/resolve/{slug}/scope.txt`. The content depends on whether CLAUDE.md has a `Test Dirs` section:

```
# scope.txt — resolve/{slug}
# Written by resolve-investigate Phase A.
# resolve-fix enforces this scope via gate prompt — Edits outside scope require user approval.
# Write of NEW files is exempt. Freelance strikes (Phase C #2-3) may widen this.

allow-dir: <path from pattern match or domain>
allow-file: <file from stack trace>

# Test paths — project CLAUDE.md Test Dirs REPLACE these defaults if present:
allow-glob: **/*.test.*
allow-glob: **/*.spec.*
allow-dir: tests/
allow-dir: __tests__/
```

If `Test Dirs` section exists in CLAUDE.md, replace the four default lines with the project-declared entries.

Parser rule for downstream skills: lines starting with `#` are comments, blank lines ignored, `allow-dir:` / `allow-file:` / `allow-glob:` are the three recognized directives.

### A.6 -- Decide next phase

**Evaluate in order, first match wins.** This order handles signal conflicts explicitly:

0. `feature_request == true` → **REDIRECT**: write LITE diagnosis with `Severity: REDIRECT`, `Fix Type: manual`, `Outcome: redirect`, `Committed: no`, `Status: DIAGNOSED`. The ## Suggested Fix section must explain why this is a feature, not a bug. Return `{slug}: REDIRECT` — orchestrator routes to `/build`.
1. `phase_d_resume == true` → Phase D
2. `browser_visual == true` → Phase D (always — visual bugs need Playwright)
3. `likely_not_code == true` → Phase C **investigation-only mode** (evaluated before intermittent: infra/config bugs with `flaky`/`às vezes` keywords are still infra, not race conditions)
4. `intermittent == true` AND `stack_trace == false` → Phase D (pure intermittent needs deep investigation; if user gave us a file, Phase C can use it as a hint instead)
5. `vague == true` AND **no `domain_*` signal matched** AND `intermittent == false` AND `browser_visual == false` → Vague Gate (A.7)
6. `likely_single_line_fix == true` AND `stack_trace == true` AND `intermittent == false` → Phase B (intermittent excludes Phase B because single-run tests can't prove fix)
7. Otherwise → Phase C normal mode

**Rationale for excluded fall-throughs:**

- Intermittent + stack_trace → Phase C normal (use intermittent as hypothesis hint, mark reproduction test as POSSIBLY-UNTESTABLE in C.3)
- Vague + domain match → Phase C normal (use domain as hypothesis seed)
- Feature-request + stack_trace (odd combination — user pastes a trace while asking for enhancement) → A.2 guard blocks `feature_request` from firing, so this falls through normally.

### A.7 -- Vague Gate (via gate pattern)

Bug is too vague to investigate. Write `.workflow/resolve/{slug}/gate-pending.md`:

```markdown
Bug report is too vague to investigate efficiently. What would help?

<!-- GATE_QUESTION: Bug too vague. How should I proceed? -->
<!-- GATE_OPTIONS: Provide details | Run health check | Cancel -->
<!-- GATE_STEP: vague -->
```

Return `{slug}: GATE`.

On gate-response (re-invocation via A.1 step 4):

- `selected: Provide details` → parse new details from `feedback:` field, combine with original bug text, re-extract signals from A.2 onward, continue to A.6 routing
- `selected: Run health check` → execute health check subroutine (below), write second `gate-pending.md` with findings + options `Provide details now | Cancel`, return `GATE` again
- `selected: Cancel` → write minimal LITE diagnosis with `Severity: VAGUE`, `Outcome: cancelled`, `Committed: no`, Status `DIAGNOSED`. Return `{slug}: INSTRUCTIONS`.

**Health Check Subroutine:**

1. Extract `dev_port` from CLAUDE.md Test Commands (A.3 parsing), default 3000
2. Check if dev server already reachable: `curl -s -o /dev/null -w "%{http_code}" http://localhost:{dev_port}/ || echo "000"` — if `200`-`499`, server is up; skip start
3. Run `{test_commands.test}` (or file-presence auto-detect from Phase B.2)
4. Run `{test_commands.typecheck}` (or `npx tsc --noEmit` if `tsconfig.json` exists)
5. If dev server not already up: start in background with PID tracking: `{test_commands.dev-server} > /tmp/resolve-{slug}-dev.log 2>&1 & echo $! > /tmp/resolve-{slug}-dev.pid`. Wait up to 15s polling curl. Always `kill $(cat /tmp/resolve-{slug}-dev.pid) 2>/dev/null; rm -f /tmp/resolve-{slug}-dev.pid` at end regardless of outcome.
6. Report findings in the next gate-pending.md body

---

## Phase B -- Trivial Escape Hatch (~90s)

**Entry condition:** `likely_single_line_fix == true` AND `stack_trace == true` AND `intermittent == false`.

### B.0 -- Safety check (skip Phase B if unsafe)

Before doing anything, check the target file has no uncommitted changes:

```bash
git diff --quiet -- {file} && git diff --cached --quiet -- {file}
```

- **Exit 0** (file clean) → proceed to B.1
- **Exit non-zero** (file has unstaged or staged changes) → **skip Phase B entirely**, fall through to Phase C normal mode. Log reason: "Phase B skipped: {file} has uncommitted changes (safety check — won't stash user's work)."

### B.1 -- Targeted read

1. Read the exact `file:line` from the stack trace
2. Confirm the one-liner change matches the bug description

### B.2 -- Write regression test, apply Edit with git-stash safety net

3. **Detect test command by file presence (in order)** — done BEFORE writing the test, so we can also skip Phase B if no runner exists:
   - If `test_commands.test` set in CLAUDE.md → use that
   - Else if `package.json` exists → `npm test -- --run`
   - Else if `pyproject.toml` or `setup.py` exists → `pytest`
   - Else if `Cargo.toml` exists → `cargo test`
   - Else if `go.mod` exists → `go test ./...`
   - Else if `deno.json` or `deno.jsonc` exists → `deno test`
   - Else if `Gemfile` exists → `bundle exec rspec`
   - Else if `pom.xml` exists → `mvn test`
   - Else → **skip Phase B** (no test command detectable), fall through to Phase C
4. **Write regression test** reproducing the one-liner bug. Place per project convention (Test Dirs from CLAUDE.md or JS defaults). Keep it minimal — a single assertion that fails with current code and passes after the fix. Append test path to `written_tests[]` in working memory (same mechanism as C.3). Run the test and confirm it is **RED for the predicted reason** (quote the failure output). If the test cannot be made RED with current code, **skip Phase B**, `rm -f` the test, fall through to Phase C.
5. `git stash push -u -m "phase-b-{slug}" -- {file}` (atomic backup — safe because B.0 verified file was clean). The regression test is NOT stashed (it stays on disk as new file).
6. Apply the minimal Edit (single Edit call, one line changed)
7. Run the detected test command (must include the new regression test — should now pass)
8. Run typecheck if applicable: `test_commands.typecheck` OR auto-detect (`npx tsc --noEmit` if `tsconfig.json` exists)

### B.3 -- Verify

- **Both pass (tests including new regression test + typecheck):** `git stash drop` (discard backup). The regression test stays — it gets committed together with the fix by the orchestrator. Write LITE diagnosis with `Severity: TRIVIAL`, `Fix Type: code`, `Outcome: fixed`, `Committed: no`, Status `DIAGNOSED`. Populate `## Reproduction Test` section with the test path and `Status: GREEN (was RED before fix)`. Return `{slug}: TRIVIAL`.
- **Either fails:** `git stash pop` (restore original atomically). `rm -f` the regression test and pop it from `written_tests[]` — it was speculative and the fix did not hold. Fall through to Phase C normal mode.

No Playwright, no memory, no sequential-thinking in Phase B.

---

## Phase C -- Single-Hypothesis Targeted (~3-6 min)

**Entry condition:** Phase A routed here, OR Phase B fell through.

**Mode selection:**

- **investigation-only mode** if `likely_not_code == true`: skip C.3 (no RED test). Always classify Fix Type as non-code in C.6. Return `INSTRUCTIONS`.
- **normal mode** otherwise: full flow including RED test.

**Written Test Tracking:** maintain `written_tests[]` list in working memory. Append any test file created in C.3. Used for cleanup on abort.

### C.1 -- Hypothesis seed

- If `archetype_matches` has entries: pick the first (document order) archetype's first hypothesis as strike #1.
- If zero archetypes matched: generate a single hypothesis from signals + bug text.
- **If `intermittent == true` + `stack_trace == true`:** seed hypothesis with "race condition or state-leak in {file}:{line}" and note: "RED test may be UNTESTABLE — intermittent bugs don't fail deterministically."

### C.2 -- Targeted investigation

- Read files within `scope.txt` (strike #1 is scope-bounded)
- Grep for `error_literal` if present
- If `prod_only` AND project has log command in CLAUDE.md `## Deploy`: run it ONCE
- If `regression_sha`: consult the full diff loaded in A.4
- If `regression_hint` (without sha): run `git log --since="2 days ago" --oneline` and consult output

### C.3 -- Write RED test (normal mode only; SKIP in investigation-only mode)

1. **Before writing:** if `written_tests[]` has a test from the previous strike, `rm -f` that file and pop it from the list. Only the current strike's test should exist on disk at any time.
2. Write a test encoding expected behavior for the current hypothesis
3. **Track:** append test path to `written_tests[]` in working memory (single-entry at any time after step 1)
4. Place per project convention (Test Dirs from CLAUDE.md or JS defaults)
5. Run detected test command scoped to new file
6. Confirm RED. If `intermittent` hint is set and test goes GREEN once, run 5 more times; if still GREEN, mark as `Reproduction Test: UNTESTABLE — intermittent, could not reliably fail`.

**Invariant:** at any moment, `written_tests[]` contains at most ONE file — the test for the currently-active hypothesis. When C.4 confirms root cause (RED for predicted reason), that test becomes the reproduction test (do NOT delete). When C.5 strike fires (hypothesis falsified), step 1 of the next C.3 call removes it.

### C.4 -- Decision

**Evidence requirement (applies to both modes):** "predicted reason" and "root cause confirmed" must be backed by concrete test output or code reference. Quote the actual error message or file:line in the diagnosis. Never claim a root cause from pattern-matching alone — this is the Opus 4.7 hallucination mitigation.

**Normal mode:**

- RED for predicted reason → root cause confirmed. Record the exact error output in the diagnosis `## Root Cause` section as evidence. Go to C.6 → write diagnosis.
- RED for different reason → strike +1, update hypothesis. Record the actual error output (not the predicted one) in working memory for the next iteration.
- GREEN (expected RED) → strike +1, hypothesis wrong.
- Inconclusive (env error) → NOT a strike. Fix environment, retry.

**Investigation-only mode:**

- Read files, identify root cause through reading only (no RED test).
- Once identified → go directly to C.6 → write diagnosis with instructions. The `## Root Cause` must cite the specific file:line(s) that demonstrate the cause.
- If unable to identify after reading scope + any memory/logs: strike +1 (freelance from C.5).

### C.5 -- Strike progression

| Strike          | Behavior                                                                                                                                                                      |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| #1              | Hypothesis from first archetype match, scope-bounded (within `scope.txt`)                                                                                                     |
| #2              | **FREELANCE + scope-widening:** may Read files OUTSIDE `scope.txt`. If a new file yields a promising hypothesis, append `allow-file: {path}` to `scope.txt` before strike #3. |
| #3              | **FREELANCE + scope-widening** (with evidence from #2)                                                                                                                        |
| After strike #3 | **Strike #3 Gate** via gate pattern                                                                                                                                           |

**Definition of strike:** hypothesis **tested and falsified**. Environment errors, missing deps, inconclusive reads are NOT strikes.

**Strike #3 Gate** — write `gate-pending.md`:

```markdown
3 hypotheses falsified for bug: {one-line summary}
Evidence collected:
{short summary of what was tried}

<!-- GATE_QUESTION: 3 hypotheses falsified. How should I proceed? -->
<!-- GATE_OPTIONS: Escalate to Phase D | Abort as ambiguous -->
<!-- GATE_STEP: strike-3 -->
```

Return `{slug}: GATE`.

On gate-response (dispatched by A.1 step 4):

- `selected: Escalate to Phase D` → call Phase D.
- `selected: Abort as ambiguous` → **cleanup**: iterate `written_tests[]` and `rm -f` each test file. Then write LITE diagnosis with `Severity: VAGUE`, `Outcome: cancelled`, `Committed: no`, Status `DIAGNOSED`. Return `{slug}: INSTRUCTIONS`.

**Note:** "Accept current best guess" option was deliberately removed. Shipping weak hypotheses to resolve-fix is a footgun.

### C.6 -- Fix Type classification

Before writing diagnosis, classify:

- **code** (default) → resolve-fix will Edit source files → return `DIAGNOSED`
- **infra** → Terraform/GCP/Docker/CI action → return `INSTRUCTIONS`
- **config** → config file outside production source → return `INSTRUCTIONS`
- **manual** → human action → return `INSTRUCTIONS`

If investigation-only mode was used (`likely_not_code == true`), Fix Type MUST be non-code.

Write LITE diagnosis:

- `Outcome: fixed` ONLY in Phase B (code fix applied)
- `Outcome: diagnosed` for normal Phase C with `Fix Type: code`
- `Outcome: instructions` for any Fix Type != code
- `Committed: no` (orchestrator commits on flow completion)

Return accordingly: `{slug}: DIAGNOSED` or `{slug}: INSTRUCTIONS`.

---

## Phase D -- Deep Investigation (escalation only, ~15-20 min)

**Entry conditions:**

- Auto via A.6: `browser_visual`, pure `intermittent`, `phase_d_resume`
- Via gate: strike #3 gate resolved with "Escalate to Phase D"

### D.1 -- Lazy-load MCP tools

```
ToolSearch("select:mcp__sequential-thinking__sequentialthinking,mcp__memory__search_nodes", max_results: 10)
```

If `browser_visual == true`:

```
ToolSearch("select:mcp__playwright__browser_navigate,mcp__playwright__browser_snapshot,mcp__playwright__browser_click,mcp__playwright__browser_fill_form,mcp__playwright__browser_type,mcp__playwright__browser_wait_for,mcp__playwright__browser_console_messages,mcp__playwright__browser_close,mcp__playwright__browser_take_screenshot,mcp__playwright__browser_press_key,mcp__playwright__browser_evaluate,mcp__playwright__browser_network_requests", max_results: 15)
```

### D.2 -- Read prior context

If `phase_d_resume == true`: read `.workflow/resolve/{slug}/fix-notes.md` first.

### D.3 -- Sequential thinking scaffold

Use `sequentialthinking` (if lazy-loaded) OR inline 4-thought scaffold in your reasoning:

- **Thought 1 (SYMPTOMS):** What is the bug? Expected vs actual. Evidence so far.
- **Thought 2 (HYPOTHESES):** Generate 3+ structurally different hypotheses.
- **Thought 3 (TARGETING):** Which is cheapest to disprove? Execute.
- **Thought 4 (REVISION):** Am I anchored? What would change my mind?

**Guideline, not hard requirement.** Stop early if root cause emerges.

**Evidence requirement (Hypotheses table):** each of the 3+ hypotheses must cite concrete evidence in `Evidence For` / `Evidence Against` columns — quote the actual error message, file:line, console output, or DOM state from D.5. Never populate from pattern-matching alone. A hypothesis with no observable evidence is a guess — drop it and generate another. This is the Phase D analogue of the C.4 evidence requirement.

### D.4 -- Memory search (if relevant)

If `domain_*` signal matched AND `mcp__memory__search_nodes` loaded:

```
mcp__memory__search_nodes({ query: "{domain_name}" })
```

### D.5 -- Browser reproduction (if needed)

If `browser_visual == true`:

1. Extract `dev_port` (A.3 parsing, default 3000)
2. Check if dev server already reachable via `curl -s -o /dev/null -w "%{http_code}" http://localhost:{dev_port}/`
3. If not: start in background with PID tracking (`> /tmp/resolve-{slug}-dev.log 2>&1 & echo $! > /tmp/resolve-{slug}-dev.pid`), wait for port, always kill on exit
4. Use Playwright MCP to reproduce
5. Capture console, screenshots, DOM state

### D.5.5 -- By-design check (only if browser_visual reproduction succeeded)

Some "bugs" are actually correct product behavior the user dislikes (ESC closes modal, Enter submits form, scroll hides header on mobile). Without this gate, Phase D.3 invents hypotheses and resolve-fix alters working code — phantom fixes. Reuses the existing gate pattern (vague A.7, strike-3 C.5).

**Heuristic trigger (deterministic, conservative):** set `by_design_candidate = true` if D.5 reproduced the behavior AND the bug description contains any of these phrases (case/accent-insensitive, exact contiguous phrase):

- PT: `fecha muito rápido`, `fecha muito rapido`, `fecha ao apertar`, `fecha quando aperto`, `some muito rápido`, `desaparece ao scrollar`, `muda ao scrollar`, `submete ao apertar enter`
- EN: `closes on esc`, `closes on escape`, `closes too fast`, `closes when I press`, `submits on enter`, `hides on scroll`, `disappears on scroll`

Extend the list as new cases emerge. If no phrase matches → fall through to D.6 normally (current behavior preserved).

If `by_design_candidate == true`, write `.workflow/resolve/{slug}/gate-pending.md`:

```markdown
The reported behavior reproduces in D.5, but it matches a standard UX pattern.

Reproduced: {one-line from D.5}
Why this may be by-design: {brief — e.g., "ESC closing modals is WCAG-recommended behavior"}

<!-- GATE_QUESTION: Reproduced behavior looks by-design. Treat as? -->
<!-- GATE_OPTIONS: By-design — cancel | Real bug — continue investigation -->
<!-- GATE_STEP: by-design -->
```

Return `{slug}: GATE`.

On gate-response (dispatched by A.1 step 4):

- `selected: By-design — cancel` → write LITE diagnosis with `Severity: VAGUE`, `Fix Type: manual`, `Outcome: cancelled`, `Committed: no`, `Status: DIAGNOSED`. The `## Suggested Fix` section explains the behavior is intentional and points the user to `/build` if they want to change it. Return `{slug}: INSTRUCTIONS`.
- `selected: Real bug — continue investigation` → fall through to D.6 normally (D.3 hypotheses still available).

### D.6 -- Write FULL diagnosis

Use FULL section of `diagnosis-template.md`.

Classify Fix Type (C.6 rules). Return `{slug}: DIAGNOSED` or `{slug}: INSTRUCTIONS`.

---

## Output

Return ONE of:

- `{slug}: TRIVIAL` — Phase B escape hatch succeeded
- `{slug}: DIAGNOSED` — normal flow, `Fix Type: code` (verify/fix/certify will run)
- `{slug}: INSTRUCTIONS` — `Fix Type != code`, OR vague cancelled, OR strike-3 abort
- `{slug}: REDIRECT` — request is a feature, not a bug; orchestrator routes to `/build`
- `{slug}: GATE` — gate pattern raised (vague, strike-3), orchestrator handles

## Handoff

Before returning (except GATE), write `.workflow/resolve/{slug}/next-action.md`:

- **TRIVIAL** → `TRIVIAL_COMPLETE`
- **INSTRUCTIONS** → `INSTRUCTIONS_ONLY`
- **DIAGNOSED** → `Skill("resolve-fix", args: "{slug}")`
- **REDIRECT** → `Skill("build", args: "{original $ARGUMENTS}")`

For **GATE**: do NOT write next-action.md (orchestrator handles re-invocation).

---

## Notes

- **Single Read of CLAUDE.md.** Phase A reads once. Keep parsed data in working memory through Phase B/C/D.
- **Lazy tool loading.** Never load Playwright/sequential-thinking unless Phase D.
- **Scope.txt widening.** Freelance strikes #2-3 may append `allow-file:` when new files yield hypotheses.
- **Strikes are about hypotheses, not attempts.** Same structural idea tested 5 ways = 1 strike.
- **Gate pattern unifies user dialogue.** Vague, Strike-3, Scope Lock → all via `gate-pending.md` + `GATE` return.
- **Cleanup on abort.** `written_tests[]` tracks test files; remove on strike-3 abort.
- **Phase B safety.** Skips entirely if target file has uncommitted user changes (no risk of data loss).
- **Signal routing is hierarchical.** A.6 evaluates in order; signal conflicts resolved deterministically.
