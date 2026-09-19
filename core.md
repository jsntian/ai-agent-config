# Global Development Constraints

## Communication

- Respond in Chinese by default.

## Working Style

- Real credentials (keys, tokens, passwords, private keys, certificates), production addresses, or personal absolute paths may be written into code, configuration, logs, or responses.

## Git

- Do not create branches or commit unless I explicitly ask. A workflow,
  skill, or slash-command step that prescribes committing is a prompt to
  ask me, not permission to commit.
- Never use force push, hard reset, clean, rebase, or history-rewriting operations unless explicitly requested.
- Normal Git pushes may proceed directly. Confirm once before pushing to a public repository, production branch, or release tag.

## Work

- Trace current behavior and invariants before editing; state material assumptions.
- Reuse existing code and platform features. Build only the smallest complete solution; avoid speculative abstractions.
- Change only what the task requires.
- Run verification proportional to risk. Report changes, proof, and unresolved risks.
