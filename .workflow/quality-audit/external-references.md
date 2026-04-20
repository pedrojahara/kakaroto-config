# External References — Quality Audit (code-reviewer + code-simplifier)

Filter: publication date ≥ 2025-10 OR canonical reference. Emphasis on Claude Opus 4.7 (released 2026-04).

## Tier 1 — Mandatory Opus 4.7 sources

### 1. Claude.com — Best practices for using Claude Opus 4.7 with Claude Code
- URL: https://claude.com/blog/best-practices-for-using-claude-opus-4-7-with-claude-code
- Date: 2026-04-16
- Author: Anthropic
- Model referenced: Opus 4.7 (explicit)
- Key principles:
  - **Literal interpretation**: "Opus 4.7 does not silently fill in implicit context like 4.6 did." Sub-agents drift without explicit intent/acceptance-criteria/constraints. → Every agent prompt needs EXPLICIT scope rules, not implicit ones.
  - **Fewer subagents by default**: 4.7 is "more judicious." If we want delegation, spell it out; if we want non-delegation, no action needed.
  - **Calibrated response length**: simpler tasks get shorter answers. Our output table should scale: TRIVIAL may produce 0-row tables; forcing boilerplate is counter-productive.
  - **Verification is 2-3x more valuable than before**: always give the agent a way to verify its own work (tsc/test).
  - **Mandatory reading**: "Every sub-agent dispatched must read the full plan file as its first action. On 4.7, literal interpretation means sub-agents drift without the full context."

### 2. code.claude.com — Create custom subagents
- URL: https://code.claude.com/docs/en/sub-agents
- Date: ongoing (canonical)
- Key principles (direct quotes / tips):
  - "Design focused subagents: each subagent should excel at one specific task." → Validates reviewer ≠ simplifier boundary. Tightens rule against overlap.
  - "Limit tool access: grant only necessary permissions for security and focus." → Reviewer currently has Edit (needed for auto-fix). This is an accepted deviation from the pure read-only pattern shown in the example — compensate by scope discipline in prompt.
  - Example code-reviewer in the docs structures feedback as **Critical / Warnings / Suggestions** (priority-grouped). → Our CRÍTICO/ALTO/MÉDIO/BAIXO is compatible but we should reinforce: "must fix / should fix / consider improving" semantics.
  - Reviewer doc example workflow: "1. Run git diff to see recent changes 2. Focus on modified files 3. Begin review immediately." → We should add an explicit "diff only" mandate using `git diff`.

### 3. code.claude.com — Best Practices
- URL: https://code.claude.com/docs/en/best-practices
- Date: ongoing (canonical)
- Key principles:
  - "Give Claude a way to verify its work... this is the single highest-leverage thing you can do." → tsc + test loop inside reviewer/simplifier is validated.
  - "Address root causes, not symptoms." → Reviewer must fix root cause, not silence errors. Add explicit guard against `@ts-ignore` shortcuts by the reviewer itself when self-fixing.
  - "Avoid the trust-then-verify gap… Always provide verification… If you can't verify it, don't ship it." → If agent's auto-fix cannot run tsc/test (special file, env broken), do NOT mark ISSUES_FIXED. Report-only.

### 4. keepmyprompts.com — Opus 4.7 Prompting Guide: Breaking Changes
- URL: https://www.keepmyprompts.com/en/blog/claude-opus-4-7-prompting-guide-whats-changed
- Date: 2026-04-17
- Model referenced: Opus 4.7
- Key principles:
  - "Compensatory scaffolding is now counterproductive; native model capabilities replace verbose instruction patterns." → Trim our prompts of redundant verbose hedging; keep rules crisp.
  - "For research tasks, delegate sub-queries to parallel sub-agents when the queries are independent." → N/A here (no nested delegation).

## Tier 2 — Supporting sources (code review, DRY, OWASP, AC)

### 5. anthropic.com — Building effective agents (general patterns)
- URL: https://www.anthropic.com/engineering/building-effective-agents
- Status: canonical
- Key principles:
  - Evaluator-Optimizer pattern: one agent generates, one evaluates iteratively. Our pipeline uses this implicitly (build-implement generates; reviewer evaluates/fixes).
  - "Start with simple prompts, optimize them...and add multi-step agentic systems only when simpler solutions fall short." → Sanity check: two-agent split is justified (review ≠ polish). Avoid third agent.
  - "Tools deserve just as much prompt engineering attention as your overall prompts."

### 6. devtoolsacademy.com — State of AI Code Review Tools in 2025
- URL: https://www.devtoolsacademy.com/blog/state-of-ai-code-review-tools-2025/
- Date: 2025-10-21
- Key principles:
  - Bug detection rates of top AI reviewers: 42–48%. Human review remains complementary.
  - **False positive rate < 5% target** or the tool gets ignored. → Reviewer must bias for Recall ≥ FPR; MÉDIO/BAIXO issues should be REPORT-ONLY, not fix.
  - "Style issues, bugs, and missing tests" is the AI-appropriate scope; architecture stays with humans. → Validates our current boundary.
  - "Higher comment volume correlates with broader issue coverage but increased false positives." → Be terse; surface only genuine issues.

### 7. OWASP Top 10 for LLM Applications 2025
- URL: https://genai.owasp.org/resource/owasp-top-10-for-llm-applications-2025/
- Date: 2025
- Key patterns for our reviewer (adjacent — our reviewer reviews app code, but LLM-adjacent systems are common):
  - Prompt injection, sensitive information disclosure, improper output handling, supply chain, excessive agency.
  - LLM coding assistants "generate code that frequently contains injection patterns, authentication failures, and cryptographic weaknesses." → Reviewer's security checklist must remain opinionated about these.

### 8. SAST-Genius (IEEE S&P 2025) + IRIS (ICLR 2025)
- Context: LLMs + static analysis combined deliver >100% detection uplift vs CodeQL alone and −91% FP rate when LLM filters SAST output.
- Key principle: **Binary verifiable ground truth** matters. Our Acceptance Criteria gate already operates this way — keep binary.

### 9. Wikipedia / understandlegacycode.com / thecodewhisperer.com — Rule of Three (Fowler/Roberts)
- URLs:
  - https://en.wikipedia.org/wiki/Rule_of_three_(computer_programming)
  - https://understandlegacycode.com/blog/refactoring-rule-of-three/
- Key principles:
  - "Knowledge duplication is always a DRY violation; code duplication is not necessarily." → Our simplifier's rule should check "same knowledge" not just "same characters."
  - "Before extracting shared code, consider how likely each section is to evolve independently; if two code paths serve different stakeholders or are expected to change for different reasons, duplication is preferable to coupling them through a shared abstraction." → Add to simplifier: "do not extract if the 3 occurrences are likely to evolve independently."
  - "DRY as a heuristic to be questioned, not a law."

### 10. LangChain / Patronus / Confident AI — Binary checklist evaluation for LLM agents
- Key principles:
  - "Binary pass/fail scoring is preferred over numeric scales."
  - "Verifiable checklist module: atomic verification questions, collect answers and evidence for each item, apply measurable filters... synthesize into a global decision with rationales." → Validates our AC-as-checklist design. Strengthen: each AC item → binary, with explicit evidence pointer (file:line or test name).

## Principles incorporated into this audit

1. **Explicit over implicit** (Opus 4.7): no hedging language, no "consider X" where we mean "do X."
2. **Diff-only scope enforcement**: add mandatory first step — `git diff --name-only` → agents operate strictly on listed files.
3. **Verifiability is the highest-leverage lever**: keep tsc + test; forbid auto-fix when verification cannot run; never mark ISSUES_FIXED without passing verification.
4. **Boundary sharpness**: reviewer says "not my job → skip (→ code-simplifier)"; simplifier says "not my job → skip (→ code-reviewer)." Make this literal.
5. **Binary AC with evidence pointers**: each criterion → pass/fail + evidence (file:line | test-name). Vague criteria → AMBIGUOUS (non-blocking).
6. **Knowledge DRY, not char DRY**: rule-of-3 condition on "same knowledge" + "likely to evolve together."
7. **FP < 5% target**: MÉDIO/BAIXO → report-only. CRÍTICO → fix. ALTO → fix if small + low-risk, else report.
8. **Priority-grouped output** consistent with Anthropic example: "must fix / should fix / consider" semantics already match our CRÍTICO/ALTO/MÉDIO/BAIXO.
