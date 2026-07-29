#!/usr/bin/env bash
# hot-cache-stale.sh — Stop-hook helper. Prints the hot-cache reminder when
# wiki/ has moved ahead of wiki/hot.md, and stays silent when it has not.
#
# Replaces an inline test in hooks.json that could not fire:
#   `git diff --name-only HEAD | grep -q '^wiki/'`
# was read at Stop time, but the PostToolUse auto-commit has already committed
# wiki/ by then, so the working tree is clean and the grep matches nothing.
# `git diff HEAD` also never lists untracked files, so a brand-new page was
# invisible even with auto-commit off. Staleness is therefore measured against
# the commit graph as well as the working tree.
#
# The reminder text lives in a quoted heredoc rather than a shell string inside
# JSON: the previous inline version was a syntax error because an apostrophe in
# "the vault's declared budget" closed its own single-quoted echo.
#
# Usage: bash scripts/hot-cache-stale.sh [vault-root]   (default: $PWD)
# Exit:  0 + reminder on stdout when hot.md is stale; 1 and silent otherwise.

set -uo pipefail

cd "${1:-$PWD}" 2>/dev/null || exit 1
[ -d wiki ] || exit 1
# Not `[ -d .git ]`: the vault root is not always the repository root. A vault
# checked in as a subdirectory (wiki-vault/ in a larger repo, say) has no .git of
# its own, and that test would silently disable the hook for every such install.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 1

# Absolute pathspecs, so the probes below mean the same thing whether the vault
# is the repository root or a subdirectory of it.
WIKI="$(pwd)/wiki"

# (a) Uncommitted or untracked changes under wiki/, ignoring hot.md itself —
#     editing hot.md is what clears this state, not what triggers it. The
#     exclusion is a git pathspec rather than a grep over porcelain output,
#     which is printed relative to the repository root and so does not have a
#     predictable shape here.
DIRTY=$(git status --porcelain -- "$WIKI" ":(exclude)$WIKI/hot.md" 2>/dev/null)

# (b) hot.md missed the most recent commit that touched wiki/. This is the
#     auto-commit case: the page landed in a commit that left hot.md behind.
LAST_WIKI=$(git log -1 --format=%H -- "$WIKI" 2>/dev/null)
LAST_HOT=$(git log -1 --format=%H -- "$WIKI/hot.md" 2>/dev/null)

# A vault with a wiki/ but no hot.md at all is maximally stale: SessionStart has
# nothing to inject. Both git probes above agree on the commit that deleted it.
if [ -f "$WIKI/hot.md" ] && [ -z "$DIRTY" ] && [ "$LAST_WIKI" = "$LAST_HOT" ]; then
  exit 1
fi

# Name the real paths. A hardcoded "wiki/hot.md" is wrong in any vault that is
# not the repository root, and the reader acts on what this says: it sent one
# agent to a path that did not exist. `--show-prefix` gives the vault's location
# relative to the repository root, which is where the reader's cwd is; fall back
# to the absolute path outside a work tree.
VAULT=$(git rev-parse --show-prefix 2>/dev/null)          # "" at the repo root
HOT="${VAULT}wiki/hot.md"
POLICY="${VAULT}CLAUDE.md"
[ -f CLAUDE.md ] || POLICY=""

# Deliberately does NOT prescribe a section list. It used to name "Last Updated,
# Key Recent Facts, Recent Changes, Active Threads", which restates the wiki
# skill's template and goes wrong the moment a vault diverges from it — telling
# one vault to re-add the very section it had just removed as duplicated.
printf 'WIKI_CHANGED: %s is behind its vault. Please rewrite it with a brief, factual summary of what changed, keeping the page structure it already has' "$HOT"
if [ -n "$POLICY" ]; then
  printf ' and the hot-cache budget %s declares' "$POLICY"
fi
cat <<'REMINDER'
. Overwrite the file completely. It is a cache, not a journal: what it drops is still in the log and in git.
REMINDER
exit 0
