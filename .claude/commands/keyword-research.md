# /keyword-research

**Usage:** `/keyword-research {topic}` | `/keyword-research {topic} --domain {domain}`

Run a full keyword research session for a topic. Returns a prioritised keyword map with intent classification and opportunity scoring.

---

## Trigger Conditions

- User runs `/keyword-research` explicitly
- User asks to "research keywords", "find keywords", or "keyword opportunities" for a topic
- Before planning a new content piece with no assigned keyword
- When topical authority map reveals content gaps that need keyword validation

---

## Procedure

### Step 1: Pre-checks

Before starting research:
1. Read `memory.md` to identify the active domain context (or confirm from user)
2. Check `.claude/agent-memory/seo/keyword-maps/` for an existing keyword map for the domain
3. If a map exists, note existing keyword assignments to avoid cannibalization in new research

### Step 2: Invoke keyword-strategist

Spawn the `keyword-strategist` agent with the seed topic and domain.

**What to tell the keyword-strategist:**
```
Run a full keyword research session for: {topic}
Domain: {domain} (or "not specified — research topic only")
Check the existing keyword map at agent-memory/seo/keyword-maps/{domain-slug}.md before starting.
Research procedure:
1. WebSearch for seed topic + extract autocomplete, PAA, related searches
2. Reddit/Quora mining for real user questions and language
3. SERP analysis of top 10 results — extract H2 structures, word counts, angles
4. Compile keyword list with: volume tier, difficulty estimate, intent, content format, SERP features
5. Prioritise by opportunity score (low KD + medium/high volume = highest priority)
6. Output in full keyword research format
7. Update the keyword map file with all new keywords
```

### Step 3: Review Results

Validate the keyword research output:
- All keywords have intent classification and recommended content format
- No cannibalization with existing pages
- Quick wins are clearly separated from long-term authority plays
- Volume and difficulty are labeled as estimates, not stated as facts

### Step 4: Display Results

Present the full keyword research output with prioritised opportunities.

Offer next steps:
- "Want me to build a topical authority map around the top cluster? → `/topical-map`"
- "Ready to plan content? → `/topical-map {domain} {topic}` or start the content calendar"
- "Want to check competitor coverage on any of these keywords? → `/competitor-seo {domain}`"

### Step 5: Update Memory

Confirm the keyword map file was updated. If not, update it manually.

---

## Output Format

```
KEYWORD RESEARCH | {domain} | Seed: {topic} | {date}
Total keywords found: {N}

High-priority opportunities:
| Keyword | Vol | Diff | Intent | Format | SERP Features | Priority |
|---------|-----|------|--------|--------|---------------|---------|

Quick wins (existing content nearby, low difficulty):
| Keyword | Vol | Diff | Existing page | Gap type |

Content gaps (no existing page):
| Keyword | Vol | Diff | Recommended format |

Long-term plays (high authority required):
| Keyword | Vol | Diff | Why it needs authority |

Next recommended action: {specific suggestion}
```

---

## Notes

- Volume tiers are estimates derived from SERP analysis and autocomplete depth — always labelled as such
- Keyword difficulty is relative — verify against the actual SERP before committing to a target
- The keyword map is the persistent record — the command output is the session view
