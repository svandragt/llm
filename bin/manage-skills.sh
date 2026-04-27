#!/usr/bin/env bash
# Interactive TUI to enable/disable skills from this repo in ~/.claude/skills/.
# Enabling = create symlink ~/.claude/skills/<name> -> ~/dev/llm/skills/<name>.
# Disabling = remove that symlink. Real directories or symlinks pointing
# elsewhere (foreign sources) are left untouched.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
repo_skills="$repo/skills"
target_dir="$HOME/.claude/skills"
mkdir -p "$target_dir"

self="$0"

cmd_list() {
    for src in "$repo_skills"/*/; do
        name=$(basename "$src")
        want="$repo_skills/$name"
        link="$target_dir/$name"
        if [ -L "$link" ]; then
            if [ "$(readlink "$link")" = "$want" ]; then
                printf "[x] %s\n" "$name"
            else
                printf "[!] %s (foreign symlink)\n" "$name"
            fi
        elif [ -e "$link" ]; then
            printf "[!] %s (real dir)\n" "$name"
        else
            printf "[ ] %s\n" "$name"
        fi
    done
}

cmd_toggle() {
    name="$1"
    link="$target_dir/$name"
    want="$repo_skills/$name"
    if [ -L "$link" ]; then
        if [ "$(readlink "$link")" = "$want" ]; then
            rm "$link"
        fi
    elif [ ! -e "$link" ]; then
        ln -s "$want" "$link"
    fi
}

cmd_preview() {
    f="$repo_skills/$1/SKILL.md"
    [ -f "$f" ] && head -40 "$f"
}

case "${1:-}" in
    list) cmd_list; exit 0 ;;
    toggle) cmd_toggle "$2"; exit 0 ;;
    preview) cmd_preview "$2"; exit 0 ;;
esac

"$self" list | fzf \
    --header="enter: toggle  esc: quit   [x] enabled  [ ] disabled  [!] foreign (untouched)" \
    --preview="$self preview {2}" \
    --preview-window=right:60% \
    --bind="enter:execute-silent($self toggle {2})+reload($self list)" \
    >/dev/null || true

echo
echo "Final state:"
"$self" list
