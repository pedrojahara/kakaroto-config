---
name: build-implement
description: "Autonomous feature implementation from spec. Explores, challenges assumptions, builds until all tests pass."
context: fork
agent: build-implementer
user-invocable: false
model: opus
effort: xhigh
---

# IMPLEMENT — Build from Spec

You receive `{slug}` from `$ARGUMENTS`.

## Boundaries

- **Authority:** You may ONLY set Status to `CERTIFYING`. Never write UNDERSTOOD, DONE, or any other status.
- **Markers:** You MUST create `v4-passed` after V4+ verification passes locally (or immediately if no V4+ tests exist). NEVER create `certified` — that belongs to build-certify.
- **Autonomous:** No user interaction. Resolve ambiguities using the spec and the codebase.
- **Contract:** `spec.md` is truth. If spec and codebase conflict, follow the spec.

## Setup

1. Read `.workflow/build/{slug}/spec.md` — this is your contract
2. Read the `Complexity` field — this determines verification depth:
   - `TRIVIAL`: minimal ceremony, V1-V3 only, no anti-anchoring
   - `STANDARD`: normal implementation, V1-V3 only
   - `COMPLEX`: full implementation with anti-anchoring and V4+ if `## Verification` exists
3. If the spec has `## Implementation Plan`: read it thoroughly —
   this is your execution guide (files, code, architecture, order).
   Follow as guidance. Hard constraints are `## Acceptance Criteria` only.
4. If the spec has `## Source` containing a `.md` file path: read the original plan file in FULL.
   The plan has code snippets, parameters, architecture decisions.
   **When spec and plan conflict, plan wins** (written by user).
   When plan references code that no longer exists, trust current codebase.
   **Codebase invariant check:** if the plan directs a change that violates a convention stated in CLAUDE.md, an existing architectural pattern, or a declared constraint (security / data-integrity / cross-module API contract), do NOT silently comply. Record the conflict as a `## Concerns` bullet in `implementation-notes.md`, implement the spec's acceptance criteria using the convention-respecting approach, and surface the conflict explicitly so code-reviewer catches it in build-certify. Do NOT escalate to user at this stage — the handoff is via notes; the user sees the surfaced concern at certify time.
5. Read the project's `CLAUDE.md` — these are your constraints
6. Search memory for relevant patterns: `mcp__memory__search_nodes({ query: "patterns" })`
7. **(Skip if spec has `## Source`.)** Find an exemplar feature similar to this request — study its anatomy (types → service → handler → tests → UI) before writing any code

## Anti-Anchoring

**Skip for TRIVIAL complexity.**

- If spec has `## Source` (plan file): implement the plan directly. Anti-anchoring activates only if verify.sh fails 3 times on the same area.
- Otherwise: consider at least 3 implementation approaches before coding. Challenge your first instinct: what assumptions am I making? What breaks if I'm wrong? Use Sequential Thinking for complex decisions.

**Among viable approaches, prefer the simplest and most elegant solution.** Default to less code, fewer abstractions, and straightforward data flow.

## Build

Read `${CLAUDE_SKILL_DIR}/verify-template.md` and generate `.workflow/build/verify.sh` with V1-V3 baselines.

Freedom in HOW. Hard constraints: spec acceptance criteria, CLAUDE.md conventions, verify.sh passes.
Run `bash .workflow/build/verify.sh {slug}` frequently as feedback loop. If the same approach fails twice, reconsider via Sequential Thinking.

**Tests are mandatory.** New functionality MUST have tests — this is enforced by CLAUDE.md ("Código sem teste = PR rejeitado"). Write tests as part of implementation, not as an afterthought. Exceptions: config files, .d.ts, UI-only without logic.

**verify.sh checks V1-V3 only:** unit tests, TypeScript, build.

## V4+ Verification (enforced by Stop hook)

After V1-V3 pass, check whether V4+ tests exist in the spec:

### If spec has `## Verification` section with V4+ tests:

**Hard contract: you MUST emit `.workflow/build/{slug}/v4-runner.mjs` as a standalone Playwright script.** The same script runs locally now AND in certify.sh against production — zero divergence between environments. No MCP Playwright orchestration in this phase.

1. **Prepare fixtures.** If any V4+ step references a file path, copy the file into `.workflow/build/{slug}/fixtures/` with a stable name and update the runner to reference the relative fixture path. Never bake user-home paths (`/Users/...`) into the runner.

2. **Write the runner.** Generate `.workflow/build/{slug}/v4-runner.mjs` with:
   - `import { chromium } from 'playwright'` and run headless by default
   - `const BASE_URL = process.env.BASE_URL || 'http://localhost:3001'`
   - If spec has `Pre-condition: authenticated user via e2eLogin()`: reuse the project's auth helper. For social-medias specifically, that's `tests/e2e/helpers/auth.ts` → runner must be invoked with `npx tsx .workflow/build/{slug}/v4-runner.mjs` (rename to `.ts` if your project uses tsx) so the TS helper import resolves. The runner calls `e2eLogin(page)` after `page.goto(BASE_URL)` and before the first V4+ scenario. Reads `E2E_TEST_EMAIL` / `E2E_TEST_PASSWORD` from the process env (certify.sh loads them from `.env`).
   - One async function per V4+ scenario, named `scenarioV4()`, `scenarioV5()`, etc.
   - Each scenario implements the spec's steps verbatim, then runs the checks via `page.evaluate()` mapped to the same DSL:
     - `console: no-errors` → collect `console` events with level `error`; fail if any.
     - `url: contains "X"` → `page.evaluate(() => location.href.includes('X'))`
     - `text: visible "X"` → `page.evaluate(() => document.body.innerText.includes('X'))`
     - `text: not-visible "X"` → `page.evaluate(() => !document.body.innerText.includes('X'))`
     - `state: no-loading` → `page.evaluate(() => !document.querySelector('.spinner, .loading, [aria-busy="true"]'))`
   - Main block runs scenarios in order; exit 0 if all pass, exit 1 on any failure with a stderr trace.
   - Trace format: `[v4-runner] {scenario}: {step|check} — {PASS|FAIL: <why>}`

3. **Run the runner locally.** Ensure dev server is up on port 3001, then:
   ```bash
   BASE_URL=http://localhost:3001 node .workflow/build/{slug}/v4-runner.mjs
   ```
   If the spec has auth pre-condition, also export `E2E_TEST_EMAIL` and `E2E_TEST_PASSWORD` from `.env`. If runner exits non-zero → fix the issue, re-run. Do NOT write the marker.

4. **Create the marker** ONLY after the runner exits 0:
   ```bash
   date -u '+%Y-%m-%dT%H:%M:%SZ' > ".workflow/build/{slug}/v4-passed"
   ```

### If spec has NO `## Verification` section:

V1-V3 passing is sufficient. Do NOT emit a runner. Create the marker immediately:
```bash
date -u '+%Y-%m-%dT%H:%M:%SZ' > ".workflow/build/{slug}/v4-passed"
```

---

## Infra Discipline

**DO NOT apply infra via imperative CLI (gcloud, gsutil, aws, kubectl, firebase deploy) if a Terraform resource covers it.** Prefer editing `terraform/*.tf` and letting `deploy.sh update` apply.

If the resource is NOT under Terraform today and you need to mutate it (bucket CORS, lifecycle, IAM binding, Firestore index): do it imperatively, but ALSO:
1. Record the exact command in `implementation-notes.md` under `## Changed` with the header `**Infra change (imperative):**`
2. Flag it as a `## Concerns` bullet with the text `needs prod parity check` so `build-certify`'s drift check picks it up.

Imperative infra without a parity record is a silent drift source — the certify drift check will block the build.

## Notes

Before signaling CERTIFYING, write `.workflow/build/{slug}/implementation-notes.md`:

- **Approach:** which of the 2+ approaches was chosen and why (skip for TRIVIAL)
- **Rejected:** what was considered and discarded (skip for TRIVIAL)
- **Changed:** files list (new | modified), 1-line rationale each
- **Concerns:** low-confidence areas, debt introduced, edge cases deferred
- **Hotspots:** files/functions where reviewer should focus hardest

## Done

When `bash .workflow/build/verify.sh {slug}` passes (V1-V3) AND the `v4-passed` marker exists (V4+ local, if spec has `## Verification`): Status → `CERTIFYING`, implementation-notes.md written.

Do NOT run `verify.sh --full` here — `--full` requires the `certified` marker which is only written by `certify.sh` in the next phase. `--full` is the final audit run by build-certify.

Return ONLY: `{slug}: CERTIFYING`

**If the agent returns with Status still BUILDING** (turn budget exhaustion): read `.workflow/build/{slug}/implementation-notes.md`, then re-invoke `build-implement` — the fresh agent reads the notes as prior context.

## Handoff

Before returning, write `.workflow/build/{slug}/next-action.md` — a single line:

```
Skill("build-certify", args: "{slug}")
```
