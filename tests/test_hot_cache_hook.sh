#!/usr/bin/env bash
# test_hot_cache_hook.sh — unit tests for scripts/hot-cache-stale.sh and for the
# shell validity of every command hook in hooks/hooks.json.
#
# Hermetic: builds throwaway git repos under mktemp, no network, no external deps
# beyond bash + git. Covers:
#   - every hooks.json command string parses as shell (`bash -n`)
#   - silent outside a vault (no wiki/, no .git) so global installs stay safe
#   - silent when hot.md is level with wiki/
#   - fires on a modified tracked page, an untracked new page, and on a commit
#     that landed wiki/ without hot.md (the PostToolUse auto-commit case)
#   - clears once hot.md is committed alongside
#   - the superseded `git diff --name-only HEAD` condition is shown to miss the
#     auto-commit and untracked cases, which is why it was replaced
#
# Usage: bash tests/test_hot_cache_hook.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STALE_SH="$ROOT/scripts/hot-cache-stale.sh"

PASS=0
FAIL=0

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "OK   $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL $label: expected '$expected', got '$actual'"
    FAIL=$((FAIL + 1))
  fi
}

# Runs the helper against the sandbox and reports "fires" or "silent".
verdict() {
  local out
  out=$(bash "$STALE_SH" "$SANDBOX" 2>/dev/null)
  if [ -n "$out" ]; then echo "fires"; else echo "silent"; fi
}

# The condition this replaced, run against the same sandbox for comparison.
old_verdict() {
  ( cd "$SANDBOX" && git diff --name-only HEAD 2>/dev/null | grep -q '^wiki/' ) \
    && echo "fires" || echo "silent"
}

echo "=== test_hot_cache_hook.sh ==="

# ── every command hook in hooks.json is valid shell ──────────────────────────
# Guards the class of bug that broke this hook: an apostrophe inside a
# single-quoted echo ("the vault's declared budget") silently closed the quote
# and made the whole command a syntax error, so it could never emit anything.
HOOKS_JSON="$ROOT/hooks/hooks.json"
CMD_COUNT=0
while IFS= read -r cmd; do
  CMD_COUNT=$((CMD_COUNT + 1))
  RC=$(printf '%s\n' "$cmd" | bash -n 2>/dev/null; echo $?)
  assert_eq "hooks.json command #$CMD_COUNT parses as shell" "0" "$RC"
done < <(python3 -c "
import json, sys
d = json.load(open('$HOOKS_JSON'))
for event in d['hooks'].values():
    for group in event:
        for h in group['hooks']:
            if h.get('type') == 'command':
                print(h['command'])
")
# An empty corpus would pass every assertion above without testing anything.
if [ "$CMD_COUNT" -lt 3 ]; then
  echo "FAIL hooks.json yielded only $CMD_COUNT command hooks; expected >= 3"
  FAIL=$((FAIL + 1))
else
  echo "OK   hooks.json yielded $CMD_COUNT command hooks"
  PASS=$((PASS + 1))
fi

# ── sandbox vault ────────────────────────────────────────────────────────────
SANDBOX=$(mktemp -d /tmp/hot-cache-test-XXXXXX)
trap 'rm -rf "$SANDBOX"' EXIT
echo "sandbox: $SANDBOX"
echo ""

# ── silent outside a vault ───────────────────────────────────────────────────
assert_eq "no wiki/ and no .git" "silent" "$(verdict)"

git -C "$SANDBOX" init -q
git -C "$SANDBOX" config user.email test@example.com
git -C "$SANDBOX" config user.name "Test"
mkdir -p "$SANDBOX/wiki"
printf '# Recent Context\n' > "$SANDBOX/wiki/hot.md"
printf '# Page A\n' > "$SANDBOX/wiki/page-a.md"
git -C "$SANDBOX" add -A
git -C "$SANDBOX" commit -qm "seed vault"

# ── in sync ──────────────────────────────────────────────────────────────────
assert_eq "hot.md level with wiki/" "silent" "$(verdict)"

# ── a tracked page modified but not committed ────────────────────────────────
printf 'edited\n' >> "$SANDBOX/wiki/page-a.md"
assert_eq "modified tracked page" "fires" "$(verdict)"
assert_eq "  (old condition agreed here)" "fires" "$(old_verdict)"
git -C "$SANDBOX" checkout -q -- wiki/page-a.md

# ── a brand-new page, never committed ────────────────────────────────────────
# `git diff HEAD` does not list untracked files, so the old condition missed this.
printf '# Page B\n' > "$SANDBOX/wiki/page-b.md"
assert_eq "untracked new page" "fires" "$(verdict)"
assert_eq "  (old condition missed it)" "silent" "$(old_verdict)"

# ── auto-commit landed wiki/ without hot.md ──────────────────────────────────
# This is the PostToolUse hook's normal behaviour, and it left the old condition
# with a clean working tree at Stop time.
git -C "$SANDBOX" add -A
git -C "$SANDBOX" commit -qm "wiki: auto-commit"
assert_eq "committed page, hot.md left behind" "fires" "$(verdict)"
assert_eq "  (old condition missed it)" "silent" "$(old_verdict)"

# ── updating hot.md clears it ────────────────────────────────────────────────
printf '# Recent Context\n\nPage B added.\n' > "$SANDBOX/wiki/hot.md"
git -C "$SANDBOX" add -A
git -C "$SANDBOX" commit -qm "wiki: refresh hot cache"
assert_eq "hot.md committed alongside" "silent" "$(verdict)"

# ── a missing hot.md is stale, not silent ────────────────────────────────────
rm "$SANDBOX/wiki/hot.md"
git -C "$SANDBOX" add -A
git -C "$SANDBOX" commit -qm "remove hot cache"
assert_eq "hot.md absent" "fires" "$(verdict)"

# ── the vault is a subdirectory of the repository, not its root ──────────────
# Installs that check the vault in under a larger repo (wiki-vault/ in a tooling
# hub, say) have no .git of their own. An earlier `[ -d .git ]` guard made the
# helper exit 1 unconditionally there — silent in every state, including the
# ones that must fire.
SUB=$(mktemp -d /tmp/hot-cache-sub-XXXXXX)
trap 'rm -rf "$SANDBOX" "$SUB"' EXIT
git -C "$SUB" init -q
git -C "$SUB" config user.email test@example.com
git -C "$SUB" config user.name "Test"
mkdir -p "$SUB/vault/wiki"
printf '# Recent Context\n' > "$SUB/vault/wiki/hot.md"
printf '# Page A\n' > "$SUB/vault/wiki/page-a.md"
printf '# unrelated\n' > "$SUB/README.md"
git -C "$SUB" add -A
git -C "$SUB" commit -qm "seed repo with a nested vault"

sub_verdict() {
  local out
  out=$(bash "$STALE_SH" "$SUB/vault" 2>/dev/null)
  if [ -n "$out" ]; then echo "fires"; else echo "silent"; fi
}

assert_eq "nested vault, in sync" "silent" "$(sub_verdict)"

printf '# Page B\n' > "$SUB/vault/wiki/page-b.md"
assert_eq "nested vault, untracked page" "fires" "$(sub_verdict)"

git -C "$SUB" add -A
git -C "$SUB" commit -qm "wiki: auto-commit"
assert_eq "nested vault, hot.md left behind" "fires" "$(sub_verdict)"

printf '# Recent Context\n\nPage B added.\n' > "$SUB/vault/wiki/hot.md"
git -C "$SUB" add -A
git -C "$SUB" commit -qm "wiki: refresh hot cache"
assert_eq "nested vault, hot.md caught up" "silent" "$(sub_verdict)"

# A dirty hot.md is not itself staleness — it is the fix in progress. Excluded
# by pathspec, so this holds regardless of where the vault sits in the repo.
printf 'still editing\n' >> "$SUB/vault/wiki/hot.md"
assert_eq "nested vault, only hot.md dirty" "silent" "$(sub_verdict)"

# Changes elsewhere in the repository are not the vault's business.
printf 'edited\n' >> "$SUB/README.md"
assert_eq "nested vault, unrelated repo change" "silent" "$(sub_verdict)"

# ── summary ──────────────────────────────────────────────────────────────────
echo ""
echo "Pass: $PASS  Fail: $FAIL"
if [ $FAIL -gt 0 ]; then
  exit 1
fi
echo "All hot-cache hook tests passed."
