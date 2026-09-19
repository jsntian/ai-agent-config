## Context Curation

Full contract: `.trellis/spec/guides/context-curation.md` (authoritative; these bullets are an entry point only).

- A Spec leaf defines one independently applicable contract. Split it when a plausible task may need one contract without needing another.
- Layer `index.md` files are routers only: applicability, leaf links, and validation entry points. They must not duplicate leaf content.
- Complex research uses `index.md`, a concise `*-summary.md`, and full evidence under `research/evidence/`.
- Task `implement.jsonl` and `check.jsonl` reference exact Spec leaves and Research summaries only; they must never reference `AGENTS.md`, Spec or Research indexes, or `research/evidence/*`.
- Read full evidence only to challenge a conclusion, resolve a conflict, or investigate an unresolved question.
