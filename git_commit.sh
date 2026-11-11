#!/bin/bash
#
# git_commit.sh - Update the yearly changelog and create a commit.
#
# Usage:
#   1. Copy LastChanges.example.md to LastChanges.md (or let this script
#      create it on the first run).
#   2. Write the changes for the next commit in LastChanges.md.
#   3. Run ./git_commit.sh from the project directory.
#
# The script:
#   - Prepends a dated entry to ChangeLog<YYYY>.md.
#   - Regenerates CHANGELOG.md as an index of the yearly files.
#   - Commits all changes with LastChanges.md as the commit message.
#   - Clears LastChanges.md on success.
#
# LastChanges.md is ignored by Git. See LastChanges.example.md for a template.
#
# WARNING: This script runs "git add ." and commits everything in the current
# directory and its subdirectories. Make sure the working tree only contains
# the changes you want to commit.

set -u

# --- CONFIGURATION ---
LAST_CHANGES="./LastChanges.md"
LAST_CHANGES_EXAMPLE="./LastChanges.example.md"
INDEX="./CHANGELOG.md"
YEAR=$(date +%Y)
CHANGELOG="./ChangeLog${YEAR}.md"
DATE=$(date +"%Y-%m-%d %H:%M")

TEMP_MSG=""
TEMP_LOG=""
TEMP_TITLE=""
BACKUP_DIR=""

# --- HELPERS ---
die() {
    echo "Error: $*" >&2
    exit 1
}

cleanup() {
    if [ -n "$TEMP_MSG" ]; then
        rm -f "$TEMP_MSG"
    fi

    if [ -n "$TEMP_LOG" ]; then
        rm -f "$TEMP_LOG"
    fi

    if [ -n "$TEMP_TITLE" ]; then
        rm -f "$TEMP_TITLE"
    fi

    if [ -n "$BACKUP_DIR" ]; then
        rm -rf "$BACKUP_DIR"
    fi
}

trap cleanup EXIT

# --- 1. CHECK GIT WORK TREE ---
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    die "not inside a Git work tree. Move to the project directory first."
fi

# --- 2. CHECK LAST CHANGES DRAFT ---
if [ ! -f "$LAST_CHANGES" ]; then
    if [ -f "$LAST_CHANGES_EXAMPLE" ]; then
        cp "$LAST_CHANGES_EXAMPLE" "$LAST_CHANGES"
        echo "Created $LAST_CHANGES from $LAST_CHANGES_EXAMPLE."
        echo "Write the changes for this commit and run the script again."
        exit 1
    fi

    die "$LAST_CHANGES does not exist. Create it with the changes for this commit."
fi

if ! grep -q '[^[:space:]]' "$LAST_CHANGES"; then
    die "$LAST_CHANGES is empty. Write the changes for this commit first."
fi

# --- 3. CLEAN THE DRAFT ---
# Remove HTML comments (single-line and multi-line) and leading blank lines.
TEMP_MSG=$(mktemp)
sed -e 's/<!--.*-->//g' "$LAST_CHANGES" \
    | sed '/<!--/,/-->/d' \
    | sed '/./,$!d' > "$TEMP_MSG"

if ! grep -q '[^[:space:]]' "$TEMP_MSG"; then
    die "$LAST_CHANGES has no content after removing HTML comments."
fi

FIRST_LINE=$(head -n 1 "$TEMP_MSG")
case "$FIRST_LINE" in
    TODO:*)
        die "replace the TODO placeholder in $LAST_CHANGES before committing."
        ;;
esac

# --- 4. BACK UP FILES ---
BACKUP_DIR=$(mktemp -d)
CHANGELOG_EXISTED=0
INDEX_EXISTED=0

if [ -f "$CHANGELOG" ]; then
    cp "$CHANGELOG" "$BACKUP_DIR/changelog"
    CHANGELOG_EXISTED=1
fi

if [ -f "$INDEX" ]; then
    cp "$INDEX" "$BACKUP_DIR/index"
    INDEX_EXISTED=1
fi

restore() {
    if [ "$CHANGELOG_EXISTED" -eq 1 ]; then
        cp "$BACKUP_DIR/changelog" "$CHANGELOG"
    else
        rm -f "$CHANGELOG"
    fi

    if [ "$INDEX_EXISTED" -eq 1 ]; then
        cp "$BACKUP_DIR/index" "$INDEX"
    else
        rm -f "$INDEX"
    fi

    # Unstage the changelog files so the index matches the restored tree.
    git reset -- "$CHANGELOG" "$INDEX" >/dev/null 2>&1 || true
}

# --- 5. UPDATE THE YEARLY CHANGELOG ---
if [ ! -f "$CHANGELOG" ]; then
    printf '# ChangeLog %s\n\n' "$YEAR" > "$CHANGELOG"
else
    FIRST_FILE_LINE=$(head -n 1 "$CHANGELOG")
    case "$FIRST_FILE_LINE" in
        '# '*)
            ;;
        *)
            TEMP_TITLE=$(mktemp)
            printf '# ChangeLog %s\n\n' "$YEAR" > "$TEMP_TITLE"
            cat "$CHANGELOG" >> "$TEMP_TITLE"
            mv "$TEMP_TITLE" "$CHANGELOG"
            TEMP_TITLE=""
            ;;
    esac
fi

TEMP_LOG=$(mktemp)
{
    # Keep the title (first line), then insert the new entry.
    head -n 1 "$CHANGELOG"
    echo ""
    echo "## $DATE"
    echo ""
    cat "$TEMP_MSG"
    echo ""
    # Append the previous entries, dropping leading blank lines.
    tail -n +2 "$CHANGELOG" | sed '/./,$!d'
} > "$TEMP_LOG"
mv "$TEMP_LOG" "$CHANGELOG"
TEMP_LOG=""

# --- 6. REGENERATE THE INDEX ---
{
    echo "# CHANGELOG"
    echo ""
    for f in $(ls -1 ChangeLog[0-9][0-9][0-9][0-9].md 2>/dev/null | sort -r); do
        y=$(basename "$f" .md | sed 's/^ChangeLog//')
        echo "- [$y]($f)"
    done
} > "$INDEX"

echo "Updated $CHANGELOG and $INDEX."

# --- 7. COMMIT ---
git add .

if git commit -F "$TEMP_MSG"; then
    echo "Commit created successfully."
    > "$LAST_CHANGES"
    echo "Cleared $LAST_CHANGES."
else
    echo "Git commit failed. Restoring changelog files." >&2
    restore
    exit 1
fi

echo
echo "If you are in a base repository, run: git push"
echo "If you are in a submodule, run: git push origin [master|main]"
