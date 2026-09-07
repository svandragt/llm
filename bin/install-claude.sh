#!/usr/bin/env bash
# Link this repo's Claude Code config into ~/.claude. Idempotent; backs up
# any real file it replaces into ~/.claude/backups/. Run after cloning on a
# new machine, and again whenever Claude Code rewrites settings.json in
# place (that turns the symlink back into a real file).
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
cfg="$repo/claude"
target="$HOME/.claude"
backups="$target/backups"
mkdir -p "$target/hooks" "$target/output-styles" "$backups"

link() {
    local src="$1" dst="$2"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then return; fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        mv "$dst" "$backups/$(basename "$dst").$(date +%s)"
        echo "backed up $dst"
    fi
    ln -s "$src" "$dst"
    echo "linked $dst"
}

for f in CLAUDE.md settings.json statusline.py; do link "$cfg/$f" "$target/$f"; done
for f in "$cfg"/hooks/*; do link "$f" "$target/hooks/$(basename "$f")"; done
for f in "$cfg"/output-styles/*; do link "$f" "$target/output-styles/$(basename "$f")"; done

pr="$repo/prompt-relay"
if [ -d "$pr" ]; then
    mkdir -p "$target/agents" "$target/references" "$target/bin"
    for f in "$pr"/agents/*.md; do case "$f" in *.example.md) continue;; esac; link "$f" "$target/agents/$(basename "$f")"; done
    link "$pr/references/routing.md" "$target/references/routing.md"
    link "$pr/hooks/claude" "$target/hooks/prompt-relay"
    link "$pr/bin/bulk-read" "$target/bin/bulk-read"
else
    echo "missing $pr: git clone https://github.com/noeltock/prompt-relay $pr"
fi

"$repo/bin/link-skills.sh" || true

for tool in park moshi-hook herdr; do
    command -v "$tool" >/dev/null || echo "warning: $tool not on PATH; its hooks will fail quietly"
done
[ -x "$HOME/dev/vala/hairness/hooks/cc-status.sh" ] || echo "warning: hairness (cc-status) not cloned at ~/dev/vala/hairness"
