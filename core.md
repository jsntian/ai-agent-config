# Global Development Constraints

## Communication

- Respond in Chinese by default.

## Security

- Real credentials must never be committed to version control or included in logs or responses. Store them only in local, untracked secret storage or environment configuration.
- Do not commit production addresses or machine-specific absolute paths.

## Git

- Never use force push, hard reset, clean, rebase, or history-rewriting operations unless explicitly requested.
- Normal Git pushes may proceed directly. Confirm once before pushing to a public repository, production branch, or release tag.

## Work

- Trace current behavior and invariants before editing; state material assumptions.
- Reuse existing code and platform features. Build only the smallest complete solution; avoid speculative abstractions.
- Change only what the task requires.
- Run verification proportional to risk. Report changes, proof, and unresolved risks.
