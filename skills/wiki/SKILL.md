---
name: wiki
description: "Initialize, adopt, and route work for a separate Obsidian knowledge vault through the portable claude-obsidian core. Use for vault setup, scaffolding, workspace selection, cross-project configuration, or choosing the correct wiki sub-skill. Triggers: /wiki, set up wiki, scaffold vault, create knowledge base, adopt this vault, Obsidian vault, second brain setup, persistent wiki."
---

# Wiki orchestration

Treat the installed product as code and the selected user vault as data. Never use
the plugin/product root as a vault, even when the current directory happens to be
the product checkout.

Resolve the portable core from this skill's installation and invoke it by absolute
path:

```bash
CORE=/absolute/product/root/scripts/claude-obsidian.py
python3 "$CORE" --help
```

Resolve a vault in this order: explicit `--vault`,
`CLAUDE_OBSIDIAN_VAULT`, the nearest `.claude-obsidian.json`, then an
unambiguous initialized vault at or above the current directory. Fail closed when
selection is missing or ambiguous.

<<<<<<< HEAD
```
wiki/
├── index.md            # master catalog of all pages
├── log.md              # chronological record of all operations
├── hot.md              # hot cache: recent context summary (vault-declared budget, default ~500 words)
├── overview.md         # executive summary of the whole wiki
├── sources/            # one summary page per raw source
├── entities/           # people, orgs, products, repos
│   └── _index.md
├── concepts/           # ideas, patterns, frameworks
│   └── _index.md
├── domains/            # top-level topic areas
│   └── _index.md
├── comparisons/        # side-by-side analyses
├── questions/          # filed answers to user queries
└── meta/               # dashboards, lint reports, conventions
=======
Baseline setup requires no network egress. Do not fetch templates, plugins, or
remote content unless the user separately approves the destinations and budget.

## Set up a vault

Use the deterministic setup commands. Both are dry-run by default.

For a new, separate vault:

```bash
python3 "$CORE" init /absolute/path/to/vault \
  --generated-at <ISO-UTC> --operation-id init-reviewed
python3 "$CORE" init /absolute/path/to/vault \
  --generated-at <ISO-UTC> --operation-id init-reviewed \
  --approved-plan-sha256 <reviewed-sha256> --apply
>>>>>>> 1c1bc49c03a685ee8f5d09c99efe52b42d6673f5
```

For an existing Obsidian vault:

<<<<<<< HEAD
---

## Hot Cache

`wiki/hot.md` is a short summary of the most recent context. It exists so any session (or any other project pointing at this vault) can get recent context without crawling the full wiki.

**Budget: whatever the vault declares, default ~500 words.** If the vault's `CLAUDE.md` states a
budget, that number wins — check it before trimming. The ceiling is not about token cost (a
thousand words is immaterial against a session's context window); it exists so the cache cannot
grow into a second log, which the vault already has in `log.md`. A vault carrying many durable
rules may legitimately declare a larger budget; hold the declared one rather than trimming to this
default and evicting something load-bearing.

Update hot.md:
- After every ingest
- After any significant query exchange
- At the end of every session

Format:
```markdown
---
type: meta
title: "Hot Cache"
description: "Rolling summary of the most recent vault context."
updated: YYYY-MM-DDTHH:MM:SS
timestamp: YYYY-MM-DDTHH:MM:SS
---

# Recent Context

## Last Updated
YYYY-MM-DD. [what happened]

## Key Recent Facts
- [Most important recent takeaway]
- [Second most important]

## Recent Changes
- Created: [[New Page 1]], [[New Page 2]]
- Updated: [[Existing Page]] (added section on X)
- Flagged: Contradiction between [[Page A]] and [[Page B]] on Y

## Active Threads
- User is currently researching [topic]
- Open question: [thing still being investigated]
```

Keep it within the vault's declared budget (default ~500 words — see Hot Cache above). It is a cache, not a journal. Overwrite it completely each time.
=======
```bash
python3 "$CORE" adopt /absolute/path/to/vault \
  --generated-at <ISO-UTC> --operation-id adopt-reviewed
python3 "$CORE" adopt /absolute/path/to/vault \
  --generated-at <ISO-UTC> --operation-id adopt-reviewed \
  --approved-plan-sha256 <reviewed-sha256> --apply
```

Before `--apply`, show the selected path and changed-path preview, then pass
the emitted `approved_plan_sha256` unchanged. Do not use
`--force` unless the user has reviewed the conflicts and explicitly approved
replacement. Setup is non-destructive by default and creates no upstream Git
remote.
>>>>>>> 1c1bc49c03a685ee8f5d09c99efe52b42d6673f5

If the user asks for a domain-specific scaffold, establish the baseline first,
then read [modes.md](references/modes.md). Draft the additional pages and
configuration as one operation-level transaction. Never mutate vault files with
host Write/Edit tools or an Obsidian transport.

## Route operations

Route the user's intent without silently broadening it:

| Intent | Skill |
|---|---|
| Ingest supplied sources | `wiki-ingest` |
| Answer from existing vault knowledge | `wiki-query` |
| Save a specific conversation result | `save` |
| Research the public web under a budget | `autoresearch` |
| Check vault health | `wiki-lint` |
| Roll up log entries | `wiki-fold` |
| Work with a canvas | `canvas` |

Query is read-only. Persistence from a query must be an explicit, separately
scoped Save operation. Never capture a transcript or update the hot cache merely
because a session ended.

## Mutation contract

Read [operation-transactions.md](references/operation-transactions.md) before
any custom scaffold or mutation. One logical operation must produce one inspected
and recoverable `claude-obsidian.transaction.v1` bundle. Parallel agents may
return drafts and evidence only; the orchestrator merges them and applies once.
Every canonical page create or removal includes an active index or MOC update
in that bundle; update the overview only when the stable high-level picture
changed. Raw source payloads are create-only. There are no automatic commits.

Use [provenance.md](references/provenance.md) when initializing or changing
source and claim ledgers. Unsupported evidence stays unsupported; never invent a
source, quote, date, locator, or confidence.

After a successful apply, report the operation ID and exact changed paths. If the
user explicitly wants a Git checkpoint, run it separately:

```bash
python3 "$CORE" checkpoint OPERATION_ID --vault /absolute/path/to/vault
```

On a conflict, re-read and rebuild. On interruption, use `transaction recover`.
Reuse an operation ID only with the identical bundle.

## Installation context

Read [install-modes.md](references/install-modes.md) when installation or host
behavior matters. Hooks are optional adapters; portable behavior lives in the
core and skills.

## Conditional references

Read only the reference needed for the current request:

<<<<<<< HEAD
When you need context not already in this project:
1. Read wiki/hot.md first (recent context, one short page)
2. If not enough, read wiki/index.md (full catalog)
3. If you need domain specifics, read wiki/<domain>/_index.md
4. Only then read individual wiki pages
=======
- [frontmatter.md](references/frontmatter.md) when defining or adopting a
  property schema;
- [css-snippets.md](references/css-snippets.md) for requested Obsidian visual
  customization;
- [git-setup.md](references/git-setup.md) for explicit local Git or checkpoint
  setup;
- [plugins.md](references/plugins.md) when evaluating optional Obsidian
  integrations;
- [mcp-setup.md](references/mcp-setup.md) when the user asks to evaluate an
  external read transport;
- [rest-api.md](references/rest-api.md) only when the user explicitly has or
  requests the Local REST API adapter.
>>>>>>> 1c1bc49c03a685ee8f5d09c99efe52b42d6673f5

## Think, verify, grow

Before applying, pause once: observe existing state, verify the vault selection
and evidence, then choose the smallest reversible operation that satisfies the
request. Afterward, report uncertainty and the next useful improvement without
performing it automatically.
