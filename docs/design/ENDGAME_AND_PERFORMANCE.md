# Difficult nights, exploitable builds

## Research and adaptation

The [Megabonk Precision Tome page](https://megabonk.wiki/wiki/Precision_Tome) describes critical chance above 100% rolling higher critical tiers. A [player build discussion](https://steamcommunity.com/app/3405340/discussions/0/685238092472362789/) describes combining Moldy Cheese, Unstable Transfusion and repeated hits to ramp damage against high-health bosses. These are community descriptions, not authoritative balance specifications. We adapt their underlying investment/interaction ideas rather than copy their numbers.

The design keeps multiplicative payoff, rare-component requirements, and positioning/survival risk. Four slots are useful because crowd clearing, boss damage, control and survival compete for space. Winning is never artificially gated on the number of purchased slots.

## Build routes

- **Overcrit:** Keen Eye and Hawk Eye each add 8 percentage points per rank/stack. The former 85% ceiling is removed. At 104%, every hit is critical and 4% are 4x overcrits; at the legal maximum of 160%, 60% are overcrits. Each equipment rank remains capped at ten.
- **Redline:** three Red Feathers and health strictly below 50% double overcrit damage again, from 4x to 8x. Regular crits are unchanged. Getting over 100% needs investment in both crit sources; healing above the threshold removes Redline. Projectile count and haste offer more rolls, while damage and Giant Slayer multiply the payoff.
- **Slow Roast:** Phoenix Trail (evolved Hot Foot), three Epic Blast Powders and Long Summer rank five enable Heat. Each fire tick adds one stack to that enemy, up to thirty. Other primary weapons gain 8% damage per stack (3.4x at cap). It takes about twelve seconds of exposure to fully heat a target. Heat expires after two seconds times the duration multiplier without fire. Fire and secondary procs do not cash in their own Heat. Keep a guardian in the trail, then exploit it with another weapon. Enemy tint and pause descriptions communicate the effect.
- Existing **Absolute Zero**, **Henpocalypse**, and **The Last Harvest** Ascensions remain: two specified evolved weapons, two specified rank-ten tomes, three recipe items, two defeated guardians, then a chest. They retain their triple damage and enhanced cast patterns. Slow Roast can complement Henpocalypse; overcrits complement Absolute Zero.

## Difficulty

Enemy health scales by `1 + 0.7m + 0.12m²`, after a 1.25 base multiplier and selected difficulty. Damage scales by `1 + 0.22m + 0.015m²`, after the base/difficulty multiplier. Speed also increases over time. Guardian base health is increased; second/final guardians multiply it by 1.35/2.0. Later casters fire spreads. Guardians use rotating rings plus aimed volleys and resist extreme slows. Regular enemies and elites continue spawning during the final battle, and overtime increases incoming damage and guardian firing pressure.

Overlapping fire ticks only once per enemy. Dense trails improve coverage, rather than multiplying damage by hundreds while standing still. This is distinct from the deliberate Heat/critical/Ascension multipliers.

## Performance architecture

- Spatial cells replace full-horde scans for most projectiles, chains and explosions. Projectiles test their swept travel segment to avoid tunneling.
- Projectiles reuse a pool with reset collision history, allegiance, appearance and attack state. Lifetime/range bounds retire distant projectiles.
- At most 160 fire patches; nearby patches refresh and oldest patches recycle. Common pickups consolidate into at most 96 nodes per kind without discarding their base reward values.
- Ordinary spawning reserves space below a 180-enemy bound; guardians can bypass that bound. Cosmetic impacts cap at 48, giant translucent explosions at six. Damage and hostile shots are not dropped when a cosmetic budget is exhausted.
- Shared sprite frames, cached item textures and quantized shared hit-flash materials reduce resource/allocation overhead. Crowd steering recalculates every 0.12 seconds; collision movement still runs each physics tick.
- Windows and web use Compatibility rendering, with 30 Hz physics and render interpolation. Pool reuse resets interpolation to prevent streaks across the arena.

## Reproducible checks

`tests/endgame_test.gd` covers overcrit thresholds, Redline's health condition, Heat prerequisites/ramp/expiry/proc exclusion, fire overlap, reward conservation, pool reset, swept collision and late scaling. The normal regression suite covers weapons, evolution/Ascension, UI inspection, progression, saves and chest behavior.

`tests/performance_probe.gd` measures only a combat CPU batch, not frame rate: 180 enemies, 240 shots and 960 requested fire patches. Before optimization: median 52.44 ms, p95 81.11 ms. Optimized measurements vary with host load; one final run measured 14.04/18.56 ms, with the fire population bounded at 160.

`tests/render_stress.tscn` is a disposable diagnostic entry scene, excluded from production exports. It runs a maxed four-weapon Ascension build against 180 artificially unkillable enemies, with 960 requested fire patches, for thirty wall-clock seconds. Frame intervals exclude the first five seconds. This deliberately exceeds ordinary combat density and is not a normal-play FPS claim. On the local Intel Iris Xe, the initial Compatibility trial measured 121.92 ms median / 227.40 ms p95. After interpolation, steering/material/effect changes: 20.51 / 55.74 ms. Sustained worst-case smoothness is not yet guaranteed; low-end devices can still drop frames.

`tests/build_comparison.gd` compares thirty seconds of stationary guardian damage from a maxed two-weapon/two-tome loadout and a completed four-weapon/four-tome Ascension build. It is not a human win-rate model: it disables movement and incoming damage, and directly equips the builds. `tests/soak_test.gd` checks a full accelerated run with boosted player health; passing it demonstrates stability and that endgame damage can win, not that the difficulty is easy.

Final comparison: the two-weapon build dealt 154,335 of 175,000 guardian HP in thirty seconds; the completed Ascension build defeated it in 8.88 seconds. The accelerated full-run stability check defeated all three guardians at 611.27 seconds (4,784 kills, peak 66 enemies / 418 world children).

The Chromium/WebGL stress test at the same in-app browser viewport improved from 230.40 ms median / 455.90 ms p95 to 29.70 / 66.70 ms (675 measured frames after warmup), with no browser runtime errors. These are single-host measurements, not a device-independent FPS guarantee.
