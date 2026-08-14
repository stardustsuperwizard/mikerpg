#!/usr/bin/env bash
# addons/ is gitignored (see README), but a couple of scenes inside the
# Maaacks Game Template addon carry project-specific config (which scenes
# the main menu / scene loader point at) rather than addon code. Tracked
# copies live under tools/addon_config/, mirroring their addon-relative
# paths. Run this after installing or updating the addon to reapply that
# config.
set -euo pipefail
cd "$(dirname "$0")/.."

SRC_ROOT="tools/addon_config/maaacks_game_template"
DEST_ROOT="addons/maaacks_game_template"

if [ ! -d "$DEST_ROOT" ]; then
	echo "addons/maaacks_game_template not found -- install the addon first." >&2
	exit 1
fi

find "$SRC_ROOT" -type f | while read -r src; do
	dest="$DEST_ROOT${src#"$SRC_ROOT"}"
	mkdir -p "$(dirname "$dest")"
	cp "$src" "$dest"
	echo "restored $dest"
done
