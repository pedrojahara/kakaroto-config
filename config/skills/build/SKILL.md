---
name: build
description: "Agentic feature development. Aligns with user, builds freely, certifies quality."
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

# /build — Agentic Feature Development

Lifecycle: `DRAFTING → UNDERSTOOD → VERIFIED → BUILDING → CERTIFYING → DONE`

## Algorithm

**CONTINUITY RULE — BLOCKING REQUIREMENT:**
After each Skill() returns, your ONLY permitted action is the next tool call.
Do NOT output text. Do NOT summarize. Do NOT narrate. Call the next tool IMMEDIATELY.

```
WRONG (VIOLATION):
  Skill("build-understand") returns
  "Requirements gathered! Now designing verification..." ← VIOLATION
  Skill("build-verify")

RIGHT:
  Skill("build-understand") returns
  Skill("build-verify")
```

0. Load deferred tools: `ToolSearch("select:AskUserQuestion", max_results: 1)`

1. Generate slug from `$ARGUMENTS` (first keyword + date, e.g., `auth-2026-02-24`)

2. **RECOVERY** — Read `.workflow/build/{slug}/spec.md` Status:
   - `BUILDING` → jump to step 6
   - `CERTIFYING` → jump to step 7
   - `DONE` → inform user, exit
   - `UNDERSTOOD` → check Complexity: FULL → jump to step 4, LITE → jump to step 5
   - `VERIFIED` → jump to step 5
   - `DRAFTING` → jump to step 3
   - Otherwise (no spec / no status) → continue to step 3

3. Skill("build-understand", args: "{slug} {$ARGUMENTS}")
   Read `.workflow/build/{slug}/spec.md` Status:
   - `UNDERSTOOD` → read Complexity. FULL → step 4, LITE → step 5
   - Spec missing or Status not UNDERSTOOD → build cancelled, inform user, exit

4. Read spec Complexity:
   - **FULL** →
     Skill("build-verify", args: "{slug}")
     Read `.workflow/build/{slug}/spec.md` Status:
     - `VERIFIED` → proceed to step 5
     - Otherwise → re-invoke (max 1). If still not VERIFIED → AskUserQuestion to escalate.
   - **LITE** → continue to step 5.

5. Edit spec Status → `BUILDING`
   Skill("build-implement", args: "{slug}")
   — After return: proceed to step 6.
   If Status still BUILDING after return: re-invoke (max 2). If stuck → AskUserQuestion.

6. Read spec Status. If CERTIFYING → proceed. If BUILDING → jump to step 5 (max 2 total retries).
   result = Skill("build-certify", args: "{slug}")
   If result contains "GATE" → handle per Certify Escalation below, then retry
   Read spec Status:
   - `DONE` → exit
   - Still CERTIFYING → re-invoke (max 1). If stuck → AskUserQuestion.

7. Recovery entry for CERTIFYING. Same as step 6.

## Certify Escalation

build-certify runs forked and uses gate files ONLY when stuck (deploy fails 2x,
code-reviewer issues persist). This is rare — most builds never trigger it.

If Skill("build-certify") returns containing "GATE":
1. Read `.workflow/build/{slug}/gate-pending.md`
2. Output the body (above HTML comments) as text to the user
3. Parse `GATE_QUESTION` and `GATE_OPTIONS` from the HTML comment footer
4. Call `AskUserQuestion` with the parsed question and options
5. Write response to `.workflow/build/{slug}/gate-response.md` via Bash:
   ```bash
   cat > ".workflow/build/{slug}/gate-response.md" << 'GATE_EOF'
   selected: {selected option}
   feedback: |
     {any additional text from the user}
   step: {N, from GATE_STEP comment if present}
   GATE_EOF
   ```
6. Delete `gate-pending.md`, re-invoke Skill("build-certify", args: "{slug}")
7. Repeat if GATE, break on terminal status (max 5 iterations)

### Guardrails

- NEVER write spec content (## What, ## Acceptance Criteria, ## Edge Cases, ## Verification) yourself. Sub-skills handle all spec content.
- NEVER manually advance Status past a gate (DRAFTING→UNDERSTOOD or UNDERSTOOD→VERIFIED). Only sub-skills advance these statuses.
- **Empty response guard:** When ANY `AskUserQuestion` call returns an empty, blank, or whitespace-only response, it is an accidental submission. NEVER treat it as approval. Re-ask the same question immediately.
- If a sub-skill completes but Status didn't advance as expected, re-invoke the same sub-skill (max 2 retries). If still stuck, escalate to user via AskUserQuestion.
