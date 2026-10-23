# Run setup and permanent equipment access

Implemented October 23, 2026.

## Research and adaptation

Megabonk separates the home screen from character, map and tier selection. Its tiers also govern multi-stage runs. Equipment access involves quests and purchases, and permanent upgrades use Silver. Chicken Punch adopts the selection and permanent-access structure while retaining its own ten-minute runs, three guardians, book UI, character-specific training, permanent gold and run-only chest coins. Our difficulty tiers modify enemy strength and rewards; they are not multi-stage runs.

Sources checked:
- https://www.destructoid.com/how-to-go-to-the-next-stage-in-megabonk/ — map selection and manually selected tiers.
- https://megabonk.wiki/wiki/Shop — permanent purchases and quest prerequisites.
- https://megabonk.fandom.com/wiki/Quests — equipment and character unlock requirements.
- https://www.pcgamer.com/games/roguelike/megabonk-hero-sword-unlock-quest/ — earning access, then buying it in Unlocks.

## Chicken Punch rules

Survive the Night opens setup. Choose an owned defender, available level and difficulty, then Begin Run. The shop has Weapons, Tomes, Items and Characters tabs. Coop Upgrades remains separate and character-specific. Save migration preserves gold, owned characters, records and training. Owned characters grant access to their starting weapons.

Free equipment: Egg Barrage, Razor Feathers, Fighting Spirit, Quick Hatch, Big Heart and Fleet Feet. Free items: Wild Honey, Packed Lunch and Iron Bead. Other weapons require a two-minute survival record and cost 60 gold; other tomes require one minute and cost 35. Common, rare and epic items require one-, two- and four-minute records and cost 25, 40 and 60 gold respectively. Purchase grants access to future reward pools, not an immediate upgrade. Character requirements and prices remain unchanged. Purchases never spend run-only coins.

Coop Meadow is the original map. Amber Orchard unlocks at a three-minute survival record, adds tree lanes, 12% faster waves and more bats. Moonlit Pasture unlocks at six minutes, adds rocky rings with escape gaps, 24% faster waves and earlier casters. Both reuse ground tiles and nature sprites from the downloaded Ninja Adventure pack, with actual obstacle collisions. All levels retain the ten-minute victory condition.

Standard: 1x enemy HP / 1x gold. Ferocious: 1.35x HP / 1.3x gold. Nightmare: 1.8x HP / 1.6x gold. Hit damage follows the existing square-root difficulty scaling. Clearing a difficulty unlocks the next on that level. Older saves with a victory receive Meadow difficulty II access. The gold multiplier applies at the end of the run.

Weapons and tomes cap at rank 10; common/rare/epic upgrades still grant 1/2/3 ranks, clamped at 10. Items cap at ten copies. Brood Burst caps at +10 and grants at most +3 per pick. Evolution requires weapon rank 10, its matching tome rank 1+, and a chest. Ascensions require both evolved weapons, both matching tomes at 10, at least three copies of the recipe item, two defeated guardians, then a chest. Three copies are a recipe threshold, not the item cap. Permanent training remains five ranks and slots remain capped at four.

The compass tracks only unopened chests and magnets. XP, coins and health never override its target.
