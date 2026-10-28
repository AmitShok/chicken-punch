extends SceneTree

const Data = preload("res://scripts/survival/data.gd")
var scene: Node
var failures = 0
var checks = 0

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func _initialize():
	call_deferred("test")

func target(pos: Vector2):
	var enemy = scene.spawn_enemy("dog")
	enemy.position = pos
	enemy.hp = 1000.0
	enemy.max_hp = 1000.0
	enemy.set_physics_process(false)
	return enemy

func clear_targets():
	for enemy in scene.enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	scene.enemies.clear()
	scene.damage_totals.clear()

func test():
	Data.save_path = "user://coop_expansion_test.cfg"
	Data.write_save({"muted": true, "coins": 0})
	scene = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	scene.set_physics_process(false)
	scene.player.set_physics_process(false)
	for key in Data.UPGRADES:
		check(ResourceLoader.exists(Data.UPGRADES[key][2]), "Upgrade art exists: " + key)
	for key in Data.ITEMS:
		check(ResourceLoader.exists(Data.ITEMS[key][2]), "Item art exists: " + key)
	scene.ranks = {"egg": 1, "shuriken": 1, "fire": 1, "orbit": 1, "might": 1, "haste": 1, "area": 1, "speed": 1}
	var pool = scene.eligible_upgrades()
	check(not pool.has("frost") and not pool.has("crit") and pool.has("egg"), "Four-slot limits exclude new equipment but keep owned upgrades")
	scene.ranks = {"egg": 1}
	scene.show_upgrades()
	check(scene.offers.any(func(key): return key in Data.WEAPONS and key != "egg"), "Opening draft includes a new weapon")
	scene.ui.close_modal()
	paused = false
	scene.ranks = {"egg": 9, "vitality": 1}
	scene.offers = ["vitality"]
	scene.offer_rarities = {"vitality": 2}
	var old_health = scene.player.max_hp
	scene.choose_upgrade("vitality")
	check(scene.ranks.vitality == 2 and scene.player.max_hp == old_health + 40, "Epic upgrades add one rank with double the health gain")
	scene.offers = ["egg"]
	scene.offer_rarities = {"egg": 2}
	scene.choose_upgrade("egg")
	check(scene.ranks.egg == 10, "Rarity cannot exceed rank ten")
	scene.choose_upgrade("egg")
	check(scene.ranks.egg == 10, "Consumed offers cannot be applied again")
	scene.pending_levels = 2
	scene.pending_treasures = 1
	scene.show_treasure()
	var item = scene.offers[0]
	scene.choose_upgrade(item)
	check(scene.items[item] == 1 and scene.pending_levels == 2 and scene.pending_treasures == 0, "Treasure grants items without consuming queued level choices")
	scene.items.clear()
	for key in Data.ITEMS:
		scene.items[key] = 10
	scene.show_treasure()
	check(scene.offers == ["gold"], "Maxed item collection falls back to coins")
	scene.choose_upgrade("gold")
	scene.items.clear()
	scene.ranks.clear()
	scene.evolved.clear()
	scene.pending_evolutions.clear()
	for key in Data.EVOLUTIONS:
		scene.ranks = {key: 10, Data.EVOLUTIONS[key][0]: 1}
		scene.collect({"kind": "chest"})
		check(scene.evolved.has(key), "Evolution recipe activates: " + key)
	check(scene.pending_evolutions.size() == Data.EVOLUTIONS.size(), "All evolution reveals are queued without overwriting")
	scene.ui.show_evolution("egg")
	check(scene.ui.mode == "evolution", "Evolution reveal presents the transformation")
	scene.ui.close_modal()
	scene.pending_evolutions.clear()
	paused = false
	clear_targets()
	scene.evolved.clear()
	scene.ranks = {"thunder": 1, "frost": 1}
	scene.items.clear()
	var first = target(Vector2(0, 0))
	var second = target(Vector2(140, 0))
	first.apply_slow(2, 0.55)
	scene.arsenal.chain(first, 2, 20)
	check(is_equal_approx(first.hp, 973) and is_equal_approx(second.hp, 980), "Cold Conductor adds damage and reaches a target outside normal chain range")
	clear_targets()
	scene.ranks = {"frost": 1, "fire": 1}
	first = target(Vector2(0, 0))
	second = target(Vector2(20, 0))
	first.apply_slow(2, 0.55)
	scene.deal_damage(first, 20, Vector2.ZERO, "fire")
	await process_frame
	check(first.slow_time == 0 and first.steam_lock > 0 and second.hp == 970, "Steam Engine consumes chill and damages nearby enemies")
	clear_targets()
	scene.ranks = {"sickle": 1}
	scene.items = {"blood_seed": 2}
	scene.player.hp = 50
	scene.complete_sickle_return(3)
	check(scene.player.hp == 54, "Reaper's Feast healing is capped and scales with item stacks")
	scene.complete_sickle_return(0)
	check(scene.player.hp == 54, "Empty returning sickles do not heal")
	scene.ranks = {"shell": 1}
	scene.items = {"powder": 1}
	var previous = scene.get_child_count()
	scene.shell_fragments(Vector2.ZERO, 100)
	var fragments = scene.get_children().filter(func(node): return node.get_script() == preload("res://scripts/survival/projectile.gd") and node.source == "cluster")
	check(scene.get_child_count() == previous + 6 and fragments.size() == 6, "Cluster Nest spawns six fragments")
	check(fragments[0].damage == 20 and fragments[0].splash == 0, "Fragments use reduced damage and cannot recursively explode")
	scene.ranks = {"orbit": 1}
	scene.items = {"bead": 2}
	first = target(scene.player.global_position + Vector2(15, 0))
	scene.on_ability()
	check(first.hp == 976, "Iron Wake damages nearby enemies when the ability is used")
	scene.items = {"bead": 2, "honey": 2, "silk": 2, "magnet_stone": 2, "lens": 2, "compass": 2}
	check(scene.armor_value() == 2 and is_equal_approx(scene.regeneration(), 0.6), "Defensive items modify armor and regeneration")
	check(scene.ability_recharge() < 2.2 and scene.pickup_radius() == 95 and is_equal_approx(scene.critical_chance(), 0.16), "Utility items modify dash, pickup and critical chance")
	clear_targets()
	scene.ranks = {"shell": 1}
	scene.items.clear()
	first = target(Vector2.ZERO)
	first.hp = 5
	scene.deal_damage(first, 100, Vector2.ZERO, "shell")
	check(scene.damage_totals.shell == 5, "Damage totals exclude overkill")
	clear_targets()
	scene.ranks = {"thunder": 2, "frost": 2, "sickle": 2, "shell": 2}
	scene.pending_levels = 0
	first = target(scene.player.global_position + Vector2(50, 0))
	scene.arsenal.tick(0.1)
	var shots = scene.get_children().filter(func(node): return node.get_script() == preload("res://scripts/survival/projectile.gd"))
	check(shots.any(func(shot): return shot.source == "frost" and shot.slow_duration > 0), "Frost weapon produces slowing projectiles")
	check(shots.any(func(shot): return shot.source == "sickle" and shot.returning_weapon), "Sickle weapon produces returning projectiles")
	check(shots.any(func(shot): return shot.source == "shell" and shot.detonates), "Shell weapon produces explosive projectiles")
	check(scene.damage_totals.get("thunder", 0) > 0, "Lightning weapon deals damage")
	check(scene.sounds.size() == 19 and scene.sounds.has("impact") and scene.sounds.values().all(func(sound): return sound.stream != null and sound.bus == "SFX"), "All 19 sound events load and route to the effects bus")
	scene.save.sfx_volume = 0
	scene.apply_audio_settings()
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "Effects slider can mute SFX independently")
	scene.ui.show_pause()
	check(scene.ui.mode == "pause" and paused, "Expanded build menu opens and pauses")
	scene.ui.close_modal()
	paused = false
	scene.queue_free()
	await create_timer(0.3).timeout
	print("EXPANSION RESULT: %d checks, %d failures" % [checks, failures])
	quit(failures)
