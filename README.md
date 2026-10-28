# Chickenpunch

For downloadable builds, see the Windows and Web export presets. [Export and hosting instructions](docs/release/EXPORTS.md) describe how to build and run them.

A Godot 4.7 horde-survival game with character progression, evolving weapons, and ten-minute runs.

## Open the game

Import `project.godot` into Godot and press F6 on `scenes/ui/main_menu.tscn`, or press F5 to launch the configured main scene.

## Project layout

| Folder | Contents |
| --- | --- |
| `scenes/ui/` | Main menu and UI scenes |
| `scenes/world/` | World and spawn-path scenes |
| `scenes/actors/` | Player and enemy scenes |
| `scenes/combat/` | Attack scenes and collision components |
| `scripts/survival/` | Run director, progression data, arsenal, HUD, inspection, compass, pickups, projectiles, and input |
| `scripts/actors/` | Player and enemy behavior |
| `scripts/ui/` | Menu and existing scene UI scripts |
| `scripts/combat/` | Scene attack and collision scripts |
| `scripts/world/` | World and spawning scripts |
| `assets/` | Downloaded packs, character art, custom Coop artwork, sprites, reference art, and UI icons |
| `tests/` | Automated gameplay and regression checks |
| `tools/capture/` | Screenshot and visual-inspection scripts |
| `docs/design/` | Design review and expansion notes |

Downloaded packs retain their original internal structure and licenses. Custom Aseprite sources live beside their exported PNGs. Godot `.uid` and `.import` files are resource metadata and should stay alongside their source files.

## Checks and captures

Run from the project directory, replacing `godot` with your Godot executable:

```text
godot --headless --editor --import --quit --path .
godot --headless --path . --script res://tests/progression_test.gd
godot --headless --path . --script res://tests/expansion_test.gd
godot --headless --path . --script res://tests/music_map_test.gd
godot --path . --script res://tools/capture/capture_menu.gd -- <existing-output-directory>
```

Tests use separate save files. `.godot/` caches and `.local/` editor backups are excluded from version control. Keep `project.godot` and `export_presets.cfg` at the project root.
