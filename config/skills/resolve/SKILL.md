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

2. **RECOVERY** -- Read `.workflow/resolve/{slug}/diagnosis.md`. Check `Outcome` tag FIRST (then Status):

   **Outcome/Status integrity check (guardrail):** before acting on `Outcome`, verify Status is consistent. If mismatch, abort with error.
   - `Outcome: fixed` requires `Status: DIAGNOSED`
   - `Outcome: instructions` requires `Status: DIAGNOSED`
   - `Outcome: cancelled` requires `Status: DIAGNOSED`
   - `Outcome: diagnosed` requires `Status: DIAGNOSED` or `VERIFIED` or `FIXING` or `CERTIFYING` or `VERIFIED_PROD`
   - Inconsistent state → report "Outcome/Status mismatch: Outcome={X}, Status={Y}. Refusing to act." and exit without modifying anything.

   Then dispatch:
   - `Outcome: fixed` AND `Committed: no` -> commit, set `Committed: yes`, cleanup, report, exit
   - `Outcome: fixed` AND `Committed: yes` -> already done, cleanup, report, exit
   - `Outcome: instructions` -> report suggested fix instructions to user, cleanup, exit (no commit/verify/fix/certify)
   - `Outcome: cancelled` -> report vague-cancelled, cleanup, exit (no commit)
   - Else by Status:
     - `VERIFIED_PROD` -> report summary, exit
     - `FAILED` -> report failure, exit
     - `CERTIFYING` -> jump to step 7
     - `FIXING` -> jump to step 6
     - `VERIFIED` -> jump to step 5
     - `DIAGNOSED` -> jump to step 4
     - `INVESTIGATING` -> jump to step 3
   - No diagnosis file -> continue to step 3

3. `result = Skill("resolve-investigate", args: "{slug} {$ARGUMENTS}")`

   **Defense in depth — check return value first:**
   - If `result` contains `GATE` -> handle per Gate Escalation below, then re-invoke investigate (max 5 gate loops)
   - If `result` contains `TRIVIAL` -> read diagnosis.md, verify `Outcome: fixed`, commit with `fix: {summary}`, set `Committed: yes`, cleanup, report, exit
   - If `result` contains `INSTRUCTIONS` -> read diagnosis.md `## Suggested Fix` section, report instructions to user verbatim, cleanup, exit (no commit)
   - If `result` contains `DIAGNOSED` -> continue to step 4

4. Read diagnosis `Severity` and `Fix Type`:
   - If `Severity: VAGUE` -> report vague-cancelled, cleanup, exit (edge case: should have been caught by Outcome check)
   - If `Fix Type != code` -> already handled as INSTRUCTIONS above, should not reach here
   - Otherwise (STANDARD or COMPLEX with `Fix Type: code`) -> continue to step 4.5

4.5. `result = Skill("resolve-verify", args: "{slug}")`
If `result` contains `GATE` -> handle per Gate Escalation, re-invoke (max 5)
Read `.workflow/resolve/{slug}/diagnosis.md` Status: - `VERIFIED` -> proceed to step 5 - Otherwise -> re-invoke (max 1). If stuck -> `AskUserQuestion` to escalate.

5. Edit Status -> `FIXING`. Continue to step 6.

6. `result = Skill("resolve-fix", args: "{slug}")`

   **Check return value first:**
   - If `result` contains `GATE` (scope lock) -> handle per Gate Escalation, re-invoke (max 5)
   - If `result` contains `CERTIFYING` -> commit all changes with `fix: {summary from diagnosis}`, set `Committed: yes` in diagnosis, continue to step 7
   - If `result` contains `FIXING` (turn budget exhaustion) -> re-invoke `Skill("resolve-fix", args: "{slug}")` (max 2 total)
   - If `result` contains `RE-INVESTIGATE` (circuit breaker) -> re-invoke `Skill("resolve-investigate", args: "{slug} PHASE_D: RE-INVESTIGATE from fix-notes.md")` (max 1). The `PHASE_D:` marker tells investigate to skip A/B/C and go straight to deep investigation. After re-investigation, go to step 4.
   - If still stuck after retries -> Status -> `FAILED`, report, exit

7. `result = Skill("resolve-certify", args: "{slug}")`
   If `result` contains `GATE` -> handle per Gate Escalation, re-invoke (max 5)
   Read `.workflow/resolve/{slug}/diagnosis.md` Status:
   - `VERIFIED_PROD` -> cleanup `.workflow/resolve/{slug}/`, report summary
   - `FAILED` -> report failure analysis
   - Still CERTIFYING -> re-invoke (max 1). If stuck -> `AskUserQuestion` to escalate.

## Gate Escalation (generic — handles investigate, fix, certify gates)

Any sub-skill can return `{slug}: GATE` when it needs user input. The handler is uniform:

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
   step: {from GATE_STEP comment}
   GATE_EOF
   ```
6. Delete `gate-pending.md`, re-invoke the same sub-skill (`resolve-investigate`, `resolve-fix`, or `resolve-certify`) — it detects `gate-response.md` on startup and resumes where the gate was raised
7. **Gate counter scope:** the orchestrator maintains a counter `gate_loop_count_{sub-skill}` in its working memory (per /resolve invocation, per sub-skill). **Increment** on each consecutive GATE return from the same sub-skill. **Reset to 0** when the sub-skill returns any non-GATE status (TRIVIAL, DIAGNOSED, INSTRUCTIONS, VERIFIED, CERTIFYING, VERIFIED_PROD, FAILED, RE-INVESTIGATE). Three counters exist: one each for investigate/fix/certify.
8. Repeat if the sub-skill raises another GATE, break on terminal status.
9. **At `gate_loop_count_{sub-skill} == 5`:** force failure. Write `Status: FAILED` to diagnosis.md, report to user verbatim: "Gate resolution loop exhausted after 5 attempts in {sub-skill}. Manual triage needed — review .workflow/resolve/{slug}/ for state." Cleanup via Cleanup section. Exit the orchestrator (do NOT proceed to other steps).

**Gate contexts:**

- **resolve-investigate:** vague bug (A.7), strike #3 after 3 failed hypotheses (C.5)
- **resolve-fix:** scope lock (Edit target outside scope.txt)
- **resolve-certify:** deploy failure, production QA failure (existing pattern)

### Cleanup

After any terminal state, delete `.workflow/resolve/{slug}/` directory (diagnosis, fix-notes, next-action, scope.txt, certified marker, gate-pending, gate-response — all ephemeral):

- `VERIFIED_PROD` (normal flow succeeded)
- `Outcome: fixed` (Phase B trivial commit done)
- `Outcome: instructions` (non-code fix or strike-3 abort)
- `Outcome: cancelled` (vague gate cancel)
- `FAILED` (explicit terminal failure)

Also delete `.workflow/build/resolve-{slug}/` if it exists (phantom dir created by certify.sh when called with resolve prefix).

### Guardrails

- NEVER write diagnosis content yourself. Sub-skills handle all diagnosis content.
- NEVER manually advance Status past `FIXING` (only sub-skills advance to CERTIFYING/VERIFIED_PROD).
- Commit happens in the ORCHESTRATOR (step 6 or step 3 for TRIVIAL) after resolve-fix / resolve-investigate returns, NOT inside sub-skills.
- `Committed: yes` is set by the orchestrator after `git commit`, never by sub-skills.
- If a sub-skill completes but Status didn't advance as expected, re-invoke same sub-skill (max 2 retries).
- Track re-investigation count. Max 1 re-investigation cycle to prevent infinite loops.
- Track gate loop count per sub-skill. Max 5 gate iterations per sub-skill invocation.
- **Empty response guard:** When ANY `AskUserQuestion` call returns an empty, blank, or whitespace-only response, it is an accidental submission. NEVER treat it as approval. Re-ask the same question immediately.
