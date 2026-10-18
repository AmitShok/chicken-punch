# Chickenpunch: horde survival review and implementation

Reviewed and implemented 18 October 2026. Project: `chickenpunch-3`.

## Assessment

The original prototype had a strong, compact identity: a small animated chicken, a colorful pixel-art field, dog enemies, eggs, shuriken, fire, and bone experience pickups. Keeping that identity is more useful than borrowing another game's aesthetic. The main gap was the decision loop: surviving and gaining XP did not create meaningfully different builds, encounters did not change over a run, and failure returned directly to the menu without a run summary or lasting rewards.

The implementation now supplies a complete ten-minute run structure. This is a playable development build, not a claim that the game has the content volume, balance, accessibility, or production polish of the reference games.

## Research and design implications

The following observations come from the developers' official store descriptions and poncle's documentation. The design decisions are my interpretation of those observations, not claims that these mechanics alone explain commercial success. Store pages are useful for comparing systems, but they do not replace playing each game or studying telemetry.

| Reference | Relevant documented systems | Application to Chickenpunch |
| --- | --- | --- |
| [Vampire Survivors](https://store.steampowered.com/app/1794680/Vampire_Survivors/) | Minimal controls, survival against large crowds, collecting XP and gold, purchases helping later runs. Its starting tips encourage focusing weapon levels and experimenting with upgrade paths. | Automatic combat, retained movement focus, meaningful level choices, concentrated weapon ranks, run rewards and permanent Coop upgrades. |
| [Megabonk](https://store.steampowered.com/app/3405340/Megabonk/) | Randomized upgrade offers, loot, bosses, character unlocks, synergistic items, and randomized maps. | Random upgrade drafts, treasure exploration, elite rewards and weapon/passive combinations. Preserve the existing authored map; procedural maps and a character roster are future work. |
| [Brotato](https://store.steampowered.com/app/1942280/Brotato/) | Multiple simultaneous weapons, short timed waves, a between-wave shop, character customization and difficulty adjustments. | Four concurrent weapon families, clear encounter timings, readable choices and three difficulty settings. Keep the continuous field-survival loop rather than introducing a second shop economy mid-run. |
| [Death Must Die](https://store.steampowered.com/app/2334730/Death_Must_Die/) | Blessing combinations, persistent equipment, bosses, shrines and exploration locations; improved rewards can come with stronger enemies. | Build synergies and world rewards. Risk/reward shrines and persistent equipment deserve later implementation once the basic economy is tested. |
| [Halls of Torment](https://store.steampowered.com/app/2218750/Halls_of_Torment/) | Traits, abilities and items, quest progression, distinct boss attacks, exploration and equipment retrieval. | Transparent recipes, differentiated enemy roles, guardian attacks with warning periods. Quest-based unlocks and distinct guardian identities remain priorities for expansion. |
| [Deep Rock Galactic: Survivor](https://store.steampowered.com/app/2321470/Deep_Rock_Galactic_Survivor/) | Automatic weapons plus mining, procedural caves, mission objectives and timed extraction. | Movement should accomplish something beyond circling: chests and collection magnets now give the player destinations. Mining and destructible terrain would require a separate map-design pass. |

[Poncle's Adventures FAQ](https://poncle.games/adventures-faq) also describes self-contained remixes of existing environments, characters and weapons. That supports expanding this game's existing art vocabulary before producing unrelated biomes or large quantities of new artwork.

The resulting design principles are:

1. Give the player a decision early and make its consequences visible. Three choices, rerolls and banishes make leveling an actual build decision.
2. Let weapon shapes support different movement. Eggs reward target selection through positioning; shuriken cut through groups; fire rewards leaving a trail; orbiting blades support close-range play.
3. Establish clear destinations and milestones. Treasure provides short-term goals; guardians at three, six and ten minutes provide medium-term goals; victory and Coop upgrades complete the loop.
4. Telegraph danger. Casters and guardians wind up before firing. Player invulnerability and dash cooldowns make avoidance more legible.
5. Bound the simulation. Regular enemy spawning is capped; projectiles expire; excess XP pickups merge their value; damage numbers are limited. These are protective limits, not a substitute for profiling on target hardware.

## Implemented systems

- Ten-minute survival run; guardians appear at 3:00, 6:00 and 10:00. Defeat the final guardian to win. Normal spawning stops at 10:00 while remaining enemies and the final guardian continue fighting.
- Four weapon families, five ranks each, and four chest-triggered evolutions.
- Eight passive upgrade families: damage, recharge, area, movement, armor, collection/XP, maximum health, regeneration.
- Three random choices per level, three rerolls and two banishes per run. Capped or banished upgrades leave the pool. If the pool is exhausted, healing/gold choices remain available.
- XP overflow and multiple pending levels are retained. Chests grant a free choice when no evolution is ready.
- Dog pursuers, fast bats, tanky bears, ranged lanterns, elites and a slime guardian. Local crowd separation and basic obstacle steering reduce stacking and getting stuck.
- A dash with brief invulnerability, player hit protection, armor, healing and regeneration.
- XP, coins, healing, collection magnets, treasure and a direction/distance indicator toward the nearest chest.
- Health/XP HUD, timer, kill count, equipped weapons, dash status, pause menu, evolution reference, result screen and retry.
- Persistent gold, best survival time, victory count, five damage upgrades and five health upgrades in the Coop.
- Relaxed, Standard and Ferocious enemy health/damage multipliers. These are presets rather than full accessibility controls.
- Pack music and throttled pickup, upgrade and damage sounds, with a saved mute setting.

### Evolution recipes

| Rank-five weapon | Passive at rank one or higher | Collect a chest to receive | Effect |
| --- | --- | --- | --- |
| Egg Barrage | Quick Hatch | Golden Omelette | Extra eggs and splash damage |
| Razor Feathers | Fleet Feet | Featherstorm | Three additional piercing blades |
| Hot Foot | Wide Wings | Phoenix Trail | Larger burning ground |
| Coop Guard | Iron Shell | Iron Roost | Two additional orbiting blades |

The original art files are untouched. Newly used enemies, boss, item icons, pickups, projectiles, font and audio come from the already downloaded Ninja Adventure pack. The original chicken, egg, bone and map are retained. No missing artwork required fabrication, so no new assets were made outside Aseprite or inside it. Ninja Adventure's included README specifies CC0 and credits Pixel-boy and AAA; the menu retains those credits. This review does not establish the provenance of the pre-existing ChickenPack.

## Original technical issues addressed

The old projectile scripts attempted to call methods absent from the enemy script. The new active combat path uses a consistent `take_damage` interface with swept projectile hit checks and one-time enemy death rewards. The old hurt signal declared three parameters but emitted two; its signature is corrected. An invalid self-connection was removed. The new controller disables the legacy overlapping hitbox path to prevent double damage.

All new attacks, pickups, enemies and transient effects belong to the world scene, so retry can clear them together. The active player no longer discards XP overflow or grants unbounded movement speed on every level. The camera transform is normalized, and the redundant sprite membership in the player group is removed at runtime.

Legacy scenes/scripts remain for reference and compatibility; the survival director supplies the active combat path. Avoid enabling the old AttackManager or MobTimer alongside it.

## Balance hypotheses to test next

The values below are goals for human playtests, not measured outcomes:

- First level choice within roughly 20–35 seconds of active collection.
- First additional weapon within the opening minute in most runs.
- First evolution around minutes four to six when deliberately pursuing a recipe.
- At least two plausible builds should defeat the first guardian without permanent upgrades.
- Death should be explainable: contact, a missed windup or poor routing, rather than unreadable visual effects.
- A loss should fund progress without making permanent upgrades necessary to survive the opening.

Collect run time, level timing, upgrade picks, weapon damage totals, damage taken by source, chest collection and death positions. Use several fresh players and test Standard with no Coop upgrades before tuning around experienced play. The automated simulation uses artificial health/upgrades and cannot establish player difficulty or fairness.

## Remaining production work

The next substantial content pass should add distinct guardian behaviors and silhouettes, an unlockable chicken roster with different starting weapons, achievements tied to experimentation, and more hand-authored exploration events. Add controller input, remapping, sound sliders, independent enemy accessibility settings and readable HUD scaling before wider distribution. Add navigation or authored routes where obstacle steering proves insufficient.

For hundreds more simultaneous enemies, profile collision/targeting costs and consider spatial queries for projectiles or pooling. Current crowd separation uses a grid, but projectile target checks still scan the active enemy list.

Random item rarities, large equipment inventories, procedural maps, endless mode, co-op and extensive quest systems are not implemented. They should be chosen according to the game's identity and tested need, rather than added simply because another game has them.

## Project organization and running

Open the existing project in Godot and press F6 on `main_menu.tscn`, or F5 to run the project. The main scene is explicitly configured as the menu. A launcher is supplied alongside this report and uses the installed Godot executable.

- `scripts/survival/run.gd`: encounter pacing, weapons, drops, progression and run outcome.
- `scripts/survival/data.gd`: upgrade catalogue, recipes and save storage.
- `scripts/survival/interface.gd`: HUD, upgrade choices, pause and results.
- `scripts/survival/projectile.gd`, `pickup.gd`: attack and pickup behavior.
- `scripts/survival/input.gd`: arrow keys, dash, pause and mute bindings.
- `chicken.gd`, `enemy.gd`, `main_menu.gd`: active player, enemy and Coop behavior.
- `tests/survival_test.gd`: functional regression checks using a separate save file.
- `tests/soak_test.gd`: accelerated, artificial-build endurance simulation using a separate save file.
- `tools/capture/capture_ui.gd`: reproducible staged combat and upgrade-screen captures.

Save data lives at Godot's `user://coop_save.cfg`. Test scripts use distinct files. The original source snapshot is supplied as a ZIP; it excludes unchanged assets and the generated Godot cache. Restore only if you intend to replace the edited source with that snapshot.

## Verification results

- Godot 4.7.2 editor import: passed without parse errors after normalizing script indentation to Godot's tab convention.
- 22 functional assertions passed: XP overflow, pending levels, paused time, upgrade selection, rerolls, banishes, four evolutions, armor/invulnerability, single death rewards, enemy initialization, orbit/fire activation, final victory, save persistence, duplicate reward protection, fresh retry and lethal damage.
- Final accelerated endurance run: 630.2 simulated seconds, 3,105 kills, 122 peak active enemies, 676 peak direct world children, all three guardians spawned, final guardian defeated. Standard enemy multiplier, but artificially granted a complete build and very high health. This validates execution and cleanup, not player balance or a hardware frame-rate target. Final run emitted no stderr errors.
- Rendered combat and upgrade screens inspected at 720×480; live main menu, gameplay and loss screen inspected through the game window.
- Earlier headless shutdown warnings were traced to audio playback with the headless audio backend. Headless tests now omit playback; normal gameplay retains sound. Final functional and render checks emitted no stderr errors.
- Screenshots are staged test scenarios showing the actual Godot renderer, not mockups or evidence of a naturally earned build.
