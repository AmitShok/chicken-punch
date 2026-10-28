# Quests, starter gear and the power ladder

Implemented October 28, 2026. Supersedes the unlock rules in RUN_SETUP_AND_UNLOCKS.md.

## The problem

Measured before the change, the two free weapons, Egg Barrage and Razor Feathers, were the strongest in the game. The free tomes Fighting Spirit (+20% damage per rank, 3x at rank 10) and Quick Hatch (0.9^rank cooldown, 2.9x attack speed) multiplied damage about 8.6x between them. A fresh save could win with two weapons and two tomes. Unlocking more made runs weaker, because level-ups spread across more slots.

## Megabonk research and what we adapted

- Most gear starts locked behind quests (in-run or lifetime tasks), then is bought with Silver. One guide counts 35 of 78 items unlocked by default. The strongest items sit behind skill checks and boss challenges ([Common Sense Gamer](https://commonsensegamer.com/megabonk-items/), [Selphie1999](https://selphie1999gaming.com/game-guides/megabonk/megabonk-quests-how-to-unlock-new-characters-items-and-weapons/)).
- Build tools such as Refresh, Skip and Banish, plus extra slots, unlock at completed-quest milestones ([Selphie1999 slots](https://selphie1999gaming.com/game-guides/megabonk/heres-how-to-unlock-weapon-and-tome-slots-in-megabonk/)).
- Difficulty rises over a run and tiers unlock by beating bosses ([Dexerto](https://www.dexerto.com/wikis/megabonk/what-does-difficulty-do)).
- Broken builds come from stacking specific multipliers with specific characters and items, such as crit scaling and reactive combos ([findingdulcinea](https://findingdulcinea.com/best-megabonk-characters-tier-list), [dtgre](https://www.dtgre.com/2025/10/megabonk-meta-evolution-patch-1-0-12-guide.html)). Guides are fan-written and patch-dependent; we adapt the structure, not numbers.

## Rules now

- **Starter gear (free):** Egg Barrage and Hot Foot; the Big Heart, Fleet Feet, Forager and Second Wind tomes; the Wild Honey, Packed Lunch and Iron Bead items.
- **Everything else** needs a quest (`Data.QUESTS`, 22 total), then gold. Quest progress comes from lifetime stats saved after each run, so it is retroactive and cannot fall out of sync. Old saves keep credit for best time and wins.
- **Build tools:** a new save gets 1 reroll, no skip and no banish. Completing 2/4/5/8/10/12/14/16 quests adds reroll, skip, banish, reroll, banish, skip, reroll, banish.
- **Tome scaling:** Fighting Spirit +10% per rank (2x at 10); Quick Hatch 0.95^rank (1.67x attack speed at 10); Brood Burst +1 projectile per two ranks (+5 at 10).
- **Egg Barrage:** an egg every second rank (6 at rank 10, was 10).
- **Gold per run:** 1 per 15 seconds + 1 per 40 kills + 10 per guardian + 50 for a win, times the difficulty multiplier.

| Quest | Unlocks |
| --- | --- |
| Survive 3:00 | Pepper |
| Reach level 15 | Harvest Moon |
| Defeat 500 enemies | Iron Shell |
| Defeat 1,000 enemies | Coop Guard, Whisker |
| Open 10 chests | Tailwind, Coop Key |
| Reach level 20 | Long Summer, Field Notes |
| Reach level 25 | Lucky Seed |
| Defeat 2,500 enemies | Lodestone |
| Survive 5:00 | Wide Wings |
| Defeat a guardian | Fighting Spirit, Shell Shock, Truffle |
| Raise a weapon to rank 10 | Quick Hatch, Storm Call |
| Evolve a weapon | Frost Quills, Giant Hatch |
| Defeat two guardians in one run | Razor Feathers |
| Dash 100 times in one run | Wind Charm |
| Defeat 5,000 enemies | Crimson Seed |
| 60 s below half health in one run | Red Feather |
| Evolve Hot Foot | Blast Powder |
| Defeat 6 guardians | Giant Slayer |
| Win a run | Keen Eye, Clover |
| Keen Eye rank 10 in one run | Hawk Eye |
| Win 3 runs | Brood Burst |

The game-breaking routes need the deepest chains. Overcrit needs a win, Keen Eye 10, then Hawk Eye. Redline also needs Red Feather. Slow Roast needs Phoenix Trail and Blast Powder. Ascensions need two evolutions, two rank-10 tomes and three copies of a late item.

## Measurements

`tools/balance/boss_race.gd` stands each build next to a guardian with no fodder or dodging. These are best-case kill times; real fights take longer.

| Build | Guardian 1 (3:00) | Guardian 2 (6:00) | Final (10:00) |
| --- | --- | --- | --- |
| Starter gear at max | 22.5 s | 96.1 s | over 240 s |
| First unlocks (Shell Shock, Fighting Spirit, Wide Wings) | 11.3 s | 48.6 s | 207.2 s |
| First win (Quick Hatch, Golden Omelette, training) | 5.7 s | 22.7 s | 94.2 s |
| Four full slots | 1.9 s | 5.7 s | 22.7 s |
| Overcrit + Redline + Absolute Zero | 0.2 s | 0.9 s | 2.8 s |
| Henpocalypse + Slow Roast | 0.8 s | 1.6 s | 4.0 s |

`tools/balance/sim_run.gd` plays full runs with a kiting bot. On a fresh save the bot now survives 2:28–3:38 (six seeds) with 178–450 kills and level 8–16, so each early run advances several quests and pays 15–25 gold. Before the change the same bot survived 4:27–6:56. The bot cannot aim at guardians or use banish, so it understates skilled play; use it for comparisons only.
