# Travel Book UI and combat feedback

Uses Crusenho Agus Hennihuno's Travel Book Lite, downloaded from https://crusenho.itch.io/complete-ui-book-styles-pack on 2026-10-20. The user chose the free Travel Book theme instead of the paid notebook theme. Original PNGs and editable Aseprite sources are retained under assets/ui/travel_book with the original License.txt. Sprites are nine-sliced and tinted in Godot; source art is unchanged. Attribution appears in both main-menu and pause-menu Credits.

The character menu uses a leather cover and separate parchment pages, with the roster on the left and actions on the right. Gold, best time and wins remain at the top. Options, upgrades, pause inspection and rewards use matching pages and buttons. Text uses the m6x11 pixel font by Daniel Linssen (assets/fonts, free with attribution; credited in Credits), snapped to whole multiples of 16px so it stays crisp. Book art is scaled 2x with nearest filtering to match the 2x world camera. Tab still switches between compact and expanded HUD layouts.

Combat feedback adds visual-only enemy squash, directional defeat echoes, dash afterimages, bounded camera impacts on player damage and boss defeats, and throttled enemy-hit audio from Ninja Adventure. Echoes are capped at 24 and expire in 0.18–0.24 seconds; camera displacement is at most three world pixels and rapidly decays. No global hit-stop or combat timing changes were introduced. Effects pause with gameplay. Options > Effects persists a reduced-motion toggle for the new motion effects. Existing core hit flashes and essential telegraphs remain.

Video reference: GameMaker, “Why Archvale Feels Amazing (Add Game Juice)”, https://www.youtube.com/watch?v=vN3fQZvfj4Q. A subsequent browser retry recovered the timestamped transcript and the projectile demonstration. See ARCHVALE_FEEDBACK.md for the techniques applied in the follow-up.

Validation: progression, roster, expansion and dedicated feedback tests; rendered menu, upgrades, pause loadout, reward and compact/full HUD captures. The feedback test checks damage preservation, sprite recoil, effect caps, cleanup, camera bounds, disabled motion and preference persistence.

## Book spread layout (October 28, 2026)

Every main-menu page is an open book: a Banner title above, bookmark tabs (Marker sprite with pack icons) along the top edge for Coop, Run, Shop, Training and Options, and a left/right page spread. The left page lists choices; the right page shows the selection's details and the primary action. The shop lists entries with Owned / price status and shows the selected entry on the right. Options lists categories on the left. In-run popups (level up, pause, chest, evolution, results) use the same banner over a book.

The Banner sprite exists only in the pack's Aseprite source. `tools/art/extract_travel_book.lua` crops it unchanged into `assets/ui/travel_book/Derived`. Sliders use Bar, Fill and Handle; toggles use Toggle; keyboard focus uses the Select corner brackets; pressed list rows use FrameSelect01b.
