# Travel Book UI and combat feedback

Uses Crusenho Agus Hennihuno's Travel Book Lite, downloaded from https://crusenho.itch.io/complete-ui-book-styles-pack on 2026-10-20. The user chose the free Travel Book theme instead of the paid notebook theme. Original PNGs and editable Aseprite sources are retained under assets/ui/travel_book with the original License.txt. Sprites are nine-sliced and tinted in Godot; source art is unchanged. Attribution appears in both main-menu and pause-menu Credits.

The character menu uses a leather cover and separate parchment pages, with the roster on the left and actions on the right. Gold, best time and wins remain at the top. Options, upgrades, pause inspection and rewards use matching pages and buttons. Text remains a readable system font. Tab still switches between compact and expanded HUD layouts.

Combat feedback adds visual-only enemy squash, directional defeat echoes, dash afterimages, bounded camera impacts on player damage and boss defeats, and throttled enemy-hit audio from Ninja Adventure. Echoes are capped at 24 and expire in 0.18–0.24 seconds; camera displacement is at most three world pixels and rapidly decays. No global hit-stop or combat timing changes were introduced. Effects pause with gameplay. Options > Effects persists a reduced-motion toggle for the new motion effects. Existing core hit flashes and essential telegraphs remain.

Video reference: GameMaker, “Why Archvale Feels Amazing (Add Game Juice)”, https://www.youtube.com/watch?v=vN3fQZvfj4Q. Its title, author and description were verified; automated caption retrieval returned empty content. The implemented feedback techniques are our design choices, not a claimed transcription or exhaustive recreation of that video.

Validation: progression, roster, expansion and dedicated feedback tests; rendered menu, upgrades, pause loadout, reward and compact/full HUD captures. The feedback test checks damage preservation, sprite recoil, effect caps, cleanup, camera bounds, disabled motion and preference persistence.
