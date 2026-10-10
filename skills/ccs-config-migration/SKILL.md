---
name: ccs-config-migration
description: >-
  Move a CCS (https://ccs.kaitran.ca/) account profile from one machine to
  another — e.g. "copy my ccs profile to m3", "move ccs work to this host",
  "why doesn't ccs <profile> launch on the new machine". Covers the
  recommended re-auth approach for OAuth account profiles, the manual
  file-copy fallback for cloning session state/plugins/config, and the
  registry gotcha (config.yaml `accounts:` entry) that makes a copied
  profile invisible to the CLI even when all its files are present.
---

# CCS config migration

CCS (https://ccs.kaitran.ca/) manages isolated Claude Code "accounts"
(also called profiles/instances) under `~/.ccs/instances/<name>/`, each with
its own auth, session history, and settings. Moving one to another machine
is not a plain directory copy.

## First choice: re-authenticate, don't copy

For OAuth-backed account profiles, the officially documented path is simplest:

```
ccs auth create <name>
```

run directly on the destination machine. This re-registers the account in
`config.yaml` and does a fresh OAuth login — no file transfer needed. Prefer
this whenever the user just wants "the same login/profile available on
another machine" and doesn't care about carrying over history or local
plugin state.

Use `ccs auth create <name> --bare` for an isolated profile with no shared
resources, or `--share-context` to share history across accounts.

For **API-key profiles** (GLM, Kimi, custom endpoints — not OAuth), there
*is* a built-in export/import path, which is easier than the manual copy
below:

```
ccs api export <name> --out <name>.json --include-secrets   # on source
# transfer the file
ccs api import <name>.json                                   # on destination
```

## When to copy files manually instead

Re-auth loses local state the user may actually want carried over: session
history, plugin installs, cached MCP-auth state, policy limits. If the user
explicitly wants that state cloned (not just a fresh login), copy files —
but be surgical. Copying the entire `~/.ccs/instances/<name>/` tree brings
across host- and path-specific junk that won't apply to the new machine.

### Layout of one instance directory

```
~/.ccs/instances/<name>/
  .claude.json          # global config + PER-PROJECT data (keyed by local paths!)
  .credentials.json      # OAuth tokens — sensitive, chmod 600
  mcp-needs-auth-cache.json
  policy-limits.json
  remote-settings.json
  plugins/
  cache/                 # global caches (changelog, closed-issues) — safe to copy
  .anthropic/
  agents -> ~/.ccs/shared/agents         # symlink
  CLAUDE.md -> ~/.ccs/shared/CLAUDE.md   # symlink
  commands -> ~/.ccs/shared/commands     # symlink
  settings.json -> ~/.ccs/shared/settings.json  # symlink
  skills -> ~/.ccs/shared/skills         # symlink

  # session/project-path-specific — DO NOT copy to a different host:
  projects/           # keyed by local absolute cwd paths
  session-env/         # per-session-UUID scratch dirs
  sessions/
  file-history/
  shell-snapshots/
  todos/
  debug/
  logs/
  backups/             # local .claude.json backups
  history.jsonl        # prompt history tied to local project paths
  .last-cleanup
  .last-update-result.json
  settings.json.ccs-adopt-recovery*   # local recovery snapshots
```

`.claude.json` itself mixes global settings (mcpServers, oauth, feature
flag caches, userID) with a `projects` map and `githubRepoPaths` list that
are both keyed by local absolute paths. When copying this file to another
host, strip those two keys — they're meaningless (or actively wrong) on a
machine with different paths:

```python
import json
d = json.load(open(".claude.json"))
d.pop("projects", None)
d.pop("githubRepoPaths", None)
json.dump(d, open(".claude.json", "w"), indent=2)
```

### Fixing the symlinks

The `agents`/`CLAUDE.md`/`commands`/`settings.json`/`skills` symlinks point
at `~/.ccs/shared/...` using the *source* machine's home directory (or a
literal absolute path). Recreate them on the destination pointing at that
machine's own `$HOME`:

```bash
ln -sfn ~/.ccs/shared/agents agents
ln -sfn ~/.ccs/shared/CLAUDE.md CLAUDE.md
ln -sfn ~/.ccs/shared/commands commands
ln -sfn ~/.ccs/shared/settings.json settings.json
ln -sfn ~/.ccs/shared/skills skills
```

### The registry gotcha (this is the one that bites you)

Even with every file in place, `ccs <name>` will fail to resolve on the new
host, because the CLI doesn't discover instances by scanning
`~/.ccs/instances/`. It looks up the name in the top-level `accounts:` map
in `~/.ccs/config.yaml`:

```yaml
accounts:
  work:
    created: "2026-07-13T04:05:23.166Z"
    last_used: "2026-09-08T21:27:41.070Z"
    context_mode: isolated
  <name>:                 # <-- this entry must exist on the destination too
    created: "..."
    last_used: "..."
    context_mode: isolated
```

After copying the instance directory, add a matching entry under `accounts:`
in the destination's `config.yaml` (any ISO timestamp works; match the
`context_mode` — usually `isolated` — of the entries already there). Verify
with:

```bash
ccs <name> --help
```

If this prints Claude Code's usage text instead of an error, the profile is
correctly registered.

## Checklist

1. Prefer `ccs auth create <name>` (OAuth) or `ccs api export/import` (API
   profiles) over manual copying — ask the user if they need history/plugin
   state carried over before doing the heavier manual copy.
2. If copying manually: exclude everything in the session/project-specific
   list above, and strip `projects`/`githubRepoPaths` from `.claude.json`.
3. Recreate the shared-resource symlinks with the destination's own home
   path.
4. Add the account to `accounts:` in the destination's `config.yaml` — this
   step is easy to miss since it's not a file *in* the instance directory,
   and skipping it is the most likely reason `ccs <name>` "does nothing" on
   the new machine.
5. Confirm with `ccs <name> --help`.
