extends RefCounted

var run: Node
var clocks = {"thunder": 0.0, "frost": 0.0, "sickle": 0.0, "shell": 0.0}

func _init(director: Node):
	run = director

func tick(delta: float):
	for key in clocks:
		clocks[key] -= delta
		if run.ranks.get(key, 0) <= 0 or clocks[key] > 0:
			continue
		var target = run.nearest_enemy()
		if target == null:
			continue
		run.play_sound(key)
		var rank = run.ranks[key]
		var haste = pow(0.9, run.ranks.get("haste", 0)) * run.ascension_cooldown(key)
		var evolved = run.evolved.has(key)
		var dir = run.player.global_position.direction_to(target.global_position)
		match key:
			"thunder":
				clocks[key] = 2.0 * haste
				chain(target, 1 + rank + (3 if evolved else 0) + (12 if run.ascension == "whiteout" else 0) + run.projectile_bonus(), (14 + rank * 6) * run.power())
			"frost":
				clocks[key] = 1.35 * haste
				var count = 1 + int(rank / 2) + (2 if evolved else 0) + (6 if run.ascension == "whiteout" else 0) + run.projectile_bonus()
				for i in range(count):
					var shot = run.make_shot(run.player.global_position, dir.rotated((i - (count - 1) / 2.0) * 0.19), key)
					shot.damage = (9 + rank * 4) * run.power()
					shot.pierce = 2 + rank
					shot.slow_duration = (2.0 + (1.5 if evolved else 0)) * run.duration_multiplier()
					shot.slow_factor = 0.3 if evolved else 0.55
			"sickle":
				clocks[key] = 1.8 * haste
				var count = (4 if run.ascension == "reaping" else 2 if evolved else 1) + run.projectile_bonus()
				for i in range(count):
					var shot = run.make_shot(run.player.global_position, dir.rotated(i * TAU / count), key)
					shot.damage = (14 + rank * 6) * run.power()
					shot.pierce = 999
					shot.returning_weapon = true
					shot.speed = 180
					shot.lifetime = 3
			"shell":
				clocks[key] = 2.3 * haste
				for i in range(1 + run.projectile_bonus()):
					var destination = target.global_position + dir.orthogonal() * (i - run.projectile_bonus() / 2.0) * 18
					var shot = run.make_shot(run.player.global_position, run.player.global_position.direction_to(destination), key)
					shot.damage = (22 + rank * 9) * run.power()
					shot.splash = (26 + rank * 3) * run.area_multiplier() * run.weapon_size_multiplier() * (1.45 if evolved else 1)
					shot.speed = 140
					shot.destination = destination
					shot.detonates = true

func chain(first: Node, jumps: int, damage: float):
	var hit: Array = []
	var target = first
	while is_instance_valid(target) and hit.size() < jumps:
		hit.append(target)
		var chilled = target.slow_time > 0
		var pos = target.global_position
		run.effect(pos, "FX/Elemental/Thunder/SpriteSheet.png", Vector2i(16, 28), 0.35, 1.4 * run.weapon_size_multiplier())
		# Limit overlapping columns in endgame builds without limiting chain damage.
		if run.get_tree().get_nodes_in_group("sky_strikes").size() < 32:
			var strike = preload("res://scripts/survival/lightning_strike.gd").new()
			strike.position = pos
			strike.configure(run.weapon_size_multiplier(), run.evolved.has("thunder"))
			run.add_child(strike)
		run.deal_damage(target, damage, Vector2.ZERO, "thunder")
		var next_target = null
		var closest = 115.0 * run.area_multiplier() * run.weapon_size_multiplier() * (1.6 if chilled else 1.0)
		for enemy in run.enemies:
			if not is_instance_valid(enemy) or enemy.dead or hit.has(enemy):
				continue
			var distance = pos.distance_to(enemy.global_position)
			if distance < closest:
				closest = distance
				next_target = enemy
		target = next_target
