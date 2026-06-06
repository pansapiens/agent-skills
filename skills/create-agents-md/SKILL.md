---
name: create-agents-md
description: Create or update an AGENTS.md file to help future coding agents work effectively in this repository. Trigger this skill when the user asks to summarize the project for AI, create an AGENTS.md, initialize the project for agents, or document codebase rules for an LLM.
---

Create or update the `AGENTS.md` file in the root of the repository. This file serves as a set of instructions for future AI coding agents working in the repository.

Follow these phases sequentially:

## Phase 1: Existing File & Preference Check

1. Check if `AGENTS.md` already exists in the root directory. If it does, stop and ask the user if they would like you to review its contents to suggest improvements, or overwrite it completely.
2. Check for other existing AI configuration files (e.g., `CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`, `claude.md`). If they exist, read them.

## Phase 2: Codebase Exploration

Use subagents or read key files to discover context about the repository.
**Crucial Instruction**: Check if the directory is empty or contains only config files. If so, stop immediately and say: "Directory appears empty or only contains config. Add source code first, then run this command to generate AGENTS.md."

Read key manifest files (`package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Makefile`, etc.), `README`, and CI pipeline configurations to detect:
- Build, lint, and test commands (especially non-standard scripts or flags).
- Project structure, languages, frameworks, and core architecture.
- Code style rules or architecture decisions that differ from language defaults.
- Important testing approaches and implicit conventions.

Identify what you could **not** figure out from the codebase alone, and ask questions if required.

## Phase 3: Fill in the gaps

Ask the user for anything the codebase analysis couldn't answer. Ask specific questions about their team's practices to refine the document:
- Are there branch naming or PR conventions not currently documented?
- Do you have any specific communication style preferences for the coding agent (e.g., "be terse," "always plan before executing")?
- What are the non-obvious gotchas, required environment variables, or testing quirks for this repository?

Wait for the user's response before proceeding to synthesize the document.

## Phase 4: Synthesize & Write AGENTS.md

Generate an organized `AGENTS.md` file using the collected information and write it to the repository.

**Guidelines for an excellent AGENTS.md**:
- **Optimal Length**: Keep the file concise. The ideal length is under 500 lines. 
- **Progressive Disclosure**: For detailed architectures or massive guides, do not bloat the file. Instead, reference external documents using relative paths (e.g., "See `docs/architecture.md` for backend patterns").
- **Skip the Obvious**: Do not include generic development practices ("write unified tests", "don't hardcode secrets", "be polite") or standard conventions an LLM already knows. 
- **Be Specific**: Include actual commands that will be run. Example: "Run a single test with `pytest -k 'test_name'`".
- **Focus on Errors**: Only include what an agent would *get wrong* without explicit guidance. Focus primarily on non-obvious knowledge that saves the agent from trial-and-error.
- **Formatting Constraints**: Use clear markdown sections and bullet points. 

**Examples pattern**
When defining specific output formats or messages (e.g., commit messages), provide exact examples:
```markdown
## Commit message format
**Example 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

Write the resulting content to `AGENTS.md` at the project root.
