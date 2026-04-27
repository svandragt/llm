#!/usr/bin/env bash
# Symlink every skill in this repo into ~/.claude/skills/ so Claude Code
# discovers them globally, without taking over the whole directory.
# Idempotent. Refuses to clobber existing real dirs or foreign symlinks
# so third-party tool-installed skills and links to other source repos
# can coexist.
set -euo pipefail

repo_skills="$(cd "$(dirname "$0")/.." && pwd)/skills"
target_dir="${HOME}/.claude/skills"
mkdir -p "$target_dir"

conflicts=0
linked=0
for src in "$repo_skills"/*/; do
    name="$(basename "$src")"
    link="$target_dir/$name"
    want="$repo_skills/$name"
    if [ -L "$link" ]; then
        if [ "$(readlink "$link")" = "$want" ]; then
            continue
        fi
        echo "skip $name (symlink to $(readlink "$link"))"
        conflicts=$((conflicts + 1))
    elif [ -e "$link" ]; then
        echo "skip $name (real path exists at $link)"
        conflicts=$((conflicts + 1))
    else
        ln -s "$want" "$link"
        echo "linked $name"
        linked=$((linked + 1))
    fi
done

echo "done: $linked linked, $conflicts skipped"
exit "$conflicts"
