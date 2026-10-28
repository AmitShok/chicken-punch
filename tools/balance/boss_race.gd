extends SceneTree
# How long named builds take to kill each guardian when standing next to it,
# with no fodder, dodging or health growth during the fight. An upper bound on
# offence: if a build cannot win this race, it cannot win a real run.
# Usage: godot --headless --path . --script res://tools/balance/boss_race.gd
const Shot = preload("res://scripts/survival/projectile.gd")
const Data = preload("res://scripts/survival/data.gd")
const LIMIT = 240.0

# name -> [ranks, items, evolved, ascension, training power, below half health]
const BUILDS = {
	"starter_max": [{"egg": 10, "fire": 10, "vitality": 10, "regen": 10}, {"honey": 3, "bead": 3, "lunch": 3}, [], "", 0, false],
	"first_unlocks": [{"egg": 10, "shell": 10, "might": 10, "area": 10}, {"bead": 3, "honey": 3}, [], "", 3, false],
	"first_win": [{"egg": 10, "shell": 10, "haste": 10, "might": 10}, {"bead": 3, "honey": 3}, ["egg"], "", 5, false],
	"four_slot": [{"egg": 10, "shell": 10, "shuriken": 10, "frost": 10, "might": 10, "haste": 10, "area": 10, "projectile_size": 10}, {"crown": 3, "bead": 3}, ["egg", "shell", "frost"], "", 5, false],
	"overcrit_redline": [{"thunder": 10, "frost": 10, "egg": 10, "shell": 10, "crit": 10, "duration": 10, "might": 10, "projectile_count": 10}, {"lens": 10, "berserk": 3, "crown": 3}, ["thunder", "frost", "egg"], "whiteout", 5, true],
	"henpocalypse_roast": [{"egg": 10, "fire": 10, "shell": 10, "frost": 10, "haste": 10, "area": 10, "duration": 10, "might": 10}, {"powder": 3, "crown": 3}, ["egg", "fire", "shell"], "henpocalypse", 5, false],
	"carrot_bonk": [{"carrot": 10, "parrot": 10, "pitchfork": 10, "stink": 10, "luck": 10, "crit": 10, "might": 10, "haste": 10}, {"mallet": 5, "hot_sauce": 5, "lens": 6, "anvil": 3}, ["carrot", "parrot"], "", 5, false]
}

func _initialize(): call_deferred("race")

func race():
	Data.save_path = "user://boss_race.cfg"
	Data.write_save({"muted": true})
	for name in BUILDS:
		var build = BUILDS[name]
		var times: Array = []
		for stage in [1, 2, 3]:
			times.append(await kill_time(build, stage))
		print("RACE %-20s guardian1=%s guardian2=%s final=%s" % [name, fmt(times[0]), fmt(times[1]), fmt(times[2])])
	quit()

func fmt(t: float) -> String:
	return "%5.1fs" % t if t >= 0 else " >%ds" % int(LIMIT)

func kill_time(build: Array, stage: int) -> float:
	var run = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	await process_frame
	run.set_physics_process(false)
	run.player.set_physics_process(false)
	run.player.invulnerability = 1.0e9
	run.rng.seed = 11
	for enemy in run.enemies: enemy.queue_free()
	run.enemies.clear()
	run.ranks = build[0].duplicate()
	run.items = build[1].duplicate()
	for key in build[2]: run.evolved[key] = true
	run.ascension = build[3]
	Data.training(run.save).power = build[4]
	if build[5]: run.player.hp = run.player.max_hp * 0.4
	run.elapsed = [0, 180, 360, 600][stage]
	run.boss_stage = stage
	var boss = run.spawn_enemy("boss", true)
	boss.position = run.player.position + Vector2(55, 0)
	boss.set_physics_process(false)
	var ticks = int(LIMIT * 30)
	var result = -1.0
	for tick in range(ticks):
		run.pending_levels = 0
		run.pending_treasures = 0
		run.spawn_clock = 1.0e9
		run.elite_clock = 1.0e9
		run.treasure_clock = 1.0e9
		if run.ranks.has("fire"):
			run.player.global_position = boss.global_position + Vector2(cos(tick * 0.08), sin(tick * 0.08)) * 30 if is_instance_valid(boss) else run.player.global_position
		run._physics_process(1.0 / 30)
		for child in run.get_children():
			if child is Shot:
				child.set_physics_process(false)
				child._physics_process(1.0 / 30)
		if tick % 6 == 0: await process_frame
		if not is_instance_valid(boss) or boss.dead:
			result = (tick + 1) / 30.0
			break
	run.queue_free()
	await process_frame
	return result
