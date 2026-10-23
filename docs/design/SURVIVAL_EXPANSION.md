# Chickenpunch — arsenal, UI and synergy expansion

Implemented 18 October 2026 in the existing chickenpunch-3 project. This follows the initial survival-loop implementation described in Chickenpunch-review.md and supersedes its weapon counts and chest rewards.

Current level caps and unlock rules were updated on October 23; see [Run setup and unlocks](RUN_SETUP_AND_UNLOCKS.md).

## What changed

- Eight weapons, ten upgrade tomes, twelve treasure items and eight evolutions.
- Four weapon slots and four tome slots per run. Treasure items use a separate collection and stack up to ten times.
- Common/rare/epic level-up offers grant one/two/three ranks, capped at ten. New equipment starts at rank one. Three rerolls, two skips and two banishes help shape a build.
- Readable sans-serif text, a 960×640 interface, rarity-colored cards with before/after values, visible inventory, centered run timer, guardian health and chest directions.
- A paused build screen includes damage totals excluding overkill, synergy status, evolution recipes, item descriptions, controls and audio settings.
- Weapon, dash, impact, critical, selection, chest, evolution and defeat effects reuse the downloaded Ninja Adventure audio pack. Music and sound effects have independently saved volume sliders. M toggles master mute. Repeated sounds are throttled with small pitch variations on combat effects.
- Existing ChickenPack characters, authored map and Ninja Adventure art remain. Every needed image/effect was available in the downloaded packs, so no new artwork or Aseprite assets were required.

## Evolutions, plainly explained

An evolution is a stronger form of an existing weapon, lasting until the run ends. It does not consume another weapon slot, remove its matching tome, or erase your other bonuses.

1. Upgrade a weapon to rank 10.
2. Own its matching tome at rank 1 or higher.
3. Collect a chest. One eligible weapon transforms automatically, and a paused reveal explains exactly what changed.

That chest gives the evolution instead of a treasure-item selection, plus its normal gold. A chest collected before a recipe is ready gives a treasure-item choice; it is not stored for a future evolution. If multiple recipes are ready, one evolves per chest in the recipe order below. Evolutions reset when the run ends; Coop purchases persist.

Example: **Egg Barrage rank 10 + Quick Hatch rank 1 + a chest = Golden Omelette.** It fires three extra eggs per volley, and egg hits gain splash damage. Merely owning Quick Hatch does not evolve the weapon.

| Rank-5 weapon | Required tome, rank 1+ | Evolved form | Added effect |
| --- | --- | --- | --- |
| Egg Barrage | Quick Hatch | Golden Omelette | Three extra eggs per volley and splash damage |
| Razor Feathers | Fleet Feet | Featherstorm | Three additional piercing blades |
| Hot Foot | Wide Wings | Phoenix Trail | Burning patches become 60% larger |
| Coop Guard | Iron Shell | Iron Roost | Two additional orbiting blades |
| Storm Call | Keen Eye | Thunderhead | Three additional lightning targets |
| Frost Quills | Long Summer | Deep Winter | Two extra shards; slow strengthens to 70% for 3.5 seconds before duration bonuses |
| Harvest Moon | Forager | Reaping Season | A second returning sickle flies in the opposite direction |
| Shell Shock | Fighting Spirit | Meteor Nest | 45% larger explosion radius before area bonuses |

Press **Escape → Evolutions** for recipes and ready/evolved indicators.

## Five automatic synergies

Synergies activate immediately when both ingredients are owned. They do not need rank 10 or a chest. A notification announces newly completed combinations; Escape → Loadout shows their status.

| Combination | Synergy | Behavior and tactical use |
| --- | --- | --- |
| Frost Quills + Storm Call | Cold Conductor | Lightning deals 35% more damage to chilled enemies and jumps 60% farther from them. Ice creates stepping stones through scattered crowds. |
| Hot Foot + Frost Quills | Steam Engine | Fire consumes an enemy's chill to create an area blast, with a three-second cooldown per enemy. Trade crowd control for burst damage by drawing frozen enemies into fire. |
| Harvest Moon + Crimson Seed | Reaper's Feast | Sickle return hits heal one HP per hit, capped at two hits, multiplied by item stacks. Position the return path through enemies; an empty return heals nothing. |
| Shell Shock + Blast Powder | Cluster Nest | Shell explosions release six piercing fragments dealing 20% of shell damage each. Fragments cannot recursively explode. |
| Coop Guard + Iron Bead | Iron Wake | Dash releases a protective blast dealing 12 damage per bead stack, scaled by damage bonuses. A defensive escape becomes an offensive move. |

These interactions can coexist with evolved weapons. Fire consuming chill can also reduce lightning's chilled-target opportunities: a build decision rather than an unconditional bonus stack.

## Treasure items

Each stacks to three. Listed amounts are per stack unless noted.

| Item | Effect |
| --- | --- |
| Lucky Seed | +6 percentage points to rare-or-better upgrade chance |
| Hawk Eye | +8 percentage points critical chance; critical hits deal double damage |
| Wild Honey | +0.3 HP regeneration per second |
| Packed Lunch | Heal 12 when opening a chest |
| Lodestone | +25 pickup radius |
| Blast Powder | Every eighth kill creates an explosion for 20 damage, also scaled by damage bonuses |
| Crimson Seed | Heal 3 every fifteenth kill |
| Red Feather | +25% damage while below half health |
| Wind Charm | Dash cooldown multiplied by 0.85 |
| Giant Slayer | +20% damage to elites and guardians |
| Field Notes | +12% XP |
| Iron Bead | +1 armor |

Critical chance caps at 85%. Fully collected treasure pools fall back to gold.

## Research behind the expansion

These are design interpretations of official developer store descriptions, not claims based on personally playing the reference games. The earlier review covers Vampire Survivors, Brotato, Death Must Die, Halls of Torment and Deep Rock Galactic: Survivor as well.

- [Megabonk](https://store.steampowered.com/app/3405340/Megabonk/) emphasizes randomized upgrades, loot and synergistic builds. Applied here through visible equipment limits, rarity-colored selection cards, stackable chest items and actual before/after upgrade values. Its UI conventions informed the layout; its assets were not copied.
- [Soulstone Survivors](https://store.steampowered.com/app/2066020/Soulstone_Survivors/) describes extensive skill and build combinations. Applied here by connecting status effects and weapon behaviors, rather than only adding additive stat boosts.
- [20 Minutes Till Dawn](https://store.steampowered.com/app/1966900/20_Minutes_Till_Dawn/) describes elemental builds, weapon evolution and distinct upgrade paths. Applied here through fire/ice/lightning interactions and explicit transformation explanations. This game retains automatic firing.
- [Nordic Ashes](https://store.steampowered.com/app/2068280/Nordic_Ashes_Survivors_of_Ragnarok/) features relic builds and weapon ascensions. Applied here by separating treasure items from weapon/tome slots and making ascension requirements inspectable. A constellation progression tree was not added.

## Verification and remaining limits

- Original functional suite: 22 checks passed.
- Expansion suite: 64 checks passed, including all recipes, rarity caps, queue handling, item limits, each synergy's combat behavior, new weapon activation, damage accounting, audio loading/routing and pause UI.
- Accelerated engine simulation with the four new evolved weapons: victory at 10:39, 3,058 kills, all three guardians, peak 181 enemies and 522 direct world children. No reported engine errors. This is a stability test with deliberately inflated player health and a prebuilt loadout, not proof of normal-run balance or real-time performance.
- Engine-rendered screenshots inspected at 960×640: upgrade cards, menu, synergy page, evolution reveal and all twelve inventory items. No clipping found in those captures. The capture is staged gameplay, not a claim of an organic run.
- Sound resources and independent volume routing were tested; the final loudness mix still benefits from listening on the intended speakers/headphones.
- More normal human playtesting is needed to tune item weights, boss time-to-kill and sustain builds. Controller navigation, alternate aspect ratios, a larger character roster and more distinct guardian encounters remain future work.

Launch with Play-Chickenpunch.cmd or run the project in Godot. Restart an already-running game instance to load the new scripts.
