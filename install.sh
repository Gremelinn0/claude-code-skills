#!/bin/bash
set -e

SKILLS_SRC="$(cd "$(dirname "$0")/skills" && pwd)"
TARGET="$HOME/.claude/skills"

mkdir -p "$TARGET"
cp -r "$SKILLS_SRC"/. "$TARGET/"

echo "Installed $(ls "$SKILLS_SRC" | wc -l) skills to $TARGET"
