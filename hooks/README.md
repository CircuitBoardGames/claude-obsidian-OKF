# claude-obsidian Hooks

Plugin hooks for the claude-obsidian wiki vault. All hooks are defined in `hooks.json`.

## Events

| Event | Type | Purpose |
|---|---|---|
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

## Known Issue: Plugin Hooks STDOUT Bug

`anthropics/claude-code#10875` documents that **plugin hook STDOUT may not be captured** by Claude Code, while identical inline hooks in `settings.json` work correctly.

**Impact**: If this bug is active in your Claude Code version, the prompt-type SessionStart and PostCompact hooks may not inject context as expected.

**Workaround**: The command-type SessionStart hook (`cat wiki/hot.md`) is the canonical safety check. It relies on STDOUT capture for context injection, so test against this issue if hot cache restoration fails. As a fallback, copy the hook config from `hooks.json` into your user-level `~/.claude/settings.json` instead of relying on plugin hooks.

**Test for the bug**: After installing the plugin, open a fresh Claude Code session in a directory containing a populated `wiki/hot.md`. Ask Claude "what's in the hot cache?". If Claude has no idea, the STDOUT bug is active in your version.

## Non-Vault Sessions

The SessionStart command hook uses `[ -f wiki/hot.md ] && cat wiki/hot.md || true` so it always exits 0, even when no vault is present. This makes the plugin safe to install globally without breaking non-vault Claude Code sessions.
