---
name: import-agent-session
description: >-
  Discover and import previous coding session transcripts from Claude Code
  (or Claude Code Switch) so the current agent can resume work with full context.
  Use when the user says things like "continue from Claude Code", "find previous
  sessions for this project", "resume where we left off", "pick up from my last
  Claude session", or "import context from a previous coding session". Also use
  when switching between coding agents and the user wants to carry over context
  from a prior Claude Code session.
---

# Import Agent Session

Discover previous Claude Code session transcripts for the current project, summarise them, and help the user resume work with full context.

## When to use

- User wants to continue work started in Claude Code (or another agent)
- User asks to find, list, or import previous coding sessions
- User is switching agents and needs context from prior sessions

## How Claude Code stores sessions

Claude Code stores session transcripts as JSONL files under two possible locations:

1. **`~/.claude/projects/<project-key>/`** — Classic Claude Code
2. **`~/.ccs/instances/*/projects/<project-key>/`** — Claude Code Switch (CCS), with instance subdirectories (e.g. `personal`, `work`)

The `<project-key>` is derived from the project's working directory by replacing `/` with `-`, e.g.:
- `/home/user/projects/agent-skills` → `-home-user-projects-agent-skills`

Each project directory may contain:
- **`<uuid>.jsonl`** — Raw session transcript (one JSON object per line)
- **`memory`** — Project-level memory notes (may be empty)
- **Compiled views** (if conversation-compiler / VCC has been run):
  - `<uuid>.txt` — Full compiled transcript
  - `<uuid>.min.txt` — Condensed overview (best for quick scanning)
  - `<uuid>.view.txt` — Search-focused view (from `--grep`)
  - `<uuid>_<N>.txt` / `<uuid>_<N>.min.txt` — Numbered chunks for long sessions

### JSONL structure

Each line is a JSON object. Key fields:
- `type`: `"user"`, `"assistant"`, `"mode"`, `"permission-mode"`, etc.
- `message.role` / `message.content`: The actual message
- `timestamp`: ISO 8601 timestamp
- `cwd`: Working directory at time of message
- `sessionId`: UUID identifying the session
- `isMeta`: If `true`, this is a system/meta message (skip when summarising)

## Workflow

### Step 1: Determine project key

Derive the project key from the current working directory. The working directory should be available from the agent's context (e.g. workspace root). Convert the absolute path to the key format:

```
/home/user/projects/my-app → -home-user-projects-my-app
```

### Step 2: Find session files

Search both storage locations for matching project directories:

```bash
PROJECT_KEY="-$(pwd | sed 's|/|-|g; s|^-||')"

# Find all matching session directories
for DIR in \
  "$HOME/.claude/projects/${PROJECT_KEY}" \
  $HOME/.ccs/instances/*/projects/"${PROJECT_KEY}"; do
  if [ -d "${DIR}" ]; then
    echo "=== ${DIR} ==="
    ls -lt "${DIR}"/*.jsonl 2>/dev/null
  fi
done
```

If no exact match is found, list available project directories and let the user pick:

```bash
ls ~/.claude/projects/ 2>/dev/null
ls ~/.ccs/instances/*/projects/ 2>/dev/null
```

### Step 3: Present sessions to the user

For each `.jsonl` file found, extract a brief summary to help the user choose:

```bash
# Get timestamp range, session ID, and first real user message
python3 -c "
import json, sys, os, datetime

for path in sys.argv[1:]:
    first_ts = last_ts = None
    first_msg = None
    sid = os.path.basename(path).replace('.jsonl', '')
    size_kb = os.path.getsize(path) / 1024

    with open(path) as f:
        for line in f:
            d = json.loads(line)
            ts = d.get('timestamp')
            if ts:
                if not first_ts: first_ts = ts
                last_ts = ts
            if (d.get('type') == 'user' and not d.get('isMeta')
                and not first_msg):
                content = d.get('message', {}).get('content', '')
                if isinstance(content, str) and '<command-' not in content and '<local-command' not in content and len(content.strip()) > 10:
                    first_msg = content[:150]

    print(f'Session: {sid}')
    print(f'  Period: {first_ts} to {last_ts}')
    print(f'  Size: {size_kb:.0f} KB')
    print(f'  First message: {first_msg}')
    print()
" /path/to/project/*.jsonl
```

Present the sessions to the user (sorted by date, most recent first). If there are multiple sessions, ask which one(s) to import.

### Step 4: Read and summarise the session

**If VCC / conversation-compiler is available** (check for `~/.claude/skills/conversation-compiler/scripts/VCC.py`):

1. Compile the JSONL if `.min.txt` files don't already exist:
   ```bash
   python3 ~/.claude/skills/conversation-compiler/scripts/VCC.py /path/to/session.jsonl
   ```
2. Read the `.min.txt` file(s) — these give a scannable overview with tool call summaries
3. For specific details, use `--grep` or read referenced line ranges in the `.txt` file

If the skill is not installed, install it from [lllyasviel/VCC](https://github.com/lllyasviel/VCC):

```bash
npx skills add -g -y lllyasviel/VCC
```

**If VCC is not available**, read the JSONL directly:

```bash
# Extract user and assistant messages, skipping meta/system
python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    for line in f:
        d = json.loads(line)
        if d.get('isMeta'): continue
        if d.get('type') not in ('user', 'assistant'): continue
        msg = d.get('message', {})
        content = msg.get('content', '')
        if isinstance(content, str) and '<command-' not in content and '<local-command' not in content:
            role = msg.get('role', d.get('type'))
            ts = d.get('timestamp', '')
            print(f'[{role}] ({ts})')
            print(content[:500])
            print()
" /path/to/session.jsonl | head -200
```

For large sessions, focus on the last portion (most recent context).

### Step 5: (Optional) Copy session files into the project

If the user wants session files accessible within the project:

```bash
mkdir -p .agents/sessions/claude-code/
cp /path/to/session.jsonl .agents/sessions/claude-code/
```

Add `.agents/sessions/` to `.gitignore` to avoid committing large transcript files.

### Step 6: Check memory file

Also read the project `memory` file if it exists and is non-empty:

```bash
MEMORY_FILE="$HOME/.claude/projects/${PROJECT_KEY}/memory"
if [ -s "${MEMORY_FILE}" ]; then
  cat "${MEMORY_FILE}"
fi
```

### Step 7: Resume work

After reading the session context:

1. Summarise what was accomplished in the previous session(s)
2. Note any unfinished work, open TODOs, or next steps mentioned
3. Read key files that were being worked on (they may have changed since the session)
4. Ask the user what they'd like to continue with

## Notes

- Session JSONL files can be very large (tens of MB). Prefer `.min.txt` compiled views when available.
- The `memory` file contains project-level notes Claude Code persists across sessions — always check it.
- When multiple sessions exist, the most recent is usually most relevant, but older sessions may contain important architectural decisions.
