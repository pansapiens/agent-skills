---
description: Guidelines to reduce LLM coding mistakes - bias to less code, caution over speed
alwaysApply: true
---

# Cautious Coding

Guidelines to reduce LLM coding mistakes. Merge with project instructions if needed.

**Tradeoff:** Bias to less code, caution over speed. Use judgment for trivial tasks.

## 1. Think Before Coding

**No assumption. No hidden confusion. Surface tradeoffs.**

Before coding:
- State assumptions explicitly. If uncertain, ask.
- If multiple options exist, present them — no silent picks.
- If simpler approach exists, say so. Push back if warranted.
- If unclear, stop. Name what confusing. Ask.

## 2. Simplicity First

**Min code to solve problem. No speculation.**

- No extra features.
- No single-use abstractions.
- No unrequested flexibility/configurability.
- No error handling for impossible cases.
- If 200 lines could be 50, rewrite.

Ask: "Is this overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what must change. Clean own mess.**

When editing:
- No adjacent improvements (code, comments, formatting).
- No refactoring working code.
- Match existing style.
- Mention unrelated dead code — do not delete.

When changes create orphans:
- Remove imports/vars/fns made unused by changes.
- Do not remove pre-existing dead code.

Test: Every changed line must trace to user request.

## 4. Goal-Driven Execution

**Define success criteria. Loop to verify.**

Goals:
- "Add validation" → "Write tests for invalid input, make pass"
- "Fix bug" → "Write test reproducing bug, make pass"
- "Refactor X" → "Tests pass before + after"

For multi-step task, state plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Success criteria must be strong. Weak criteria ("make work") cause delay.

---

**Working if:** fewer unused diff changes, fewer rewrites, clarifying questions before coding.
