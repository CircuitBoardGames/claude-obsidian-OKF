# Frontmatter conventions

Preserve an existing vault's valid property vocabulary. For a new generic
claude-obsidian page, use flat YAML properties, block lists, and explicit
evidence fields where they apply.

## Common properties

```yaml
---
<<<<<<< HEAD
type: <source|entity|concept|domain|comparison|question|overview|meta>
title: "Human-Readable Title"
description: "One-sentence summary of what this page covers."
created: 2026-04-07
updated: 2026-04-07
timestamp: 2026-04-07T00:00:00
=======
type: concept
title: "Human-readable title"
created: YYYY-MM-DD
updated: YYYY-MM-DD
status: developing
>>>>>>> 1c1bc49c03a685ee8f5d09c99efe52b42d6673f5
tags:
  - concept
related:
  - "[[Related page]]"
sources:
  - "[[Source page]]"
claim_ids:
  - claim-example
---
```

<<<<<<< HEAD
`type`, `title`, `description`, and `timestamp` are the fields the vault's
Open Knowledge Format (OKF v0.1) conformance check (`type`) and recommended
set (`title`, `description`, `tags`, `timestamp`) look for — see
`skills/wiki/references/okf-conformance.md`. Never omit them, even on
generated/report pages.

**status values:**
- `seed`: exists, barely populated
- `developing`: has real content, not yet complete
- `mature`: comprehensive, well-linked
- `evergreen`: unlikely to need updates
=======
Core generated page types are `source`, `entity`, `concept`, `comparison`,
`question`, `overview`, and `meta`. A custom scaffold may add types when its
schema is documented. `status` commonly progresses through `seed`,
`developing`, `mature`, and `evergreen`; preserve other established values in
an adopted vault.
>>>>>>> 1c1bc49c03a685ee8f5d09c99efe52b42d6673f5

## Source properties

```yaml
source_type: article
author: ""
date_published: YYYY-MM-DD
url: ""
source_id: ""
sha256: ""
authority: unknown
independence_key: ""
review_state: unreviewed
key_claims:
  - "No claims extracted yet."
```

Allowed authority values and evidence semantics are defined in
[provenance.md](provenance.md). A missing value remains empty or `unknown`; do
not manufacture metadata to complete a form.

## Other type-specific properties

```yaml
# entity
entity_type: organization
role: ""
first_mentioned: "[[Source page]]"

# concept
complexity: intermediate
domain: ""
aliases:
  - Alternative name

# comparison
subjects:
  - "[[Thing A]]"
  - "[[Thing B]]"
dimensions:
  - cost
  - reliability
assessment: provisional
risk: low

# question
question: "What is being asked?"
assessment: unsupported
risk: low
```

## Rules

<<<<<<< HEAD
1. Use flat YAML only. Never nest objects.
2. `created`/`updated` are `YYYY-MM-DD` strings, not ISO datetime — `timestamp` is the one field that carries full ISO 8601 (`YYYY-MM-DDTHH:MM:SS`).
3. Lists always use the `- item` format, not inline `[a, b, c]`.
4. Wikilinks in YAML fields must be quoted: `"[[Page Name]]"`.
5. Keep `related` and `sources` as wikilinks, not plain URLs.
6. Update `updated` and `timestamp` every time you edit the page content.
7. Always write `description` — a one-sentence summary, not a restatement of `title`.
=======
1. Keep generated properties flat; do not introduce nested mappings.
2. Write dates as `YYYY-MM-DD` unless an existing schema requires a timestamp.
3. Use block lists for generated multi-value properties.
4. Quote wikilinks in YAML.
5. Keep external locators on source records; use wikilinks for internal
   `related` and `sources` relationships.
6. Update `updated` only when the page content or assessed state changes.
7. Preserve unknown valid properties during an edit.
8. Do not treat a frontmatter confidence label as evidence; the claim ledger
   and linked active sources determine support.
9. Quote numeric-only tag values, for example `- "2026"`, so their YAML type
   remains text.
>>>>>>> 1c1bc49c03a685ee8f5d09c99efe52b42d6673f5
