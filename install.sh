#!/bin/sh
# Install the pharo-review skill for coding agents: link .agents/skills/pharo-review
# into each agent's personal skills folder, so it follows this checkout.
# The tool itself is loaded into the Pharo image by the agent, through MCP, with the
# Metacello expression in README.md (the skill says when).
set -eu

here=$(cd "$(dirname "$0")" && pwd)
skill="$here/.agents/skills/pharo-review"

for dir in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
	mkdir -p "$dir"
	target="$dir/pharo-review"
	if [ -L "$target" ]; then
		rm "$target"
	elif [ -e "$target" ]; then
		echo "Skipped $target: it exists and is not a link. Move it away and run again." >&2
		continue
	fi
	ln -s "$skill" "$target"
	echo "Linked $target -> $skill"
done
