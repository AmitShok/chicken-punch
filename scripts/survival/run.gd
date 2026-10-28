extends Node2D

const Data = preload("res://scripts/survival/data.gd")
const Shot = preload("res://scripts/survival/projectile.gd")
const Pickup = preload("res://scripts/survival/pickup.gd")
const Interface = preload("res://scripts/survival/interface.gd")
const ENEMY = preload("res://scenes/actors/enemy.tscn")
const Arsenal = preload("res://scripts/survival/arsenal.gd")
const DURATION = 600.0
const MAX_FIRE_PATCHES = 160
const MAX_PICKUPS_PER_KIND = 96
const MAX_IMPACT_EFFECTS = 48
const MAX_ENEMIES = 180
const MUSIC_VOLUME = -17.0
const MUSIC_SILENT = -40.0
const MIGHT_PER_RANK = 0.1
const HASTE_PER_RANK = 0.95
const RARITY_FACTORS = [1.0, 1.5, 2.0]
var potency: Dictionary = {}
var hero = "nugget"
var abilities: RefCounted
# Hold the Line makes orbiting blades spin and strike twice as fast.
var orbit_rush = 0.0
var stink_sprite: Sprite2D
var music_key = ""
var music_clock = 0.0
var combat_grid: Dictionary = {}
var combat_grid_frame = -1
var combat_grid_dirty = true
var pickup_registry: Dictionary = {}
var impact_effects = 0
var large_effects = 0
var fire_damage_clock = 0.0
var projectile_pool: Array = []
var projectile_reserve: Node2D
var target_scan_clock = 0.0
var cached_target: Node
var feedback: Node2D
var arsenal: RefCounted
var ascension = ""
var pending_ascension = ""
var guardians_defeated = 0
var items: Dictionary = {}
var pending_treasures = 0
var paid_chests = 0
var last_chest_paid = 0
var last_chest_note = ""
var pending_evolutions: Array = []
var sound_clocks: Dictionary = {}
var offer_kind = "upgrade"
var offer_rarities: Dictionary = {}
var damage_totals: Dictionary = {}
var skips = 0
# Run stats that feed lifetime quests.
var chests_opened = 0
var dashes = 0
var low_hp_time = 0.0
var new_quests: Array = []
var player: Node
var ui: CanvasLayer
var elapsed = 0.0
var kills = 0

# Coins are run-only; legacy pickup/reward ID "gold" also grants coins.
var coins = 0
var gold_earned = 0
var ended = false
var difficulty = 1.0
var level_id = "meadow"
var difficulty_tier = 0
var reward_multiplier = 1.0
var pending_levels = 0
# Assigning a whole new ranks table (new run, tests, tools) also resets rarity levels.
var ranks: Dictionary = {"egg": 1}:
	set(value):
		ranks = value
		potency = {}
var evolved: Dictionary = {}
var enemies: Array = []
var arena_bounds = Rect2(-540, -400, 1320, 1000)
var cooldowns: Dictionary = {"egg": 0.0, "shuriken": 0.0, "fire": 0.0, "orbit": 0.0}
var spawn_clock = 0.0
var elite_clock = 35.0
var treasure_clock = 25.0
var boss_stage = 0
var final_boss_dead = false
var orbit_clock = 0.0
var orbit_sprites: Array = []
var hazards: Array = []
var fire_trail_started = false
var fire_last_position = Vector2.ZERO
var fire_trail_progress = 0.0
var rerolls = 0
var banishes = 0
var banned: Array = []
var offers: Array = []
var save: Dictionary
var damage_labels = 0
var music: AudioStreamPlayer
var crowd_grid: Dictionary = {}
var sounds: Dictionary = {}
var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	add_to_group("run")
	player = $Chicken
	player.run = self
	arsenal = Arsenal.new(self)
	projectile_reserve = Node2D.new()
	projectile_reserve.name = "ProjectileReserve"
	projectile_reserve.process_mode = Node.PROCESS_MODE_DISABLED
	projectile_reserve.hide()
	add_child(projectile_reserve)
	save = Data.read_save()
	# Build tools are earned by completing quests.
	rerolls = Data.tool_uses(save, "reroll")
	banishes = Data.tool_uses(save, "banish")
	skips = Data.tool_uses(save, "skip")
	feedback = preload("res://scripts/survival/feedback.gd").new()
	feedback.run = self
	add_child(feedback)
	var character = save.get("character", "nugget")
	if not Data.CHARACTERS.has(character):
		character = "nugget"
	ranks = {Data.CHARACTERS[character][1]: 1}
	player.configure_character(character)
	hero = character
	abilities = preload("res://scripts/survival/abilities.gd").new(self)
	player.max_hp += Data.training(save).heart * 10 + {"truffle": 20, "donkey": 30}.get(character, 0)
	player.hp = player.max_hp
	if get_tree().has_meta("difficulty"):
		difficulty = get_tree().get_meta("difficulty")
	level_id = str(get_tree().get_meta("level_id", "meadow"))
	if not Data.LEVELS.has(level_id): level_id = "meadow"
	difficulty_tier = clampi(int(get_tree().get_meta("difficulty_tier", 0)), 0, 2)
	reward_multiplier = Data.DIFFICULTIES[difficulty_tier].reward
	preload("res://scripts/survival/level_layout.gd").apply(self, level_id)
	$MobTimer/MobTimer.stop()
	$GUIlayer.hide()
	$CanvasModulate.color = Data.LEVELS[level_id].tint
	$PointLight2D.hide()
	var ground = get_node("Ground layer")
	var used: Rect2i = ground.get_used_rect()
	if used.size.x > 10:
		arena_bounds = Rect2(Vector2(used.position) * 16 + Vector2(24, 24), Vector2(used.size) * 16 - Vector2(48, 48))
	ui = Interface.new()
	ui.run = self
	add_child(ui)
	setup_audio_buses()
	play_music(level_id)
	var clips = {
		"hit": ["Hit & Impact/Hit1.wav", -12], "impact": ["Hit & Impact/Hit2.wav", -29], "pickup": ["Bonus/Coin.wav", -26],
		"upgrade": ["Bonus/PowerUp1.wav", -14], "evolution": ["Bonus/PowerUp2.wav", -10],
		"egg": ["Whoosh & Slash/Launch.wav", -23], "shuriken": ["Whoosh & Slash/Slash2.wav", -23],
		"fire": ["Elemental/Fire2.wav", -28], "orbit": ["Whoosh & Slash/Slash.wav", -28],
		"thunder": ["Elemental/Explosion5.wav", -22], "frost": ["Elemental/Water4.wav", -22],
		"sickle": ["Whoosh & Slash/Whoosh2.wav", -22], "shell": ["Elemental/Fireball.wav", -24],
		"explosion": ["Elemental/Explosion2.wav", -24], "dash": ["Creature/Wings.wav", -17],
		"select": ["Menu/Accept2.wav", -15], "chest": ["Menu/Accept8.wav", -13],
		"critical": ["Hit & Impact/Hit3.wav", -27], "defeat": ["Menu/Cancel2.wav", -12]
	}
	for key in clips:
		var sound = AudioStreamPlayer.new()
		sound.stream = load(Data.PACK + "Audio/Sounds/" + clips[key][0])
		sound.volume_db = clips[key][1]
		sound.bus = "SFX"
		sound.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(sound)
		sounds[key] = sound
	apply_audio_settings()
	AudioServer.set_bus_mute(0, save.muted)
	for i in range(3):
		drop("chest", walkable_position(150 + i * 55), 1)
	ui.announce(Data.LEVELS[level_id].name.to_upper(), Data.DIFFICULTIES[difficulty_tier].name + " · Defeat the final guardian at 10:00.")

func _physics_process(delta):
	if ended:
		return
	enemies = enemies.filter(func(e): return is_instance_valid(e) and not e.dead)
	if pending_ascension != "" and not ui.modal_open:
		ui.show_ascension(pending_ascension)
		pending_ascension = ""
		get_tree().paused = true
		return
	if not pending_evolutions.is_empty() and not ui.modal_open:
		ui.show_evolution(pending_evolutions.pop_front())
		get_tree().paused = true
		return
	if pending_treasures > 0 and not ui.modal_open:
		show_treasure()
		return
	if pending_levels > 0 and not ui.modal_open:
		show_upgrades()
		return
	crowd_grid.clear()
	for enemy in enemies:
		var cell = Vector2i((enemy.global_position / 32).floor())
		if not crowd_grid.has(cell):
			crowd_grid[cell] = []
		crowd_grid[cell].append(enemy)
	rebuild_combat_grid()
	target_scan_clock -= delta
	elapsed += delta
	spawn_clock -= delta
	if player.hp < player.max_hp * 0.5: low_hp_time += delta
	if spawn_clock <= 0 and not final_boss_dead:
		var minute = int(elapsed / 60)
		spawn_clock = maxf(0.12, 0.85 - minute * 0.075) / Data.LEVELS[level_id].pressure
		var count = 2 + int(minute / 2)
		for i in range(count):
			if enemies.size() >= MAX_ENEMIES - 4:
				break
			var type = "dog"
			var roll = rng.randf()
			if elapsed > 35 and roll < 0.25:
				type = "bat"
			if elapsed > 90 and roll > 0.7:
				type = "tank"
			if elapsed > 150 and roll > 0.88:
				type = "caster"
			if level_id == "orchard" and elapsed > 20 and roll < 0.4: type = "bat"
			if level_id == "pasture" and elapsed > 65 and roll > 0.75: type = "caster"
			spawn_enemy(type)
	elite_clock -= delta
	if elite_clock <= 0 and not final_boss_dead:
		elite_clock = maxf(20, 48 - elapsed / 30)
		spawn_enemy("tank", true)
		ui.announce("ELITE ON THE HUNT", "Gold-ring enemies drop treasure. Prepare an evolution!")
	treasure_clock -= delta
	if treasure_clock <= 0:
		treasure_clock = 50
		drop("chest", walkable_position(220), 1)
		drop("magnet", walkable_position(120), 1)
	if (boss_stage == 0 and elapsed >= 180) or (boss_stage == 1 and elapsed >= 360) or (boss_stage == 2 and elapsed >= DURATION):
		boss_stage += 1
		spawn_enemy("boss", true)
		ui.announce("GUARDIAN %d / 3" % boss_stage, "Rotating rings and aimed volleys. The horde keeps coming.")
	music_clock -= delta
	if music_clock <= 0:
		music_clock = 0.5
		play_music(music_phase())
	for key in cooldowns:
		cooldowns[key] -= delta
	attack_weapons()
	arsenal.tick(delta)
	update_orbits(delta)
	update_stink_aura(delta)
	update_hazards(delta)
	if final_boss_dead:
		finish(true)

func walkable_position(distance: float) -> Vector2:
	# Test the actual map physics before placing rewards or spawning enemies.
	var shape = CircleShape2D.new()
	shape.radius = 10
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = 1
	# Clamping to the arena pulls points toward the player, so near walls an enemy
	# could appear on screen. Prefer unclamped points; otherwise keep the farthest one.
	var fallback = player.global_position + Vector2(0, 30)
	var fallback_distance = -1.0
	for attempt in range(32):
		var pos = player.global_position + Vector2.RIGHT.rotated(rng.randf() * TAU) * distance
		pos = pos.clamp(arena_bounds.position + Vector2(16, 16), arena_bounds.end - Vector2(16, 16))
		query.transform = Transform2D(0, pos)
		if not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty() or on_water(pos):
			continue
		var reach = player.global_position.distance_to(pos)
		if reach >= distance - 1.0:
			return pos
		if reach > fallback_distance:
			fallback = pos
			fallback_distance = reach
	return fallback

# The pond has no collision, so physics alone lets chests land in it.
func on_water(pos: Vector2) -> bool:
	var ground = get_node_or_null("Ground layer")
	if ground == null: return false
	var layers: Array = [ground]
	layers.append_array(ground.get_children().filter(func(c): return c is TileMapLayer))
	for layer in layers:
		var source_id = layer.get_cell_source_id(layer.local_to_map(layer.to_local(pos)))
		if source_id == -1: continue
		var source = layer.tile_set.get_source(source_id)
		if source is TileSetAtlasSource and source.texture and source.texture.resource_path.contains("TilesetWater"):
			return true
	return false

func spawn_enemy(type: String, champion: bool = false):
	if type != "boss" and enemies.size() >= MAX_ENEMIES: return null
	var enemy = ENEMY.instantiate()
	enemy.position = walkable_position(310)
	add_child(enemy)
	enemy.configure(self, type, champion)
	enemies.append(enemy)
	combat_grid_dirty = true
	return enemy

func power() -> float:
	return 1.0 + level("might") * MIGHT_PER_RANK + Data.training(save).power * 0.05 + (0.1 if hero == "donkey" else 0.0) + (items.get("berserk", 0) * 0.25 if player.hp < player.max_hp * 0.5 else 0.0)

func area_multiplier() -> float:
	return 1.0 + level("area") * 0.18 + (0.15 if hero == "clover" else 0.0)

func nearest_enemy():
	if target_scan_clock > 0 and is_instance_valid(cached_target) and not cached_target.dead and cached_target.global_position.distance_squared_to(player.global_position) < 115600: return cached_target
	var result = null
	var distance = 340.0 * 340.0
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.dead:
			var d = player.global_position.distance_squared_to(enemy.global_position)
			if d < distance:
				result = enemy
				distance = d
	cached_target = result
	target_scan_clock = 0.08
	return result

func attack_weapons():
	var target = nearest_enemy()
	var haste = haste_multiplier()
	for key in ["egg", "shuriken"]:
		var rank = ranks.get(key, 0)
		if rank == 0 or cooldowns[key] > 0 or target == null:
			continue
		play_sound(key)
		var dir = player.global_position.direction_to(target.global_position)
		cooldowns[key] = (0.85 if key == "egg" else 1.6) * haste * ascension_cooldown(key)
		var count = (1 + int(rank / 2) if key == "egg" else rank + 2) + projectile_bonus()
		if evolved.has(key):
			count += 3
		if key == "egg" and ascension == "henpocalypse":
			count += 8
		for i in range(count):
			var angle = (i - (count - 1) / 2.0) * 0.14
			var shot = make_shot(player.global_position, dir.rotated(angle), key)
			shot.damage = ((13 if key == "egg" else 10) + level(key) * 4) * power()
			shot.pierce = 1 if key == "egg" else 2 + rank
			if key == "egg" and evolved.has(key):
				shot.splash = 30 * area_multiplier() * weapon_size_multiplier() * (1.8 if ascension == "henpocalypse" else 1.0)
	update_fire_trail()

func fire_spacing() -> float:
	return 65.0 * haste_multiplier() * ascension_cooldown("fire") / (1 + projectile_bonus())

func update_fire_trail():
	if ranks.get("fire", 0) <= 0:
		fire_trail_started = false
		return
	var position_now = player.global_position
	var distance = fire_last_position.distance_to(position_now)
	if not fire_trail_started or distance > 512:
		fire_trail_started = true
		fire_last_position = position_now
		fire_trail_progress = 0.0
		spawn_fire_patch(position_now)
		return
	if distance > 0.001:
		# Measure distance along each movement segment, including corners/dashes.
		var spacing = fire_spacing()
		var next = maxf(0.0, spacing - fire_trail_progress)
		while next <= distance + 0.0001:
			spawn_fire_patch(fire_last_position.lerp(position_now, minf(1.0, next / distance)))
			next += spacing
		fire_trail_progress = maxf(0.0, distance - (next - spacing))
	elif cooldowns.fire <= 0:
		spawn_fire_patch(position_now)
		fire_trail_progress = 0.0
	fire_last_position = position_now

func spawn_fire_patch(pos: Vector2):
	cooldowns.fire = fire_spacing() / 100.0
	var fire_level = level("fire")
	var life = (2.0 + fire_level * 0.5) * duration_multiplier()
	var damage = (5 + fire_level * 3) * power()
	# Sub-pixel piles and standing still refresh existing fire instead of multiplying DPS.
	for existing in hazards:
		if existing.sprite.position.distance_squared_to(pos) < 16:
			existing.life = maxf(existing.life, life)
			existing.damage = maxf(existing.damage, damage)
			return
	play_sound("fire")
	var sprite: Sprite2D
	if hazards.size() >= MAX_FIRE_PATCHES:
		var oldest = hazards.pop_front()
		sprite = oldest.sprite
	else:
		sprite = Sprite2D.new()
		sprite.texture = preload("res://assets/Ninja Adventure - Asset Pack/FX/Particle/Fire.png")
		sprite.hframes = 12
		add_child(sprite)
	sprite.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	sprite.frame = 0
	sprite.position = pos
	sprite.scale = Vector2.ONE * area_multiplier() * weapon_size_multiplier() * (1.6 if evolved.has("fire") else 1)
	if not sprite.has_node("Range"):
		var ring = preload("res://scripts/survival/fire_range.gd").new()
		ring.name = "Range"
		sprite.add_child(ring)
	if evolved.has("fire") and not sprite.has_node("Phoenix"):
		var phoenix = Sprite2D.new()
		phoenix.name = "Phoenix"
		phoenix.texture = Data.icon("fire", false, true)
		phoenix.position.y = -7
		sprite.add_child(phoenix)
	hazards.append({"sprite": sprite, "age": 0.0, "life": life, "tick": 0.0, "radius": 17 * sprite.scale.x, "damage": damage})

func make_shot(pos: Vector2, dir: Vector2, type: String):
	var shot = projectile_pool.pop_back() if not projectile_pool.is_empty() else Shot.new()
	if shot.get_parent(): shot.get_parent().remove_child(shot)
	shot.reset_projectile()
	shot.run = self
	shot.z_index = 1
	shot.position = pos
	shot.direction = dir
	shot.source = type
	var sprite = shot.get_node_or_null("Sprite")
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite"
		shot.add_child(sprite)
	sprite.hframes = 1
	sprite.rotation = 0
	sprite.flip_h = false
	sprite.scale = Vector2.ONE
	if type == "egg":
		sprite.texture = load("res://assets/sprites/egg_sprite.png")
	elif type == "sickle":
		sprite.texture = Data.icon("sickle")
	elif type == "shell":
		sprite.texture = load(Data.PACK + "FX/Projectile/CanonBall.png")
		sprite.hframes = 5
	elif type == "frost":
		var atlas = AtlasTexture.new()
		atlas.atlas = load(Data.PACK + "FX/Projectile/IceSpike.png")
		atlas.region = Rect2(0, 0, 18, 10)
		sprite.texture = atlas
		sprite.rotation = dir.angle()
	elif type == "carrot":
		sprite.texture = load(Data.PACK + "Items/Food/SeedBig1.png")
	elif type == "parrot":
		var bird = AtlasTexture.new()
		bird.atlas = load(Data.PACK + "Actor/Animals/Parrot/SpriteSheetBlue.png")
		bird.region = Rect2(0, 0, 16, 16)
		sprite.texture = bird
		sprite.flip_h = dir.x < 0
	else:
		sprite.texture = load(Data.PACK + "FX/Projectile/" + ("Fireball.png" if type == "hostile" else "Shuriken.png"))
		sprite.hframes = maxi(1, int(sprite.texture.get_width() / 16))
	if evolved.has(type):
		sprite.texture = Data.icon(type, false, true)
		sprite.hframes = 1
		sprite.rotation = dir.angle() + (-3 * PI / 4 if type == "shell" else PI / 4 if type == "frost" else 0)
	if type != "hostile":
		shot.speed_scale = projectile_speed_multiplier()
		shot.hit_radius = 4.0 * weapon_size_multiplier()
		sprite.scale = Vector2.ONE * weapon_size_multiplier()
	shot.spin = type in ["shuriken", "sickle"]
	add_child(shot)
	shot.reset_physics_interpolation()
	feedback.launch(pos, dir, type)
	return shot

func enemy_bullet(pos: Vector2, dir: Vector2, damage: float):
	var shot = make_shot(pos, dir, "hostile")
	shot.hostile = true
	shot.damage = damage
	shot.speed = 85 + minf(25, elapsed / 24)
	shot.lifetime = 5
	shot.modulate = Color("ff937a")

func update_orbits(delta):
	var rank = ranks.get("orbit", 0)
	var count = 0 if rank == 0 else 1 + int(rank / 2) + (2 if evolved.has("orbit") else 0) + (8 if ascension == "reaping" else 0) + projectile_bonus()
	while orbit_sprites.size() < count:
		var sprite = Sprite2D.new()
		sprite.texture = load(Data.PACK + "Items/Weapons/Sai/Sprite.png")
		add_child(sprite)
		orbit_sprites.append(sprite)
	orbit_rush = maxf(0, orbit_rush - delta)
	orbit_clock += delta * 2.4 * projectile_speed_multiplier() * (2 if ascension == "reaping" else 1) * (2 if orbit_rush > 0 else 1)
	for i in range(orbit_sprites.size()):
		var angle = orbit_clock + i * TAU / count
		var pos = player.global_position + Vector2.RIGHT.rotated(angle) * 35 * area_multiplier()
		orbit_sprites[i].texture = Data.icon("orbit", false, evolved.has("orbit"))
		orbit_sprites[i].scale = Vector2.ONE * weapon_size_multiplier()
		orbit_sprites[i].position = pos
		# Both guard sprites point up; rotate their blade into the clockwise tangent.
		orbit_sprites[i].rotation = angle + PI
	if rank > 0 and cooldowns.orbit <= 0:
		cooldowns.orbit = 0.22 * haste_multiplier() * (0.5 if orbit_rush > 0 else 1.0)
		for sprite in orbit_sprites:
			blast(sprite.position, 15 * area_multiplier() * weapon_size_multiplier(), (5 + level("orbit") * 3) * power(), false, "orbit")

func update_hazards(delta):
	fire_damage_clock -= delta
	var burn_tick = fire_damage_clock <= 0
	if burn_tick: fire_damage_clock = 0.4
	var burning: Dictionary = {}
	for i in range(hazards.size() - 1, -1, -1):
		var h = hazards[i]
		h.life -= delta
		h.age += delta
		h.tick -= delta
		if h.life <= 0:
			h.sprite.queue_free()
			hazards.remove_at(i)
		else:
			# The range ring fades out with the embers.
			var ring = h.sprite.get_node_or_null("Range")
			if ring: ring.modulate.a = clampf(h.life * 3.0, 0.0, 1.0)
			# The pack contains twelve 8x12 frames: ignition, flame, then embers.
			# Animation runs independently of the 0.4-second damage interval.
			if h.life < 1.0 / 3.0:
				h.sprite.frame = mini(11, 8 + int((1.0 / 3.0 - h.life) * 12.0))
			elif h.age < 0.25:
				h.sprite.frame = mini(2, int(h.age * 12.0))
			else:
				h.sprite.frame = 3 + int((h.age - 0.25) * 12.0) % 5
			if burn_tick:
				for enemy in nearby_enemies(h.sprite.position, h.radius + 32):
					if is_instance_valid(enemy) and not enemy.dead and h.sprite.position.distance_squared_to(enemy.global_position) < pow(h.radius + enemy.radius, 2):
						burning[enemy] = maxf(burning.get(enemy, 0), h.damage)
	for enemy in burning:
		if is_instance_valid(enemy) and not enemy.dead: deal_damage(enemy, burning[enemy], Vector2.ZERO, "fire")

func blast(pos: Vector2, radius: float, damage: float, visual: bool = true, source: String = "egg"):
	for enemy in nearby_enemies(pos, radius + 32):
		if is_instance_valid(enemy) and not enemy.dead and pos.distance_squared_to(enemy.global_position) < pow(radius + enemy.radius, 2):
			deal_damage(enemy, damage, pos.direction_to(enemy.global_position), source)
	if visual:
		effect(pos, "FX/Elemental/Explosion/SpriteSheet.png", Vector2i(40, 40), 0.35, radius / 20.0)

func enemy_died(enemy):
	feedback.defeated(enemy)
	kills += 1
	if items.get("blood_seed", 0) > 0 and kills % 15 == 0:
		player.hp = minf(player.max_hp, player.hp + 3 * items.blood_seed)
	if items.get("powder", 0) > 0 and kills % 8 == 0:
		# Deferred explosions avoid recursive death chains inside the hit iteration.
		powder_burst.call_deferred(enemy.global_position)
	drop("xp", enemy.global_position, 5 if enemy.kind == "tank" else 3)
	# Pirate Flock: evolved parrots bring back coins from their kills.
	if enemy.last_source == "parrot" and evolved.has("parrot") and rng.randf() < 0.3:
		drop("gold", enemy.global_position + Vector2(6, 0), 1)
	if enemy.elite:
		drop("chest", enemy.global_position, 0)
		coins += 10
	if enemy.boss:
		guardians_defeated += 1
		coins += 30
		drop("magnet", enemy.global_position + Vector2(15, 0), 1)
		if enemy.final_guardian:
			final_boss_dead = true
	elif rng.randf() < 0.08:
		drop("heal", enemy.global_position, 12)
	elif rng.randf() < 0.24:
		drop("gold", enemy.global_position, 1)

func drop(type: String, pos: Vector2, amount: int):
	# Preserve total rewards while bounding every common pickup type, not only XP.
	if type in ["xp", "gold", "heal"]:
		var pool: Array = pickup_registry.get(type, []).filter(func(p): return is_instance_valid(p) and not p.is_queued_for_deletion())
		pickup_registry[type] = pool
		var nearest = null
		var distance = INF
		for existing in pool:
			var d = existing.position.distance_squared_to(pos)
			if d < distance:
				nearest = existing
				distance = d
		if nearest != null and (distance < 576 or pool.size() >= MAX_PICKUPS_PER_KIND):
			nearest.value += amount
			return nearest
	var pickup = Pickup.new()
	pickup.run = self
	if type in ["xp", "gold", "heal"]: pickup_registry[type].append(pickup)
	pickup.kind = type
	pickup.value = amount
	pickup.chest_free = type == "chest" and amount == 0
	pickup.position = pos
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	var path = "res://assets/sprites/bone.png"
	match type:
		"gold": path = Data.PACK + "Items/Treasure/GoldCoin.png"
		"chest": path = Data.PACK + "Items/Treasure/LittleTreasureChest.png"
		"heal": path = Data.PACK + "Items/Potion/Heart.png"
		"magnet": path = "res://assets/Coop/magnet.png"
	sprite.texture = load(path)
	if type == "chest":
		sprite.hframes = 2
		if pickup.chest_free:
			sprite.modulate = Color("9be7e0")
	pickup.add_child(sprite)
	pickup.add_to_group("run_pickups")
	add_child(pickup)
	return pickup

func collect(item):
	play_sound("pickup")
	match item.kind:
		"xp": player.gain_xp(maxi(1, roundi(item.value * (1 + level("magnet") * 0.1 + items.get("compass", 0) * 0.12 + (0.1 if hero == "nugget" else 0.0)))))
		"gold": coins += roundi(item.value * coin_multiplier())
		"heal": player.hp = minf(player.max_hp, player.hp + item.value)
		"magnet":
			for pickup in get_tree().get_nodes_in_group("run_pickups"):
				if pickup.kind == "xp" or pickup.kind == "gold":
					pickup.pulled = true
			ui.announce("FORAGER'S CALL", "All experience and coins are coming to you.")
		"chest":
			play_sound("chest")
			player.hp = minf(player.max_hp, player.hp + items.get("lunch", 0) * 12)
			if ascension == "":
				for key in Data.ASCENSIONS:
					if ascension_ready(key):
						ascension = key
						pending_ascension = key
						ui.refresh_inventory()
						return
			for weapon in Data.EVOLUTIONS:
				var recipe = Data.EVOLUTIONS[weapon]
				if ranks.get(weapon, 0) >= Data.MAX_RANK and ranks.get(recipe[0], 0) >= 1 and not evolved.has(weapon):
					evolved[weapon] = true
					pending_evolutions.append(weapon)
					ui.refresh_inventory()
					ui.announce("EVOLVED: " + recipe[1].to_upper(), "Your build has transformed.")
					return
			pending_treasures += 1
			ui.announce("TREASURE FOUND", "A random item awaits.")

func owned_count(weapons: bool) -> int:
	var count = 0
	for key in ranks:
		if ranks[key] > 0 and (key in Data.WEAPONS) == weapons:
			count += 1
	return count

func eligible_upgrades() -> Array:
	var pool: Array = []
	for key in Data.UPGRADES:
		if (not Data.equipment_owned(save, key) and ranks.get(key, 0) == 0) or ranks.get(key, 0) >= Data.UPGRADES[key][3] or banned.has(key):
			continue
		var weapon = key in Data.WEAPONS
		var limit = Data.slot_limit(save, weapon)
		if ranks.get(key, 0) == 0 and owned_count(weapon) >= limit:
			continue
		pool.append(key)
	return pool

func roll_rarity() -> int:
	var roll = rng.randf()
	var luck = items.get("clover", 0) * 0.06 + level("luck") * 0.04
	if roll < 0.05 + luck * 0.25:
		return 2
	if roll < 0.30 + luck:
		return 1
	return 0

func show_upgrades():
	offer_kind = "upgrade"
	play_sound("upgrade")
	var pool = eligible_upgrades()
	offers.clear()
	offer_rarities.clear()
	# The opening draft always includes a new weapon, if one remains eligible.
	if owned_count(true) < 2:
		var weapons = pool.filter(func(key): return key in Data.WEAPONS and ranks.get(key, 0) == 0)
		if not weapons.is_empty():
			var key = weapons[rng.randi_range(0, weapons.size() - 1)]
			offers.append(key)
			pool.erase(key)
	while offers.size() < 3 and not pool.is_empty():
		offers.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	for key in offers:
		offer_rarities[key] = roll_rarity() if ranks.get(key, 0) > 0 or key == "projectile_count" else 0
	if offers.is_empty():
		offers = ["feast", "gold"]
	ui.show_choices()
	get_tree().paused = true

func show_treasure():
	offer_kind = "item"
	play_sound("upgrade")
	offers.clear()
	offer_rarities.clear()
	var pool = Data.ITEMS.keys().filter(func(key): return Data.equipment_owned(save, key, true) and items.get(key, 0) < Data.MAX_ITEM_LEVEL)
	while offers.size() < 1 and not pool.is_empty():
		var weights: Array[float] = []
		var total = 0.0
		for key in pool:
			var weight = [6.0, 3.0, 1.0][Data.ITEMS[key][3]]
			weight *= 1 + items.get("clover", 0) * 0.25 + level("luck") * 0.15 if Data.ITEMS[key][3] > 0 else 1.0
			weights.append(weight)
			total += weight
		var roll = rng.randf() * total
		var selected = pool.size() - 1
		for i in range(pool.size()):
			roll -= weights[i]
			if roll <= 0:
				selected = i
				break
		var key = pool.pop_at(selected)
		offers.append(key)
		offer_rarities[key] = Data.ITEMS[key][3]
	if offers.is_empty():
		offers = ["gold"]
	ui.show_chest_reward()
	get_tree().paused = true

func offered_rank(key: String) -> int:
	return mini(Data.MAX_RANK, ranks.get(key, 0) + 1)

# Stat strength one pick adds: Megabonk-style rarity factors, plus Rusty Anvil on weapons.
func offered_gain(key: String) -> float:
	var gain = RARITY_FACTORS[offer_rarities.get(key, 0)]
	if key in Data.WEAPONS: gain += items.get("anvil", 0) * 0.25
	return gain

# A key's stat level: picks weighted by rarity. Falls back to rank when set directly.
func level(key: String) -> float:
	return potency.get(key, float(ranks.get(key, 0)))

func choose_upgrade(key: String):
	if not offers.has(key):
		return
	var previously_active: Array[String] = []
	for synergy in Data.SYNERGIES:
		if synergy_active(synergy):
			previously_active.append(synergy)
	play_sound("select")
	if key == "feast":
		player.hp = minf(player.max_hp, player.hp + 30)
	elif key == "gold":
		coins += maxi(15, last_chest_paid) if offer_kind == "item" else 15
	elif offer_kind == "item":
		items[key] = mini(Data.MAX_ITEM_LEVEL, items.get(key, 0) + 1)
		if key == "oats":
			player.max_hp += 10
			player.hp = minf(player.max_hp, player.hp + 10)
		ui.announce(Data.ITEMS[key][0].to_upper(), "Level %d / 10  |  %s" % [items[key], Data.ITEMS[key][1]])
	else:
		# Every pick is one level; rarity makes that level's stats stronger.
		var gain_level = offered_gain(key)
		potency[key] = level(key) + gain_level
		ranks[key] = offered_rank(key)
		if key == "vitality":
			var gain = roundi(gain_level * 20)
			player.max_hp += gain
			player.hp = minf(player.max_hp, player.hp + gain)
		player.movement_speed = 100 * (1 + level("speed") * 0.08)
	if offer_kind == "item":
		pending_treasures = maxi(0, pending_treasures - 1)
	else:
		pending_levels = maxi(0, pending_levels - 1)
	var activated: Array[String] = []
	for synergy in Data.SYNERGIES:
		if synergy_active(synergy) and not previously_active.has(synergy):
			activated.append(Data.SYNERGIES[synergy][0])
	if not activated.is_empty():
		ui.announce("SYNERGY ACTIVE", " + ".join(activated) + "  /  Details in ESC > Loadout")
		play_sound("upgrade")
	offers.clear()
	ui.refresh_inventory()
	ui.close_modal()
	get_tree().paused = false

func reroll():
	if rerolls <= 0 or offer_kind == "item":
		return
	rerolls -= 1
	show_upgrades()

func banish(key: String):
	if offer_kind != "upgrade" or banishes <= 0 or not Data.UPGRADES.has(key) or not offers.has(key):
		return
	banishes -= 1
	banned.append(key)
	show_upgrades()

func skip_offer():
	if skips <= 0 or offer_kind != "upgrade":
		return
	skips -= 1
	pending_levels = maxi(0, pending_levels - 1)
	offers.clear()
	ui.close_modal()
	get_tree().paused = false

func finish(won: bool):
	if ended:
		return
	ended = true
	play_sound("evolution" if won else "defeat")
	play_music("victory" if won else "defeat")
	# Gold rewards time, kills and guardians, so short early runs still fund unlocks.
	gold_earned = roundi((int(elapsed / 15) + int(kills / 40) + guardians_defeated * 10 + (50 if won else 0)) * reward_multiplier)
	save.gold += gold_earned
	if won:
		save.wins += 1
		save.level_clears[level_id] = maxi(save.level_clears.get(level_id, 0), difficulty_tier + 1)
	var weapon_ranks = ranks.keys().filter(func(k): return k in Data.WEAPONS).map(func(k): return ranks[k])
	new_quests = Data.record_run(save, {
		"best_time": int(elapsed), "best_level": player.level, "best_guardians": guardians_defeated,
		"best_rank": weapon_ranks.max() if not weapon_ranks.is_empty() else 0, "best_crit": ranks.get("crit", 0),
		"best_dashes": dashes, "best_low_hp": int(low_hp_time), "best_tier_won": difficulty_tier + 1 if won else 0,
		"kills": kills, "chests": chests_opened, "guardians": guardians_defeated, "evolutions": evolved.size(),
		"evolved_fire": 1 if evolved.has("fire") else 0, "wins": 1 if won else 0, "runs": 1})
	Data.write_save(save)
	ui.show_result(won)
	get_tree().paused = true

func floating_text(pos: Vector2, message: String, color: Color):
	if damage_labels >= 35:
		return
	damage_labels += 1
	var label = Label.new()
	label.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	label.text = message
	label.position = pos + Vector2(-7, -18)
	label.add_theme_font_size_override("font_size", 10)
	label.modulate = color
	label.z_index = 20
	add_child(label)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 18, 0.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(func():
		damage_labels -= 1
		label.queue_free())

func _on_mob_timer_timeout():
	pass


func _exit_tree():
	if is_instance_valid(music):
		music.stop()
	for sound in sounds.values():
		if is_instance_valid(sound):
			sound.stop()



func play_sound(key: String):
	if DisplayServer.get_name() == "headless" or not sounds.has(key):
		return
	var now = Time.get_ticks_msec()
	var gap = 180 if key in ["critical", "pickup", "explosion"] else 100
	if now - sound_clocks.get(key, -1000) < gap or sounds[key].playing:
		return
	sound_clocks[key] = now
	sounds[key].pitch_scale = randf_range(0.95, 1.05) if key not in ["upgrade", "evolution", "defeat", "select"] else 1.0
	sounds[key].play()

func separation(enemy) -> Vector2:
	var force = Vector2.ZERO
	var cell = Vector2i((enemy.global_position / 32).floor())
	for y in range(-1, 2):
		for x in range(-1, 2):
			for other in crowd_grid.get(cell + Vector2i(x, y), []):
				if other == enemy or not is_instance_valid(other) or other.dead:
					continue
				var offset = enemy.global_position - other.global_position
				var distance = offset.length()
				if distance > 0.1 and distance < 17:
					force += offset / distance * (17 - distance) * 2
	return force.limit_length(25)




func storm_target_count(rank: int = -1) -> int:
	if rank < 0: rank = ranks.get("thunder", 0)
	# Chaining unlocks at rank two, including bonus targets from tomes.
	if rank <= 1: return maxi(0, rank)
	return rank + projectile_bonus() + (3 if evolved.has("thunder") else 0) + (12 if ascension == "whiteout" else 0)

func duration_multiplier() -> float:
	return 1.0 + level("duration") * 0.2

func critical_chance() -> float:
	return level("crit") * 0.08 + items.get("lens", 0) * 0.08 + (0.1 if hero == "whisker" else 0.0)

func critical_tier(roll: float) -> int:
	var chance = critical_chance()
	return floori(chance) + (1 if roll < fmod(chance, 1.0) else 0)

func slow_roast_ready() -> bool:
	return evolved.has("fire") and items.get("powder", 0) >= 3 and ranks.get("duration", 0) >= 5

func pickup_radius() -> float:
	return 45.0 + level("magnet") * 30 + items.get("magnet_stone", 0) * 25

func armor_value() -> int:
	return roundi(level("armor")) + items.get("bead", 0) + (1 if hero == "truffle" else 0)

func regeneration() -> float:
	return level("regen") * 0.4 + items.get("honey", 0) * 0.3 + (0.5 if hero == "frog" else 0.0)

func ability_recharge() -> float:
	return abilities.cooldown()

# Evasion tome: a chance to ignore a hit entirely, capped at 40%.
func dodge_chance() -> float:
	return minf(0.4, level("evasion") * 0.04)

# Greed tome and the parrot's passive raise run coin income.
func coin_multiplier() -> float:
	return 1.0 + level("greed") * 0.12 + (0.25 if hero == "parrot" else 0.0)

func stink_radius() -> float:
	return (40 + level("stink") * 2) * area_multiplier() * weapon_size_multiplier() * (1.5 if evolved.has("stink") else 1.0)

# Thorns tome: enemies that land a hit take damage back.
func on_player_struck(enemy: Node):
	if level("thorns") > 0 and is_instance_valid(enemy) and not enemy.dead:
		deal_damage(enemy, (8 + level("thorns") * 6) * power(), player.global_position.direction_to(enemy.global_position), "thorns")

func deal_damage(enemy: Node, amount: float, direction: Vector2, source: String):
	if not is_instance_valid(enemy) or enemy.dead:
		return
	amount *= ascension_damage(source)
	if enemy.elite or enemy.boss:
		amount *= 1 + items.get("crown", 0) * 0.2
	if source == "thunder" and enemy.slow_time > 0:
		amount *= 1.35
	if source == "fire" and enemy.slow_time > 0 and enemy.steam_lock <= 0:
		enemy.slow_time = 0
		enemy.steam_lock = 3.0
		steam_burst.call_deferred(enemy.global_position, amount)
	# Heat is one counter per enemy; it never creates recursive damage events.
	if source == "fire" and slow_roast_ready():
		enemy.roast_stacks = mini(30, enemy.roast_stacks + 1)
		enemy.roast_time = 2.0 * duration_multiplier()
	elif source in Data.WEAPONS and enemy.roast_time > 0:
		amount *= 1.0 + enemy.roast_stacks * 0.08
	if hero == "pepper" and source in ["fire", "hotwings"]:
		amount *= 1.25
	# Golden Carrot: evolved Carrot Cannon shots crit far more often.
	var tier = critical_tier(rng.randf() - (0.25 if source == "carrot" and evolved.has("carrot") else 0.0))
	var critical = tier > 0
	# Hot Sauce raises the critical multiplier itself, so it compounds with overcrits.
	amount *= pow(2.0 + items.get("hot_sauce", 0) * 0.25, tier)
	if tier >= 2 and items.get("berserk", 0) >= 3 and player.hp < player.max_hp * 0.5:
		amount *= 2.0
	# On-hit procs skip damage-over-time ticks so they never chain into themselves.
	if not source in ["poison", "thorns"]:
		if rng.randf() < items.get("mallet", 0) * 0.02:
			amount *= 20.0
			floating_text(enemy.global_position + Vector2(0, -10), "BONK!", Color("ffd36b"))
		if rng.randf() < items.get("ice_cube", 0) * 0.03:
			enemy.apply_slow(1.2, 0.0)
		if rng.randf() < items.get("cheese", 0) * 0.08:
			enemy.poison_time = 3.0
			enemy.poison_dps = maxf(enemy.poison_dps if enemy.poison_time > 0 else 0.0, amount * 0.3)
	enemy.last_source = source
	var actual = minf(enemy.hp, amount)
	damage_totals[source] = damage_totals.get(source, 0.0) + actual
	enemy.take_damage(amount, direction, 0.08 if source in ["sickle", "orbit"] else 0.16)
	if critical:
		play_sound("critical")
		effect(enemy.global_position, "FX/Magic/Spark/SpriteSheet.png", Vector2i(30, 35), 0.2, 1.0)

func powder_burst(pos: Vector2):
	if not ended:
		blast(pos, 40 * area_multiplier(), 20 * items.get("powder", 0) * power(), true, "powder")

func effect(pos: Vector2, path: String, cell: Vector2i, duration: float, size: float):
	# Cosmetic effects may be omitted; damage and hostile projectile cues are separate.
	if impact_effects >= MAX_IMPACT_EFFECTS or pos.distance_squared_to(player.global_position) > 250000: return
	var large = size > 3.0
	if large and large_effects >= 6: return
	if large: large_effects += 1
	impact_effects += 1
	var sprite = Sprite2D.new()
	sprite.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	sprite.texture = load(Data.PACK + path)
	sprite.tree_exited.connect(func():
		impact_effects -= 1
		if large: large_effects -= 1)
	if large: sprite.modulate.a = 0.45
	sprite.hframes = maxi(1, sprite.texture.get_width() / cell.x)
	sprite.vframes = maxi(1, sprite.texture.get_height() / cell.y)
	sprite.position = pos
	sprite.scale = Vector2.ONE * size
	sprite.z_index = 5
	add_child(sprite)
	var tween = create_tween()
	tween.tween_method(func(frame):
		if is_instance_valid(sprite):
			sprite.frame = mini(int(frame), sprite.hframes * sprite.vframes - 1), 0.0, float(sprite.hframes * sprite.vframes), duration)
	tween.tween_callback(sprite.queue_free)

func base_upgrade_preview(key: String) -> String:
	# Levels (b, a) carry rarity and size stats; ranks (rb, ra) drive counts.
	var b = level(key)
	var a = b + offered_gain(key)
	var rb = ranks.get(key, 0)
	var ra = offered_rank(key)
	match key:
		"projectile_speed": return "Speed  +%d%% > +%d%%" % [b * 20, a * 20]
		"projectile_count": return "Extra projectiles  +%d > +%d\nOne per two levels" % [int(b / 2), int(a / 2)]
		"projectile_size": return "Size  +%d%% > +%d%%" % [b * 20, a * 20]
		"egg": return "Eggs  %d > %d\nDamage  %d > %d" % [0 if rb == 0 else 1 + rb / 2, 1 + ra / 2, 13 + b * 4, 13 + a * 4]
		"shuriken": return "Blades  %d > %d\nDamage  %d > %d" % [0 if rb == 0 else rb + 2, ra + 2, 10 + b * 4, 10 + a * 4]
		"thunder": return "Targets  %d > %d\nDamage  %d > %d" % [storm_target_count(rb), storm_target_count(ra), 14 + b * 6, 14 + a * 6]
		"frost": return "Shards  %d > %d\nDamage  %d > %d" % [0 if rb == 0 else 1 + rb / 2, 1 + ra / 2, 9 + b * 4, 9 + a * 4]
		"sickle": return "Damage  %d > %d\nHits on the return trip" % [14 + b * 6, 14 + a * 6]
		"shell": return "Damage  %d > %d\nBlast radius  %d > %d" % [22 + b * 9, 22 + a * 9, 26 + b * 3, 26 + a * 3]
		"fire": return "Damage / tick  %d > %d\nDuration  %.1fs > %.1fs" % [5 + b * 3, 5 + a * 3, 2 + b * 0.5, 2 + a * 0.5]
		"orbit": return "Blades  %d > %d\nDamage  %d > %d" % [0 if rb == 0 else 1 + rb / 2, 1 + ra / 2, 5 + b * 3, 5 + a * 3]
		"pitchfork": return "Jabs  %d > %d\nDamage  %d > %d" % [0 if rb == 0 else (2 if rb >= 6 else 1), 2 if ra >= 6 else 1, 20 + b * 9, 20 + a * 9]
		"carrot": return "Damage  %.0f > %.0f\nFires every 0.30s" % [12 + b * 6, 12 + a * 6]
		"stink": return "Damage / tick  %.0f > %.0f\nRadius  %d > %d" % [5 + b * 2.5, 5 + a * 2.5, 40 + b * 2, 40 + a * 2]
		"parrot": return "Parrots  %d > %d\nDamage  %d > %d" % [0 if rb == 0 else 1 + rb / 3, 1 + ra / 3, 12 + b * 5, 12 + a * 5]
		"might": return "Damage bonus  +%d%% > +%d%%" % [b * 10, a * 10]
		"haste": return "Cooldown  %d%% > %d%%" % [roundi(pow(HASTE_PER_RANK, b) * 100), roundi(pow(HASTE_PER_RANK, a) * 100)]
		"area": return "Area bonus  +%d%% > +%d%%" % [b * 18, a * 18]
		"speed": return "Speed bonus  +%d%% > +%d%%" % [b * 8, a * 8]
		"armor": return "Armor  +%d > +%d" % [roundi(b), roundi(a)]
		"magnet": return "Pickup radius  +%d > +%d\nXP bonus  +%d%% > +%d%%" % [b * 30, a * 30, b * 10, a * 10]
		"vitality": return "Max health  +%d > +%d\nHeal %d now" % [b * 20, a * 20, roundi((a - b) * 20)]
		"regen": return "Health / sec  +%.1f > +%.1f" % [b * 0.4, a * 0.4]
		"crit": return "Critical chance  +%d%% > +%d%%" % [b * 8, a * 8]
		"duration": return "Fire / slow duration  +%d%% > +%d%%" % [b * 20, a * 20]
		"luck": return "Rare / epic odds  +%d%% > +%d%%" % [b * 4, a * 4]
		"thorns": return "Thorns damage  %d > %d" % [0 if b == 0 else 8 + b * 6, 8 + a * 6]
		"evasion": return "Dodge chance  %d%% > %d%%" % [minf(40, b * 4), minf(40, a * 4)]
		"greed": return "Coins  +%d%% > +%d%%" % [b * 12, a * 12]
	return ""

func synergy_active(key: String) -> bool:
	var rule = Data.SYNERGIES[key]
	return ranks.get(rule[1], 0) > 0 and (items.get(rule[2], 0) > 0 if rule[3] else ranks.get(rule[2], 0) > 0)

func steam_burst(pos: Vector2, amount: float):
	if ended:
		return
	blast(pos, 38 * area_multiplier(), amount * 1.5, false, "steam")
	effect(pos, "FX/Smoke/SmokeCircular/SpriteSheet.png", Vector2i(24, 14), 0.4, 2.0)
	play_sound("frost")

func shell_fragments(pos: Vector2, amount: float):
	if not synergy_active("cluster"):
		return
	for i in range(6):
		var shot = make_shot(pos, Vector2.RIGHT.rotated(i * TAU / 6), "shuriken")
		shot.source = "cluster"
		shot.damage = amount * 0.2
		shot.pierce = 2
		shot.lifetime = 0.8

func complete_sickle_return(hits: int):
	if synergy_active("reaper") and hits > 0:
		var healing = mini(2, hits) * items.get("blood_seed", 0)
		player.hp = minf(player.max_hp, player.hp + healing)
		floating_text(player.global_position, "+%d" % healing, Color("8fe0bc"))

func on_ability():
	dashes += 1
	if synergy_active("wake"):
		blast(player.global_position, 45 * area_multiplier(), 12 * items.get("bead", 0) * power(), true, "wake")

func setup_audio_buses():
	Data.ensure_audio_buses()

# Picks the track for the current phase: the level's theme, then rising
# intensity at 3:00 and 6:00, with dedicated tracks while a guardian lives.
func music_phase() -> String:
	var guardian = enemies.any(func(e): return is_instance_valid(e) and not e.dead and e.boss)
	if guardian: return "final" if boss_stage >= 3 else "guardian"
	if elapsed >= 360: return "late"
	if elapsed >= 180: return "mid"
	return level_id

func play_music(key: String):
	if key == music_key: return
	music_key = key
	var previous = music
	music = AudioStreamPlayer.new()
	music.stream = Data.music_stream(key)
	music.bus = "Music"
	# Music keeps playing under the pause menu and result screen.
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	music.finished.connect(music.play)
	add_child(music)
	if DisplayServer.get_name() == "headless":
		if is_instance_valid(previous): previous.queue_free()
		return
	music.volume_db = MUSIC_SILENT
	music.play()
	var fade = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	fade.tween_property(music, "volume_db", MUSIC_VOLUME, 1.2)
	if is_instance_valid(previous):
		fade.tween_property(previous, "volume_db", MUSIC_SILENT, 1.2)
		fade.chain().tween_callback(previous.queue_free)

func apply_audio_settings():
	for entry in [["Music", "music_volume"], ["SFX", "sfx_volume"]]:
		var index = AudioServer.get_bus_index(entry[0])
		if index >= 0:
			var volume = float(save[entry[1]])
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.001, volume)))
			AudioServer.set_bus_mute(index, volume <= 0)

func upgrade_preview(key: String) -> String:
	var text = base_upgrade_preview(key)
	if ranks.get(key, 0) == 0 and key in Data.WEAPONS:
		var lines: Array[String] = []
		for line in text.split("\n"):
			if line.contains(" > "):
				var parts = line.split(" > ")
				lines.append(parts[0].split("  ")[0] + "  " + parts[1])
			else:
				lines.append(line)
		return "\n".join(lines)
	return text

func ascension_ready(key: String) -> bool:
	if ascension != "" or not Data.ASCENSIONS.has(key):
		return false
	var rule = Data.ASCENSIONS[key]
	return guardians_defeated >= 2 and evolved.has(rule[1]) and evolved.has(rule[2]) and ranks.get(rule[3], 0) >= Data.MAX_RANK and ranks.get(rule[4], 0) >= Data.MAX_RANK and items.get(rule[5], 0) >= 3

func ascension_damage(source: String) -> float:
	if ascension != "" and source in [Data.ASCENSIONS[ascension][1], Data.ASCENSIONS[ascension][2]]:
		return 3.0
	return 1.0

func ascension_cooldown(source: String) -> float:
	return 0.5 if ascension_damage(source) > 1.0 else 1.0

func ascension_progress(key: String) -> String:
	var rule = Data.ASCENSIONS[key]
	var lines: Array[String] = []
	lines.append("Guardians defeated: %d / 2" % mini(2, guardians_defeated))
	for weapon in [rule[1], rule[2]]:
		lines.append(("[OK] " if evolved.has(weapon) else "[NEED] ") + Data.EVOLUTIONS[weapon][1] + " evolution")
	for tome in [rule[3], rule[4]]:
		lines.append("%s: rank %d / 10" % [Data.UPGRADES[tome][0], ranks.get(tome, 0)])
	lines.append("%s: %d stacks (needs 3)" % [Data.ITEMS[rule[5]][0], items.get(rule[5], 0)])
	lines.append("ACTIVE for this run" if ascension == key else "Another Ascension already claimed" if ascension != "" else "READY: collect a chest" if ascension_ready(key) else "Complete the recipe, then collect a chest")
	return "\n".join(lines)

func haste_multiplier() -> float:
	return pow(HASTE_PER_RANK, level("haste"))

func projectile_bonus() -> int:
	# One extra projectile per two ranks: a strong tome, not a free doubling.
	return int(level("projectile_count") / 2.0)

func projectile_speed_multiplier() -> float:
	return 1.0 + level("projectile_speed") * 0.2

func weapon_size_multiplier() -> float:
	return 1.0 + level("projectile_size") * 0.2

func chest_price() -> int:
	# A shorter-run economy: 30, 45, 60...; only paid openings advance it.
	return 30 + paid_chests * 15

func key_chance() -> float:
	var count = items.get("key", 0)
	return float(count) / (count + 10.0)

func nearest_chest(max_distance: float = INF):
	var nearest = null
	var distance = max_distance
	for pickup in get_tree().get_nodes_in_group("run_pickups"):
		if pickup.kind != "chest" or pickup.opened:
			continue
		var d = player.global_position.distance_to(pickup.global_position)
		if d <= distance:
			distance = d
			nearest = pickup
	return nearest

func try_open_chest(chest = null) -> bool:
	if ended or get_tree().paused or ui.modal_open or pending_treasures > 0 or not pending_evolutions.is_empty() or pending_ascension != "":
		return false
	if chest == null:
		chest = nearest_chest(30)
	if not is_instance_valid(chest) or chest.kind != "chest" or chest.opened or chest.is_queued_for_deletion() or chest.run != self or player.global_position.distance_to(chest.global_position) > 30:
		return false
	var price = 0 if chest.chest_free else chest_price()
	if coins < price:
		ui.announce("NEED %d MORE COINS" % (price-coins), "This chest will wait here.")
		return false
	var key_triggered = price > 0 and rng.randf() < key_chance()
	last_chest_paid = 0 if key_triggered else price
	last_chest_note = "COOP KEY / FREE OPENING" if key_triggered else "ELITE REWARD / FREE" if chest.chest_free else "%d COINS SPENT" % price
	coins -= last_chest_paid
	if last_chest_paid > 0:
		paid_chests += 1
	chests_opened += 1
	chest.opened = true
	chest.remove_from_group("run_pickups")
	chest.get_node("Sprite").frame = 1
	collect(chest)
	chest.queue_free()
	if pending_ascension != "":
		ui.show_ascension(pending_ascension)
		pending_ascension = ""
	elif not pending_evolutions.is_empty():
		ui.show_evolution(pending_evolutions.pop_front())
	else:
		show_treasure()
	get_tree().paused = true
	return true

func rebuild_combat_grid():
	combat_grid.clear()
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.dead or enemy.is_queued_for_deletion(): continue
		var cell = Vector2i((enemy.global_position / 64.0).floor())
		if not combat_grid.has(cell): combat_grid[cell] = []
		combat_grid[cell].append(enemy)
	combat_grid_frame = Engine.get_physics_frames()
	combat_grid_dirty = false

func enemies_in_rect(bounds: Rect2) -> Array:
	if combat_grid_dirty or combat_grid_frame != Engine.get_physics_frames(): rebuild_combat_grid()
	var first = Vector2i((bounds.position / 64.0).floor())
	var last = Vector2i((bounds.end / 64.0).floor())
	# Huge endgame blasts are cheaper as one linear pass than hundreds of empty cells.
	if (last.x - first.x + 1) * (last.y - first.y + 1) > 128: return enemies
	var result: Array = []
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var cell = Vector2i(x,y)
			if combat_grid.has(cell): result.append_array(combat_grid[cell])
	return result

func nearby_enemies(pos: Vector2, radius: float) -> Array:
	return enemies_in_rect(Rect2(pos - Vector2.ONE * radius, Vector2.ONE * radius * 2))

func recycle_shot(shot: Node2D):
	if shot.get_parent(): shot.get_parent().remove_child(shot)
	if projectile_pool.size() >= 192:
		shot.queue_free()
		return
	projectile_reserve.add_child(shot)
	projectile_pool.append(shot)

# Stink Cloud's visible aura: the pack's aura effect, tinted and sized to the damage radius.
func update_stink_aura(delta: float):
	var active = ranks.get("stink", 0) > 0
	if not active:
		if is_instance_valid(stink_sprite): stink_sprite.hide()
		return
	if not is_instance_valid(stink_sprite):
		stink_sprite = Sprite2D.new()
		stink_sprite.texture = load(Data.PACK + "FX/Magic/Aura/SpriteSheet.png")
		stink_sprite.hframes = 5
		stink_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# On the ground layer it draws above the tiles and decoration, below every actor.
		get_node("Ground layer").add_child(stink_sprite)
	stink_sprite.show()
	stink_sprite.modulate = Color(0.55, 0.85, 0.35, 0.32) if not evolved.has("stink") else Color(0.7, 0.45, 0.85, 0.36)
	stink_sprite.global_position = player.global_position
	stink_sprite.scale = Vector2.ONE * stink_radius() / 12.0
	stink_sprite.frame = int(elapsed * 8) % 5

# Debug-build test shortcuts (listed on the main menu's hidden F12 page).
func dev_key(keycode: int) -> bool:
	match keycode:
		KEY_F1:
			player.gain_xp(player.max_xp - player.current_xp)
		KEY_F2:
			drop("chest", player.global_position + Vector2(18, 0), 0)
		KEY_F3:
			coins += 100
		KEY_F4:
			var next = [180.0, 360.0, DURATION][mini(boss_stage, 2)]
			elapsed = maxf(elapsed, next - 5.0)
		KEY_F5:
			for key in ranks.keys():
				ranks[key] = Data.MAX_RANK
				potency[key] = maxf(level(key), float(Data.MAX_RANK))
			player.movement_speed = 100 * (1 + level("speed") * 0.08)
			ui.refresh_inventory()
		_:
			return false
	ui.announce("DEV", {KEY_F1: "Level up", KEY_F2: "Free chest dropped", KEY_F3: "+100 coins", KEY_F4: "Skipped to the next guardian", KEY_F5: "Everything owned is rank 10"}[keycode])
	return true
