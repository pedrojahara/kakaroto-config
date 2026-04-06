---
name: resolve
description: "Agentic bug resolution. Investigates, verifies with user, fixes, certifies quality."
disable-model-invocation: true
model: opus
allowed-tools:
  - Read
  - Edit
  - Bash
  - Glob
  - Grep
  - Skill
  - ToolSearch
  - AskUserQuestion
---

# /resolve -- Agentic Bug Resolution

Lifecycle: `INVESTIGATING -> DIAGNOSED -> VERIFIED -> FIXING -> CERTIFYING -> VERIFIED_PROD`

## Algorithm

**CONTINUITY RULE — BLOCKING REQUIREMENT:**
After each Skill() returns, your ONLY permitted action is the next tool call.
Do NOT output text. Do NOT summarize. Do NOT narrate. Call the next tool IMMEDIATELY.

```
WRONG (VIOLATION):
  Skill("resolve-investigate") returns
  "Root cause identified! Now..." ← VIOLATION
  Skill("resolve-verify")

RIGHT:
  Skill("resolve-investigate") returns
  Skill("resolve-verify")
```

0. Load deferred tools: `ToolSearch("select:AskUserQuestion", max_results: 1)`

If `$ARGUMENTS` is too vague to start, infer from recent git log, error logs, or test failures.

1. Generate slug from `$ARGUMENTS` (keyword + date, e.g., `fix-auth-2026-03-20`)

2. **RECOVERY** -- Read `.workflow/resolve/{slug}/diagnosis.md` Status:
   - `VERIFIED_PROD` -> report summary, exit
   - `FAILED` -> report failure, exit
   - `CERTIFYING` -> jump to step 7
   - `FIXING` -> jump to step 6
   - `VERIFIED` -> jump to step 5
   - `DIAGNOSED` -> jump to step 4
   - `INVESTIGATING` -> jump to step 3
   - Check for `Trivial Fix Applied: YES` -> commit, cleanup, report, exit
   - No diagnosis file -> continue to step 3

3. Skill("resolve-investigate", args: "{slug} {$ARGUMENTS}")
   Read `.workflow/resolve/{slug}/diagnosis.md`:
   - Check for `Trivial Fix Applied: YES` -> commit with `fix: {summary}`, cleanup `.workflow/resolve/{slug}/`, report, exit
   - Otherwise -> continue to step 4

4. Read diagnosis Severity and Status:
   - If STANDARD or COMPLEX -> continue to step 4.5 (verify)
   - (TRIVIAL already handled in step 3)

4.5. Skill("resolve-verify", args: "{slug}")
     Read `.workflow/resolve/{slug}/diagnosis.md` Status:
     - `VERIFIED` → proceed to step 5
     - Otherwise → re-invoke (max 1). If stuck → AskUserQuestion to escalate.

5. Edit Status -> `FIXING`
   Continue to step 6

6. Skill("resolve-fix", args: "{slug}")
   Read diagnosis Status after return:
   - If `CERTIFYING` -> commit all changes with `fix: {summary from diagnosis}`, then continue to step 7
   - If `FIXING` (turn budget exhaustion) -> re-invoke `Skill("resolve-fix", args: "{slug}")` (max 2 total)
   - If `INVESTIGATING` (circuit breaker) -> re-invoke `Skill("resolve-investigate", args: "{slug} RE-INVESTIGATE: see fix-notes.md")` (max 1). After re-investigation, go to step 4.
   - If still stuck after retries -> Status -> `FAILED`, report, exit

7. result = Skill("resolve-certify", args: "{slug}")
   If result contains "GATE" → handle per Certify Escalation below, then retry
   Read `.workflow/resolve/{slug}/diagnosis.md` Status:
   - `VERIFIED_PROD` → cleanup `.workflow/resolve/{slug}/`, report summary
   - `FAILED` → report failure analysis
   - Still CERTIFYING → re-invoke (max 1). If stuck → AskUserQuestion to escalate.

## Certify Escalation

resolve-certify runs forked and uses gate files ONLY when stuck (deploy fails 2x,
verification issues persist). This is rare — most resolves never trigger it.

If Skill("resolve-certify") returns containing "GATE":
1. Read `.workflow/resolve/{slug}/gate-pending.md`
2. Output the body (above HTML comments) as text to the user
3. Parse `GATE_QUESTION` and `GATE_OPTIONS` from the HTML comment footer
4. Call `AskUserQuestion` with the parsed question and options
5. Write response to `.workflow/resolve/{slug}/gate-response.md` via Bash:
   ```bash
   cat > ".workflow/resolve/{slug}/gate-response.md" << 'GATE_EOF'
   selected: {selected option}
   feedback: |
     {any additional text from the user}
   step: {N, from GATE_STEP comment if present}
   GATE_EOF
   ```
6. Delete `gate-pending.md`, re-invoke Skill("resolve-certify", args: "{slug}")
7. Repeat if GATE, break on terminal status (max 5 iterations)

### Cleanup

After VERIFIED_PROD or TRIVIAL: delete `.workflow/resolve/{slug}/` directory (diagnosis, fix-notes, next-action, certified marker -- all ephemeral). Also delete `.workflow/build/resolve-{slug}/` if it exists (phantom dir created by certify.sh when called with resolve prefix).

### Guardrails

- NEVER write diagnosis content yourself. Sub-skills handle all diagnosis content.
- NEVER manually advance Status past `FIXING` (only sub-skills advance to CERTIFYING/VERIFIED_PROD).
- Commit happens in the ORCHESTRATOR (step 6) after resolve-fix returns CERTIFYING, NOT inside sub-skills.
- If a sub-skill completes but Status didn't advance as expected, re-invoke same sub-skill (max 2 retries).
- Track re-investigation count. Max 1 re-investigation cycle to prevent infinite loops.
- **Empty response guard:** When ANY `AskUserQuestion` call returns an empty, blank, or whitespace-only response, it is an accidental submission. NEVER treat it as approval. Re-ask the same question immediately.
