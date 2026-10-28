extends RefCounted

const Data = preload("res://scripts/survival/data.gd")
var run: Node
var clocks = {"thunder": 0.0, "frost": 0.0, "sickle": 0.0, "shell": 0.0, "pitchfork": 0.0, "carrot": 0.0, "stink": 0.0, "parrot": 0.0}
const FORK = preload("res://assets/Ninja Adventure - Asset Pack/Items/Weapons/Fork/Sprite.png")

func _init(director: Node):
	run = director

func tick(delta: float):
	for key in clocks:
		clocks[key] -= delta
		if run.ranks.get(key, 0) <= 0 or clocks[key] > 0:
			continue
		var target = run.nearest_enemy()
		# Melee and aura weapons fire without a target in range; the rest need one.
		if target == null and not key in ["pitchfork", "stink"]:
			continue
		run.play_sound(key)
		var rank = run.ranks[key]
		# Counts follow rank; damage follows rarity-weighted level.
		var lv = run.level(key)
		var haste = run.haste_multiplier() * run.ascension_cooldown(key)
		var evolved = run.evolved.has(key)
		var dir = run.player.global_position.direction_to(target.global_position) if target else run.player.facing.normalized()
		match key:
			"thunder":
				clocks[key] = 2.0 * haste
				chain(target, run.storm_target_count(rank), (14 + lv * 6) * run.power())
			"frost":
				clocks[key] = 1.35 * haste
				var count = 1 + int(rank / 2) + (2 if evolved else 0) + (6 if run.ascension == "whiteout" else 0) + run.projectile_bonus()
				for i in range(count):
					var shot = run.make_shot(run.player.global_position, dir.rotated((i - (count - 1) / 2.0) * 0.19), key)
					shot.damage = (9 + lv * 4) * run.power()
					shot.pierce = 2 + rank
					shot.slow_duration = (2.0 + (1.5 if evolved else 0)) * run.duration_multiplier()
					shot.slow_factor = 0.3 if evolved else 0.55
			"sickle":
				clocks[key] = 1.8 * haste
				var count = (4 if run.ascension == "reaping" else 2 if evolved else 1) + run.projectile_bonus()
				for i in range(count):
					var shot = run.make_shot(run.player.global_position, dir.rotated(i * TAU / count), key)
					shot.damage = (14 + lv * 6) * run.power()
					shot.pierce = 999
					shot.returning_weapon = true
					shot.speed = 180
					shot.lifetime = 3
			"shell":
				clocks[key] = 2.3 * haste
				for i in range(1 + run.projectile_bonus()):
					var destination = target.global_position + dir.orthogonal() * (i - run.projectile_bonus() / 2.0) * 18
					var shot = run.make_shot(run.player.global_position, run.player.global_position.direction_to(destination), key)
					shot.damage = (22 + lv * 9) * run.power()
					shot.splash = (26 + lv * 3) * run.area_multiplier() * run.weapon_size_multiplier() * (1.45 if evolved else 1)
					shot.speed = 140
					shot.destination = destination
					shot.detonates = true
			"pitchfork":
				# Megabonk Sword: a quick jab in the direction you face.
				clocks[key] = 0.9 * haste
				var jabs = 1 + (1 if rank >= 6 else 0) + run.projectile_bonus() + (2 if evolved else 0)
				var facing = run.player.facing.normalized()
				var reach = 58.0 * run.area_multiplier() * run.weapon_size_multiplier() * (1.5 if evolved else 1.0)
				for i in range(jabs):
					jab(facing.rotated(i * TAU / jabs), reach, (20 + lv * 9) * run.power(), evolved)
			"carrot":
				# Megabonk Revolver: rapid single shots that favour one target.
				clocks[key] = 0.3 * haste * (0.6 if evolved else 1.0)
				for i in range(1 + run.projectile_bonus()):
					var shot = run.make_shot(run.player.global_position, dir.rotated((i - run.projectile_bonus() / 2.0) * 0.08), key)
					shot.damage = (12 + lv * 6) * run.power()
					shot.pierce = 3 if evolved else 1
					shot.speed = 340
					shot.lifetime = 1.4
			"stink":
				# Megabonk Aura: steady damage and a light slow around you.
				clocks[key] = 0.5 * haste
				var radius = run.stink_radius()
				for enemy in run.nearby_enemies(run.player.global_position, radius + 32):
					if is_instance_valid(enemy) and not enemy.dead and run.player.global_position.distance_to(enemy.global_position) < radius + enemy.radius:
						enemy.apply_slow(0.6, 0.5 if evolved else 0.75)
						run.deal_damage(enemy, (5 + lv * 2.5) * run.power(), Vector2.ZERO, key)
			"parrot":
				# Homing birds that pick their own targets.
				clocks[key] = 2.2 * haste
				var birds = 1 + int(rank / 3) + run.projectile_bonus() + (2 if evolved else 0)
				for i in range(birds):
					var shot = run.make_shot(run.player.global_position, dir.rotated(i * TAU / birds), key)
					shot.damage = (12 + lv * 5) * run.power()
					shot.pierce = 2
					shot.speed = 150
					shot.lifetime = 3.0
					shot.homing = 5.0

func chain(first: Node, jumps: int, damage: float):
	var hit: Array = []
	var target = first
	var previous_position := Vector2.ZERO
	while is_instance_valid(target) and hit.size() < jumps:
		hit.append(target)
		var chilled = target.slow_time > 0
		var pos = target.global_position
		run.effect(pos, "FX/Elemental/Thunder/SpriteSheet.png", Vector2i(16, 28), 0.35, 1.4 * run.weapon_size_multiplier())
		# Only the first target is struck from the sky; subsequent hits conduct along arcs.
		if hit.size() == 1 and run.get_tree().get_nodes_in_group("sky_strikes").size() < 32:
			var strike = preload("res://scripts/survival/lightning_strike.gd").new()
			strike.position = pos
			strike.configure(run.weapon_size_multiplier(), run.evolved.has("thunder"))
			run.add_child(strike)
		elif hit.size() > 1 and run.get_tree().get_nodes_in_group("chain_arcs").size() < 64:
			var arc = preload("res://scripts/survival/chain_lightning.gd").new()
			arc.configure(previous_position, pos, run.weapon_size_multiplier(), run.evolved.has("thunder"), hit.size() - 2)
			run.add_child(arc)
		previous_position = pos
		run.deal_damage(target, damage, Vector2.ZERO, "thunder")
		var next_target = null
		var closest = 115.0 * run.area_multiplier() * run.weapon_size_multiplier() * (1.6 if chilled else 1.0)
		for enemy in run.nearby_enemies(pos, closest + 32):
			if not is_instance_valid(enemy) or enemy.dead or hit.has(enemy):
				continue
			var distance = pos.distance_to(enemy.global_position)
			if distance < closest:
				closest = distance
				next_target = enemy
		target = next_target

# A pitchfork jab: damages everything in a narrow cone and shows a quick thrust.
func jab(direction: Vector2, reach: float, damage: float, evolved: bool):
	var origin = run.player.global_position
	for enemy in run.nearby_enemies(origin, reach + 32):
		if not is_instance_valid(enemy) or enemy.dead: continue
		var offset = enemy.global_position - origin
		if offset.length() < reach + enemy.radius and absf(direction.angle_to(offset)) < 0.5:
			run.deal_damage(enemy, damage, direction, "pitchfork")
	var sprite = Sprite2D.new()
	sprite.texture = Data.icon("pitchfork", false, evolved)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.rotation = direction.angle() + PI / 2
	sprite.position = origin + direction * 10
	sprite.z_index = 4
	run.add_child(sprite)
	var tween = run.create_tween()
	tween.tween_property(sprite, "position", origin + direction * reach * 0.8, 0.09)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.08)
	tween.tween_callback(sprite.queue_free)
