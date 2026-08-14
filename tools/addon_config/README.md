# addon_config

`addons/` is gitignored (see the project README) — it's third-party plugin
code, re-downloadable if needed and not meant to be tracked. But a couple of
scenes inside the Maaack's Game Template addon (`AppConfig`, `SceneLoader`)
double as project configuration: they hold the paths to *our* main menu,
game scene, and loading screen, not addon internals.

This folder tracks copies of those specific files, mirrored at their
addon-relative path (e.g. `tools/addon_config/maaacks_game_template/base/...`
mirrors `addons/maaacks_game_template/base/...`), so that configuration
survives a fresh addon install even though `addons/` itself doesn't.

## Usage

After installing or updating the addon, run:

```
./tools/restore_addon_config.sh
```

This copies every file under `tools/addon_config/maaacks_game_template/`
back into the matching path under `addons/maaacks_game_template/`,
reapplying the project's scene wiring.

## Keeping it in sync

This is a snapshot, not a live link — if you edit `app_config.tscn` or
`scene_loader.tscn` in the Godot editor, re-copy the updated file back into
`tools/addon_config/` afterward so the backup doesn't go stale:

```
cp addons/maaacks_game_template/base/nodes/autoloads/app_config/app_config.tscn \
   tools/addon_config/maaacks_game_template/base/nodes/autoloads/app_config/app_config.tscn
```

(same pattern for `scene_loader.tscn`, or any other addon-internal file that
starts holding project config in the future).
