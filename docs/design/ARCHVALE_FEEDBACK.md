# Archvale-inspired feedback

Reference: GameMaker / IDoZ and Jonas Tyroller, [Why Archvale Feels Amazing](https://www.youtube.com/watch?v=vN3fQZvfj4Q). Reviewed the browser transcript and projectile demonstration after direct caption retrieval failed.

- 7:23–8:00: eased animation. The player health bar now shows an immediate health change followed by a short, easing gold damage trail; enemy bars also briefly retain lost health.
- 9:39–11:58: emphasize useful information. Color-matched launch puffs mark new volleys. Normal enemies display small health bars briefly after hits; elite/boss bars stay visible.
- 12:15–14:05: reuse particles and preserve pixel styling. Reuse Ninja Adventure's six-frame smoke strip, nearest filtering and snapped world positions. No new raster art or separate low-resolution render pass.
- 14:13–15:25: avoid continuous rapid-fire knockback. A 0.16-second per-enemy cooldown gates ranged shoves; sickle/orbit use 0.08 seconds. Every hit still deals damage. This deliberately changes crowd control, not damage or fire rate.
- 15:34–17:27: preserve momentum. Impact puffs follow attack direction; dash smoke drifts with movement; death echoes retain the latest impact direction.
- 17:42–18:45: readable flashes. A shader brightens sprite interiors while preserving dark outlines and transparency.

Normal particles cap at 36, leaving 12 slots for hostile cues (48 total). One launch cue per rapid volley limits clutter. Effects pause with gameplay; Options > Effects removes motion without changing knockback rules or hiding health information. No full-screen flashes or hit-stop.
