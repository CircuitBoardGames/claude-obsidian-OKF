---
name: wiki-fold
<<<<<<< HEAD
description: "Rollup of wiki log entries into meta-pages. Reads the oldest 2^k entries no earlier fold has covered, writes a structurally-idempotent fold page to wiki/folds/ that links back to children. Extractive summarization (no invention). Dry-run by default, stdout-only; commit mode writes and accepts that the PostToolUse hook auto-commits. Triggers on: fold the log, run a fold, run wiki-fold, log rollup, roll up log entries."
=======
description: "Create a bounded, extractive, structurally idempotent rollup of recent Obsidian wiki log entries, with dry-run preview by default and one optional transaction apply. Use for manual log compression without modifying child pages. Triggers: fold the log, run a fold, run wiki-fold, log rollup, roll up log entries, commit the fold."
>>>>>>> 1c1bc49c03a685ee8f5d09c99efe52b42d6673f5
---

# Extractive log fold

Create an additive rollup of raw `wiki/log.md` entries. Never modify, move, or
delete child entries or their pages. Do not perform fold-of-folds or trigger a
fold automatically.

Resolve the portable core from this skill's installation. Resolve the user vault
by explicit `--vault`, `CLAUDE_OBSIDIAN_VAULT`, workspace config, then
current-directory discovery. Never treat the plugin/product root as a vault.

```bash
PRODUCT_ROOT=/absolute/path/to/installed/claude-obsidian
CORE="$PRODUCT_ROOT/scripts/claude-obsidian.py"
test -f "$CORE"
```

This skill needs no network egress. Do not call external services.

## Select a bounded range

Use batch exponent `k` with size `2^k`; default to `k=4`. An explicit entry range
may override it. If fewer entries exist than requested, report the shortfall and
stop rather than folding a partial batch.

Read the selected log entries completely. Read referenced child pages only when
the log lacks enough context: target 0-10 reads, hard ceiling 15. Missing pages
remain explicit `page_missing` records.

Derive the structural ID only from inputs:

```text
fold-k{K}-from-{EARLIEST-DATE}-to-{LATEST-DATE}-n{COUNT}
```

If `wiki/folds/{FOLD_ID}.md` already exists, return a no-op. Replacing it requires
an explicit force request and a separately reviewed `replace` proposal.

## Draft extractively

Follow [fold-template.md](references/fold-template.md). Every child log entry must
have one deterministic `child_key` in frontmatter and exactly one matching row
in the Child Entries table. Do not deduplicate children by page, although the
final Child Pages link list may be deduplicated.

Every outcome must name its source entry. Every number must be verifiable in the
selected entry. A cross-entry theme must name at least two contributing entries.
Prefer `ambiguous in source` or `source missing` to invention. When a child page
and log entry disagree, preserve both and identify the mismatch; the log entry is
the fold's primary source.

Run these checks before proposing any write:

- deterministic ID and exact entry count;
- frontmatter/table bijection;
- numeric traceability;
- source citation for every outcome and theme;
- no change to a child, source, source ledger, or claim ledger.

<<<<<<< HEAD
If fewer than `2^k` **uncovered** log entries exist, report the shortfall and stop. Do not silently fold a partial batch.
=======
A fold adds no new factual evidence, so it does not upgrade claim assessments or
create source records. Report discovered contradictions for later review instead
of editing canonical claims.
>>>>>>> 1c1bc49c03a685ee8f5d09c99efe52b42d6673f5

## Preview by default

Return the complete fold draft, ID, child range, read budget, and proposed changed
paths without modifying the vault. Parallel agents may check child entries and
return extracts, but only the orchestrator assembles the fold; workers never
write.

<<<<<<< HEAD
### 1. Parse log entries — and subtract what earlier folds already cover

**A fold is additive, so the newest entries are the ones the previous fold already folded.** Children stay in `log.md`; nothing is moved or deleted. Taking `head -{2^k}` is therefore correct only for a vault's FIRST fold. On the second run it re-folds the same entries, producing two fold pages that claim the same children.

List every heading, then subtract the covered ones:

```
# every log entry, newest first
grep -n "^## \[" wiki/log.md

# what previous folds already cover: each fold's children[].title
grep -h '^    title:' wiki/folds/*.md 2>/dev/null
```

An entry is **covered** when its heading title appears as a `children[].title` in any fold page. Two further exclusions:

- A fold's own log entry (`## [DATE] fold | …`) is bookkeeping, not a foldable entry — folding it nests a fold inside a fold.
- Titles are compared verbatim. If a fold recorded a paraphrased title, matching fails and its children look uncovered — see the verbatim rule in step 4, which exists for exactly this reason.

From the uncovered set, take the **oldest contiguous run** of `2^k` entries. Oldest, because a rollup should compress history and leave recent entries readable in the raw log. Contiguous, because a fold whose children are scattered across the log is far harder to reason about than one that tiles a span — with successive folds tiling, any log position belongs to at most one fold.

Sanity check before proceeding: `covered + uncovered` must equal the total heading count minus the fold entries. If it does not, a fold's `children[].title` has drifted from its heading and coverage is being under-counted — fix the fold page before folding anything new.

Record for each selected entry: line number, date, operation, title, and the following bullet lines until the next `## [` or end-of-section.
=======
When the user explicitly says to apply or commit the fold, build one
`claude-obsidian.transaction.v1` bundle with `operation_type: fold`. Read
[the transaction contract](../wiki/references/operation-transactions.md). Couple:

- `wiki/folds/{FOLD_ID}.md` in `create` mode by default;
- the fold catalog entry in `wiki/index.md`;
- one new top-of-file fold entry in `wiki/log.md`.

Do not update `wiki/hot.md`. Record SHA-256 preconditions for all three targets.
Do not use host Write/Edit, Obsidian transport writes, deprecated locks, automatic
commits, or one apply per file.

Inspect before the single apply:

```bash
python3 "$CORE" transaction inspect /path/to/fold-bundle.json --vault /path/to/vault
# Set APPROVAL_SHA256 to the inspect result's approval_sha256 after review.
python3 "$CORE" transaction apply /path/to/fold-bundle.json --vault /path/to/vault \
  --approved-plan-sha256 "$APPROVAL_SHA256"
```

Report the operation ID and exact changed paths. The identical bundle and ID are
idempotent. On exit 75, re-read and rebuild; after interruption, use
`transaction recover`.
>>>>>>> 1c1bc49c03a685ee8f5d09c99efe52b42d6673f5

Git history is a separate optional action:

```bash
python3 "$CORE" checkpoint OPERATION_ID --vault /path/to/vault
```

<<<<<<< HEAD
One record per log entry. Do not dedupe by page: if two entries both point to `[[DragonScale Memory]]`, both records appear, distinguishable by date and title.

### 3. Read referenced pages (bounded)

Read only the pages that are not already captured fully in the log entry's bullets. Budget: 0-10 page reads. Hard ceiling: 15. If an entry's referenced page is missing, record `page_missing: true` and proceed.

### 4. Extractive summarization with count checks

Write the fold body per `references/fold-template.md`. **Rules**:

- **Extractive only.** Every outcome bullet and theme bullet must cite a specific child entry (e.g., `(from 2026-04-14 session)`) or a quoted line from that entry. Do not introduce events, counts, or interpretations not present in a child entry.
- **Log entry is the primary source.** If the log entry's bullets and the referenced meta-page disagree on a fact (e.g., a count), prefer the log-entry bullets and flag the mismatch as "source mismatch: log says X, meta says Y."
- **Count checks.** If you write "N concept pages" or "M repos updated," grep the source entries for the number and verify. Numeric mismatches are dry-run blockers.
- **No merging across entries without naming them.** A theme that spans multiple entries must name each contributing entry inline.
- **Uncertainty is a feature.** If an entry is ambiguous, say "ambiguous in source: [[Entry]]" rather than picking one interpretation.

### 5. Self-check before emitting

Before printing output, verify:
- Every child in `children:` frontmatter appears exactly once in the Child Entries table.
- Every entry in the table appears in the `children:` frontmatter.
- Every `children[].title` is the log heading **verbatim** — byte-for-byte, including quotation marks, arrows and any trailing clause. Not "close enough". This is what step 1 matches on to decide coverage, so a paraphrase makes those children look unfolded forever and invites a second fold over the same entries. Grep each title back against `wiki/log.md` and require a hit.
- No selected entry is already a child of an existing fold (step 1's subtraction, re-verified here — the two are cheap and disagree loudly when one is wrong).
- Every numeric claim in Key Outcomes is grep-verifiable against a child entry.
- The fold ID is deterministic and the file does not already exist (or `--force` is set).

If any check fails, abort and report the specific failure.

### 6. Emit

**Dry-run**: use Bash `cat <<'EOF' ... EOF` to stdout. Do not use Write. Print the fold ID and a one-line summary of what the commit step would do.

**Commit** (only after user says "commit the fold"):
1. `Write` the fold page to `wiki/folds/{FOLD-ID}.md`. (PostToolUse hook will auto-commit this.)
2. `Edit` `wiki/index.md` to add the fold link under a `## Folds` section (create section if missing). (Hook auto-commits.)
3. `Edit` `wiki/log.md` to prepend one entry (OKF §7 format — date-only heading, newest first; add the bullet under today's `## YYYY-MM-DD` heading if it's already topmost, else insert a new one):
   ```
   ## YYYY-MM-DD
   * **fold**: batch-exponent-k{K} rollup of N entries — Location: wiki/folds/{FOLD-ID}.md; Range: {EARLIEST-DATE} to {LATEST-DATE}; Children: N log entries
   ```
   (Hook auto-commits.)

Three auto-commits result. The user sees three separate `wiki: auto-commit` entries in git log. This is expected; do not attempt to suppress the hook.

---

## Output schema

See `references/fold-template.md` for the canonical frontmatter and body layout.

---

## Invariants

1. **Structural idempotency**: same range + same k → same fold ID → duplicate detection prevents double-writes. LLM prose may vary across runs; the *location and scope* are fixed.
2. **Folds partition the log**: every entry is a child of at most one fold. Guaranteed by step 1 subtracting existing coverage before selecting, NOT by the fold ID check — two folds over different-but-overlapping ranges have different IDs, so the ID check alone would happily write both.
3. **Additive**: children are never modified.
4. **Bounded reads**: 0-15 child-page reads per fold.
5. **Extractive**: zero invented facts. Count checks enforced.
6. **No chaining**: wiki-fold does not invoke wiki-lint, wiki-ingest, autoresearch, or save.

---

## What NOT to do

- Do not use Write/Edit during dry-run. Bash stdout only.
- Do not include the current date in the fold filename or title. Use the child entry range.
- Do not silently dedupe children by page title. One record per log entry.
- Do not write "emergent themes" that span entries without naming which entries contribute.
- Do not claim byte-identical idempotency. Structural idempotency is the actual guarantee.
- Do not suppress or bypass the PostToolUse auto-commit hook.
- Do not update `wiki/hot.md`. Ownership stays with save/ingest skills.

---

## Reversal

Committed fold reversal (three commits, land in this order):
1. Remove the log.md fold entry.
2. Remove the index.md entry.
3. Delete the fold page file.

Or: `git revert` the three auto-commits. Child pages are untouched in either path.

---

## Example dry-run sequence

User: "fold the log, dry-run k=3"

1. Parse `wiki/log.md` top 8 entries.
2. Build structured children list (8 records).
3. Read 0-10 referenced pages as needed.
4. Produce fold ID: `fold-k3-from-2026-04-10-to-2026-04-23-n8`.
5. Check `wiki/folds/fold-k3-from-2026-04-10-to-2026-04-23-n8.md` does not exist.
6. Write fold body following the template.
7. Run self-check (frontmatter/table consistency, count verification).
8. Emit via `cat <<'EOF' ... EOF` to stdout.
9. Report: "Dry-run complete. Fold ID: {FOLD-ID}. To commit: 'commit the fold'."

---

## How to think (10-principle mapping)

When working on this skill, apply the 10-principle loop. See [`skills/think/SKILL.md`](../think/SKILL.md) for the canonical framework.

| # | Principle | Application here |
|---|-----------|-------------------|
| 1 | OBSERVE (ext) | Read the last 2^k log entries FULLY. Skimming defeats extractive summarization. |
| 2 | OBSERVE (int) | Am I tempted to synthesize beyond what the child entries support? Extractive-only is the binding rule. |
| 3 | LISTEN | Which themes emerge naturally from the child entries? Don't impose themes from outside the children. |
| 4 | THINK | Extractive only. Every outcome must be traceable to a specific child entry. Count check at the end. |
| 5 | CONNECT (lat) | Cross-entry patterns ARE the value-add. The single-entry view misses these. |
| 6 | CONNECT (sys) | DragonScale Mechanism 1 + wiki-lock + address allocator. Folds are part of the memory architecture. |
| 7 | FEEL | A good fold lets future-me skim a year of work in 5 minutes. Aim for that compression. |
| 8 | ACCEPT | Dry-run first. Commit only when the self-check passes. Honor the bounded-scope constraint (no fold-of-folds yet). |
| 9 | CREATE | Fold page at `wiki/folds/<fold-id>.md` linking to all child entries. |
| 10 | GROW | Fold-of-folds (hierarchical level-stacking) is v_next scope — note as you encounter it, don't sneak it in. |
=======
Observe all selected entries, verify traceability and counts, then grow the
rollup only from what its children actually say.
>>>>>>> 1c1bc49c03a685ee8f5d09c99efe52b42d6673f5
