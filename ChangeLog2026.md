# ChangeLog 2026

## 2026-11-11 03:37

Add per-year changelog and commit helper script

### `git_commit.sh`
- Translate the script to English.
- Write entries to `ChangeLog<YYYY>.md` and regenerate `CHANGELOG.md`
  as the yearly index.
- Strip HTML comments from the draft before using it as the commit
  message and changelog entry.
- Back up and restore the changelog files if the commit fails.
- Check for a Git work tree with `git rev-parse --is-inside-work-tree`,
  so the script also works from submodules and subdirectories.
- Keep `LastChanges.md` on failure and clear it only after a successful
  commit.

### `.gitignore`
- Ignore the local `LastChanges.md` draft.

### `LastChanges.example.md`
- Add the changelog entry template and instructions.

### `CHANGELOG.md`, `ChangeLog2026.md`
- Add the changelog index and the initial yearly file.

### `README.md`
- Document the development process and the changelog workflow.

