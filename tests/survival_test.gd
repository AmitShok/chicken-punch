extends SceneTree

const Data = preload("res://scripts/survival/data.gd")
var failures = 0

func check(condition: bool, message: String):
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _initialize():
	call_deferred("test")

func test():
	Data.save_path = "user://coop_automated_test.cfg"
	Data.write_save({"coins": 0, "power": 0, "heart": 0, "best": 0, "wins": 0, "muted": true})
	var scene = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await physics_frame
	scene.set_physics_process(false)
	scene.player.set_physics_process(false)
	print("ARENA: ", scene.arena_bounds)
	check(scene.player.hp == 100, "Run initializes with full health")
	scene.player.gain_xp(100)
	check(scene.player.level == 4 and scene.player.current_xp == 34, "Large XP grants preserve overflow and all levels")
	check(scene.pending_levels == 3, "Every earned upgrade is queued")
	scene.show_upgrades()
	check(paused and scene.offers.size() == 3, "Level choices pause the game and offer three options")
	var time_before = scene.elapsed
	await process_frame
	check(scene.elapsed == time_before, "Time does not advance during upgrades")
	var chosen = scene.offers[0]
	scene.choose_upgrade(chosen)
	check(not paused and scene.pending_levels == 2, "Choice resumes and consumes exactly one queued upgrade")
	scene.show_upgrades()
	scene.reroll()
	check(scene.rerolls == 2, "Rerolls consume their budget")
	var banished = scene.offers[0]
	scene.banish(banished)
	check(not scene.offers.has(banished) and scene.banishes == 1, "Banished upgrades leave the offer pool")
	scene.ui.close_modal()
	paused = false
	scene.pending_levels = 0
	scene.ranks = {"egg": 10, "haste": 1, "fire": 10, "area": 1, "orbit": 10, "armor": 1, "shuriken": 10, "speed": 1}
	for i in range(4):
		scene.collect({"kind": "chest"})
	check(scene.evolved.size() == 4, "All four chest evolution recipes trigger")
	var hp = scene.player.hp
	scene.player.invulnerability = 0
	scene.player.take_damage(10)
	scene.player.take_damage(10)
	check(scene.player.hp == hp - 9, "Armor and invulnerability prevent repeated contact damage")
	var enemy = scene.spawn_enemy("dog")
	enemy.take_damage(999)
	enemy.take_damage(999)
	check(scene.kills == 1, "Death rewards are granted exactly once")
	for kind in ["bat", "tank", "caster", "boss"]:
		var mob = scene.spawn_enemy(kind)
		check(mob.max_hp > 0, "Enemy initializes: " + kind)
	scene.attack_weapons()
	scene.update_orbits(0.1)
	scene.update_hazards(0.1)
	check(scene.orbit_sprites.size() == 8 and scene.hazards.size() > 0, "Evolved orbit and fire weapons activate")
	scene.boss_stage = 3
	scene.elapsed = 600
	var boss = scene.spawn_enemy("boss", true)
	boss.take_damage(100000)
	check(scene.final_boss_dead, "Final guardian death unlocks victory")
	scene.finish(true)
	check(scene.ended and paused, "Victory stops combat")
	var saved = Data.read_save()
	check(saved.wins == 1 and saved.gold > 0, "Victory rewards persist")
	var bank = saved.gold
	scene.finish(true)
	check(Data.read_save().gold == bank, "Run results cannot grant rewards twice")
	paused = false
	root.remove_child(scene)
	scene.queue_free()
	await process_frame
	var fresh = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(fresh)
	current_scene = fresh
	await physics_frame
	check(fresh.kills == 0 and fresh.elapsed < 1 and fresh.evolved.is_empty(), "Retry starts with clean run state")
	fresh.player.invulnerability = 0
	fresh.player.take_damage(100000)
	check(fresh.ended and fresh.player.is_dead and paused, "Lethal damage ends the run")
	paused = false
	root.remove_child(fresh)
	fresh.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("RESULT: ", failures, " failures")
	quit(failures)


