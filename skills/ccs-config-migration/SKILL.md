---
name: ccs-config-migration
description: >-
  Move a CCS (https://ccs.kaitran.ca/) account profile from one machine to
  another - e.g. "copy my ccs profile to m3", "move ccs work to this host",
  "why doesn't ccs <profile> launch on the new machine". Also covers CCS
  context groups (opt-in sharing of project history between accounts):
  checking whether sharing can be turned on for existing accounts without
  losing sessions, and how to enable, verify and reverse it. Covers the
  recommended re-auth approach for OAuth account profiles, the manual
  file-copy fallback for cloning plugins/config, and the registry gotcha
  (config.yaml `accounts:` entry) that makes a copied profile invisible to
  the CLI even when all its files are present.
---

# CCS config migration and context sharing

CCS (https://ccs.kaitran.ca/) manages isolated Claude Code "accounts"
(also called profiles/instances) under `~/.ccs/instances/<name>/`, each with
its own auth, session history, and settings. CCS runs Claude with
`CLAUDE_CONFIG_DIR=~/.ccs/instances/<name>`. Moving an instance to another
machine is not a plain directory copy.

Useful read-only inspection commands (source or destination):

```bash
ccs auth list --json        # context_mode, context_group, continuity_mode, instance_path per profile
ccs auth show <name>        # context, resources, credentials, history summary
```

## First choice: re-authenticate, don't copy

For OAuth-backed account profiles, the officially documented path is simplest:

```
ccs auth create <name>
```

run directly on the destination machine. This re-registers the account in
`config.yaml` and does a fresh OAuth login - no file transfer needed. Prefer
this whenever the user just wants "the same login/profile available on
another machine" and doesn't care about carrying over plugin state or
agent memory. It also avoids copying OAuth tokens to a second host.

Flags: `--bare` (isolated profile, no shared commands/skills/agents),
`--share-context [--context-group <name>] [--deeper-continuity]` (see
"Context sharing" below). These flags only apply at creation.

For **API-key profiles** (GLM, Kimi, custom endpoints - not OAuth), there
*is* a built-in export/import path, which is easier than the manual copy
below:

```
ccs api export <name> --out <name>.json --include-secrets   # on source
# transfer the file
ccs api import <name>.json                                   # on destination
```

## When to copy files manually instead

Re-auth loses local state the user may actually want carried over: plugin
installs, agent memory, cached MCP-auth state, policy limits. If the user
explicitly wants that state cloned, copy files - but be surgical. Copying the
entire `~/.ccs/instances/<name>/` tree brings across host- and path-specific
junk that won't apply to the new machine.

### Pre-flight on the destination (never clobber)

Before writing anything, read the destination's `~/.ccs/config.yaml` and
`ls ~/.ccs/instances/`. Stop if `instances/<name>` already exists. Create the
target directory with `mkdir` (mode 700) only when absent, and use
`rsync -a --ignore-existing` for every copy. Remember:

- The destination user and `$HOME` may differ from the source (e.g.
  `/home/alice` vs `/home/bob`). Absolute paths inside copied files must be
  rewritten (see "Path rewriting").
- `ccs` is often not on `PATH` in a non-interactive `ssh host cmd` shell
  (nvm/conda installs). Use `ssh host 'bash -lic "ccs ..."'` or tell the user
  to run the final verification interactively.
- A copied `.credentials.json` duplicates OAuth tokens onto another machine.
  Tell the user, and keep mode 600.

### Layout of one instance directory

```
~/.ccs/instances/<name>/
  .claude.json          # global config + PER-PROJECT data (keyed by local paths!)
  .credentials.json      # OAuth tokens - sensitive, chmod 600
  mcp-needs-auth-cache.json
  policy-limits.json
  remote-settings.json
  plugins/
  cache/                 # global caches (changelog, closed-issues) - safe to copy
  .anthropic/
  agent-memory/          # per-agent memory, not path-keyed - safe to copy
  agents -> ~/.ccs/shared/agents         # symlink
  CLAUDE.md -> ~/.ccs/shared/CLAUDE.md   # symlink
  commands -> ~/.ccs/shared/commands     # symlink
  settings.json -> ~/.ccs/shared/settings.json  # symlink
  skills -> ~/.ccs/shared/skills         # symlink

  # session/project-path-specific - DO NOT copy to a different host:
  projects/           # keyed by local absolute cwd paths; a SYMLINK into
                      # ~/.ccs/shared/context-groups/<group>/projects when
                      # context sharing is on (would dangle on the new host)
  session-env/ sessions/ file-history/ shell-snapshots/ todos/   # also the
                      # "deeper continuity" artifacts, possibly symlinks
  debug/ logs/ jobs/ daemon/ ide/ paste-cache/ tasks/ state/
  backups/             # local .claude.json backups
  history.jsonl        # prompt history tied to local project paths
  .last-cleanup  .last-update-result.json
  settings.json.ccs-adopt-recovery*   # local recovery snapshots
```

Suggested copy:

```bash
S=~/.ccs/instances/<name>
rsync -a --ignore-existing "$S/.credentials.json" "$S/policy-limits.json" \
  "$S/remote-settings.json" "$S/.anthropic" "$S/cache" "$S/plugins" \
  "$S/agent-memory" host:.ccs/instances/<name>/
```

`.claude.json` itself mixes global settings (mcpServers, oauth, feature
flag caches, userID) with a `projects` map and `githubRepoPaths` list that
are both keyed by local absolute paths. Write a sanitised copy to a temp file
(never edit the source in place), strip those two keys, and send that:

```python
import json
d = json.load(open("<src>/.claude.json"))
d.pop("projects", None)
d.pop("githubRepoPaths", None)
json.dump(d, open("/tmp/claude.json", "w"), indent=2)   # then chmod 600, rsync, rm
```

### Path rewriting

`plugins/installed_plugins.json`, `known_marketplaces.json` and
`.claude.json` (mcpServers) contain absolute install paths. On the
destination, if the home directory differs:

```bash
grep -rl /home/<srcuser> plugins .claude.json | xargs -r sed -i 's#/home/<srcuser>#/home/<dstuser>#g'
```

Also scan `.claude.json` mcpServers for commands that only exist on the
source (local binaries, `nvm` paths); mention any to the user.

### Fixing the symlinks

The `agents`/`CLAUDE.md`/`commands`/`settings.json`/`skills` symlinks point
at `~/.ccs/shared/...` using the *source* machine's home directory (or a
literal absolute path). Recreate them on the destination pointing at that
machine's own `$HOME`:

```bash
for l in agents CLAUDE.md commands settings.json skills; do ln -sfn ~/.ccs/shared/$l $l; done
```

(Check an existing instance on the destination, with `ls -la`, to confirm the
convention. The destination's `~/.ccs/shared/*` may itself point at `~/.claude/*`;
that is fine and should not be changed.)

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
in the destination's `config.yaml` (any ISO timestamp works). Edit only that
map; leave existing entries alone. For context metadata, default to
`context_mode: isolated` on the destination, even if the source is shared:
the group's `projects/` is not being copied, and sharing can be enabled
deliberately on the new host afterwards. If the user wants the same grouping
there, copy `context_mode`, `context_group` and `continuity_mode` verbatim;
the group directory is created on first launch. Verify with:

```bash
ccs <name> --help
```

If this prints Claude Code's usage text instead of an error, the profile is
correctly registered.

## Context sharing (context groups)

By default every account keeps its own `projects/` (session transcripts,
per-project memory). Credentials, tokens and `.anthropic` state stay
isolated per account regardless; only history is shared. Sharing is
configured per account in `~/.ccs/config.yaml`:

```yaml
accounts:
  <name>:
    context_mode: shared          # isolated (default) | shared
    context_group: <group>        # accounts with the same group share; always name it
    continuity_mode: standard     # standard | deeper (only valid when shared)
```

Behaviour, from the CCS source (`management/shared-manager/project-context-sync.js`,
`auth/account-context.js`, `management/instance-manager.js`):

- **When it takes effect:** at the next launch of that account (`ensureInstance`,
  under a per-profile lock), which runs on a normal `ccs <name>` launch and
  on `ccs auth backup|resources <name>`. Editing `config.yaml` does nothing
  until then. `ccs auth show|list` are read-only and do not trigger it.
- **Shared mode:** `instances/<name>/projects` becomes a symlink to
  `~/.ccs/shared/context-groups/<group>/projects`. An existing real
  `projects/` directory is **merged into the group directory, then deleted**,
  then replaced by the symlink.
- **Merge rules:** copies files that don't exist in the group; skips
  byte-identical files; if the same relative path exists with different
  content, the incoming file is kept as `<file>.migrated-from-<account>`
  (numbered if repeated). Nothing is overwritten, so no data is lost, but a
  conflicting file is no longer the one Claude reads by its normal name.
- **Deeper continuity** (`continuity_mode: deeper`, or
  `--deeper-continuity` at create): also symlinks `session-env`,
  `file-history`, `shell-snapshots`, `todos` into
  `context-groups/<group>/continuity/`, with the same merge-then-link logic.
  Standard mode leaves these local. Not needed for `--resume`/`-c` to see
  shared sessions.
- **Back to isolated:** the symlink is replaced by a real directory populated
  with a copy of the whole group's `projects/`. The other members are
  unaffected.
- **No CLI for existing accounts.** `ccs auth create` flags only apply when
  creating. For an existing account, edit `config.yaml` by hand (set all of
  `context_mode`, `context_group`) or use Dashboard > Accounts > Sync
  (`PUT /api/accounts/:name/context`). Group names are normalised to
  lowercase `[a-z][a-z0-9_-]*`, max 64 chars.
- Docs warn: never hand-copy or combine `projects/` between accounts to fix a
  resume mismatch; use groups instead.

### Is it safe to turn on for existing accounts?

Session files are named by UUID inside a directory named after the encoded
cwd (`-home-user-proj`), so two accounts rarely produce the same relative
path with different content. Check before enabling; this is read-only:

```bash
cd ~/.ccs/instances
for a in <acct1> <acct2>; do ls $a/projects; done | sort | uniq -d     # shared cwd dirs
# for each shared dir, list files present in both accounts with differing content:
for p in $(comm -12 <(ls <acct1>/projects|sort) <(ls <acct2>/projects|sort)); do
  (cd <acct1>/projects/$p && find . -type f) | while read f; do
    [ -f <acct2>/projects/$p/$f ] && { cmp -s <acct1>/projects/$p/$f <acct2>/projects/$p/$f && echo "same $p/$f" || echo "DIFF $p/$f"; }
  done
done
```

No output from the inner loop means no file-level conflicts; `DIFF` lines
will become `.migrated-from-*` copies. Directories present in only one
account just move into the group and become visible to all members.

The real risk is not conflicts but **live sessions**: the merge copies and
then `rm -rf`s the original `projects/`, so a running Claude session (any
terminal, plus IDE extensions that use `CLAUDE_CONFIG_DIR`) writing
transcripts during that window can lose data or write into a deleted path.
Procedure:

1. `pgrep -af 'claude|ccs'` and confirm no session is running for any
   account being changed (including the IDE extension). Ask the user to
   close them; do not kill them.
2. `ccs auth backup <name>` for each account (copies `projects/` and
   continuity artifacts; the lane is dereferenced, so it is a real copy).
   Also note `du -sh instances/<name>/projects` so the group directory size
   can be checked afterwards.
3. Edit `config.yaml`: for every member set `context_mode: shared` and the
   same explicit `context_group`. Make the edit minimal and keep a copy of the
   original file.
4. Run `ccs auth backup <name>` again (or launch the account normally) to
   trigger the merge, and verify:
   `ls -ld instances/<name>/projects` shows the symlink,
   `ccs auth list --json` shows the group, and
   `find ~/.ccs/shared/context-groups/<group> -name '*.migrated-from-*'`
   lists any conflicts to review.
5. Rollback if needed: restore `config.yaml`, launch the account (it
   becomes a real directory again with a copy of the group's projects), or
   restore from the `ccs auth backup` output.

On a migration destination, an account's `projects/` was not copied, so
turning sharing on there has nothing to merge.

## Checklist

1. Prefer `ccs auth create <name>` (OAuth) or `ccs api export/import` (API
   profiles) over manual copying - ask the user if they need plugin/agent
   state carried over before doing the heavier manual copy.
2. Inspect the destination first (config.yaml, instances/); never overwrite
   an existing instance or other accounts' entries.
3. If copying manually: exclude everything in the session/project-specific
   list above (including a symlinked `projects/`), sanitise `.claude.json`,
   rewrite source-home paths, and keep `.credentials.json` at mode 600.
4. Recreate the shared-resource symlinks with the destination's own home
   path.
5. Add the account to `accounts:` in the destination's `config.yaml` - this
   step is easy to miss since it's not a file *in* the instance directory,
   and skipping it is the most likely reason `ccs <name>` "does nothing" on
   the new machine.
6. Confirm with `ccs <name> --help` (interactive shell, so `ccs` is on PATH).
7. For context sharing changes: run the conflict check, make sure no sessions
   are running, back up, edit config, launch, verify.
