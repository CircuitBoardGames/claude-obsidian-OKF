# Claude Code hooks

`hooks.json` is a thin Claude Code adapter around the portable core.

| Event | Matcher | Behavior |
|---|---|---|
<<<<<<< HEAD
| `SessionStart` | command + prompt | Loads `wiki/hot.md` into context. Command type runs `[ -f wiki/hot.md ] && cat wiki/hot.md` as the canonical safety check (works for non-vault sessions without erroring). Prompt type complements with semantic context restoration. Matcher: `startup\|resume`. |
| `PostCompact` | prompt | Re-loads `wiki/hot.md` after context compaction. Hook-injected context does NOT survive compaction (only `CLAUDE.md` does), so this hook restores the hot cache mid-session. |
| `PostToolUse` | command | Auto-commits any wiki/ or .raw/ changes after Write or Edit tool calls. Guarded by `[ -d .git ]` so it never errors in non-git directories, and by `git diff --cached --quiet` so it never creates empty commits. |
| `Stop` | command | Asks for a `wiki/hot.md` refresh when the hot cache has fallen behind `wiki/`. Delegates the decision to `scripts/hot-cache-stale.sh`; silent when the cache is level, and silent outside a vault. |

## Stop: measuring hot-cache staleness

The reminder is gated on the **commit graph**, not the working tree. The earlier inline test —
`git diff --name-only HEAD | grep -q '^wiki/'` — could not fire in a normal session, for two
independent reasons:

- The `PostToolUse` auto-commit lands `wiki/` changes as soon as they are written, so by the time
  `Stop` runs the working tree is already clean and the grep matches nothing.
- `git diff HEAD` never lists untracked files, so a brand-new page was invisible even with
  auto-commit turned off.

`scripts/hot-cache-stale.sh` fires when `wiki/` has uncommitted or untracked changes other than
`hot.md` itself, when the newest commit touching `wiki/` is not the newest commit touching
`wiki/hot.md`, or when `hot.md` is missing entirely.

Keeping the logic in a script rather than a shell string inside JSON is also what prevents the
quoting bug that broke the previous version: an apostrophe in "the vault's declared budget" closed
its own single-quoted `echo`, making the whole command a syntax error. `tests/test_hot_cache_hook.sh`
now runs `bash -n` over every command hook in `hooks.json` so that class of bug cannot return.

## Stop: what the reminder says

Every path in the reminder is derived from `git rev-parse --show-prefix`, so it resolves from the
repository root — where the reader's cwd is — in a vault at any depth. A hardcoded `wiki/hot.md`
sent an agent to a nonexistent file the first time the fixed hook ever fired in a nested vault.

The reminder deliberately does **not** name sections. It used to restate the `wiki` skill's template
(`Last Updated, Key Recent Facts, Recent Changes, Active Threads`), which duplicates the skill and
goes wrong as soon as a vault diverges from it — it told a vault that had just deleted
`Recent Changes` as redundant to add it back. It asks for the page's existing structure instead, and
cites the vault's `CLAUDE.md` for the budget only when that file exists.
=======
| `SessionStart` | `startup|resume|clear|compact` | Silent by default. With `CLAUDE_OBSIDIAN_SESSION_CONTEXT=1`, resolves a real user vault and emits a bounded, sanitized `wiki/hot.md` data block. A workspace-configured vault outside that project also requires an exact `CLAUDE_OBSIDIAN_SESSION_CONTEXT_VAULT` path. |
| `Stop` | unsupported/omitted | Emits a bounded, aggregate JSON `systemMessage` when recovery is needed. It omits operation identifiers, paths, and note content; otherwise it is silent. |
>>>>>>> 1c1bc49c03a685ee8f5d09c99efe52b42d6673f5

Both are `command` hooks using an executable plus an argument array and
`${CLAUDE_PLUGIN_ROOT}` only to locate plugin code. They do not use the plugin
cache as a vault.

The response shapes follow the current [Claude Code hooks contract](https://code.claude.com/docs/en/hooks):
An opted-in SessionStart may add context through stdout, while Stop warnings use the
supported top-level `systemMessage` field. Stop has no matcher because that
event does not support one. Both readers reject symlinked paths and cap their
scan count and output bytes.

Hooks never write knowledge, update `wiki/hot.md`, stage files, commit Git, run
remote calls, or bypass transaction approval. The same workflows remain usable
on hosts that do not support Claude hooks.
