# Spec Template

Generate `.claude/build/{slug}/spec.md` using this template. Replace all `{placeholders}` with actual content from the approved gates.

```markdown
# {Feature Title}

Status: UNDERSTOOD
Complexity: {LITE | FULL}

## What
What this feature does, in plain language, from the user's perspective.

## Acceptance Criteria
- [ ] Observable behavior 1
- [ ] Observable behavior 2

## Edge Cases
- What happens when X?
- Error states?

## Source
{Reference to plan file or original description, so Phase 2 can use it as implementation hints}
```

## Rules

- `Complexity: LITE` when ALL: single-pattern change, 1-3 files, no new UI flow/data model/endpoint
- `Complexity: FULL` otherwise (default if unsure)
- Status goes to `UNDERSTOOD` — the understanding gate already passed
- The spec describes WHAT — never HOW to implement
- No implementation details: no file lists, no code snippets, no service names
- `## Verification` section is added later by build-verify, not by this template
