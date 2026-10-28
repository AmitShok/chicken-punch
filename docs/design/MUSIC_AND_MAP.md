# Music phases and ground decoration

Implemented October 28, 2026.

## Music

All tracks come from the Ninja Adventure pack. `Data.MUSIC` maps each phase to a file, so swapping a track is a one-line change.

| Phase | Track |
| --- | --- |
| Main menu | 33 - Calm Village |
| Coop Meadow, 0:00–3:00 | 35 - Adventure |
| Amber Orchard, 0:00–3:00 | 23 - Road |
| Moonlit Pasture, 0:00–3:00 | 37 - Dark Forest |
| 3:00–6:00 | 17 - Fight |
| 6:00 onward | 28 - Tension |
| A guardian is alive | 34 - Fight |
| Final guardian | 24 - Final Area |
| Victory / defeat screen | 19 - Ascension / 29 - Lament |

The run checks its phase twice a second and crossfades over 1.2 seconds. Music keeps playing under the pause menu and the result screen. Track choices were made from titles and still need a listening pass.

## Ground decoration

`scripts/world/ground_detail.gd` scatters grass tufts, flowers and small bushes on grass and twigs and leaves on sand. It adds extra cover where the ground tile changes, which softens the stepped edges between field colours. Up to four tilled pumpkin patches sit on open grass. Placement is seeded by level name, so each map looks the same every run. Only field tiles with nothing on the overlay layer are decorated, so docks, water, hedges and existing props stay clear, as do the start point and level obstacles. Nothing collides, and everything draws in a single canvas item.

Sprites come from TilesetNature, TilesetFloorDetail and TilesetFloor in the Ninja Adventure pack. Checked by `tests/music_map_test.gd`.
