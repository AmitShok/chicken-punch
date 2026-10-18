extends SceneTree

const Data = preload("res://scripts/survival/data.gd")
var scene: Node
var steps = 0
var max_enemies = 0
var max_nodes = 0
var finishing = false

func _initialize():
	call_deferred("start")

func start():
	Data.save_path = "user://coop_soak_test.cfg"
	Data.write_save({"coins": 0, "muted": true})
	scene = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.ranks = {"thunder": 5, "frost": 5, "sickle": 5, "shell": 5, "crit": 5, "duration": 5, "magnet": 5, "might": 5}
	for key in Data.ITEMS:
		scene.items[key] = 3
	scene.evolved = {"thunder": true, "frost": true, "sickle": true, "shell": true}
	scene.player.max_hp = 100000
	scene.player.hp = 100000
	Engine.time_scale = 12

func _process(_delta):
	if finishing or not is_instance_valid(scene):
		return false
	steps += 1
	max_enemies = maxi(max_enemies, scene.enemies.size())
	max_nodes = maxi(max_nodes, scene.get_child_count())
	if scene.ui.mode in ["evolution", "ascension"]:
		scene.ui.close_modal()
		paused = false
	if scene.ui.mode in ["upgrade", "chest"]:
		scene.choose_upgrade(scene.offers[0])
	if not scene.ended and not paused:
		scene.try_open_chest()
	if not scene.ended:
		var angle = scene.elapsed * 0.08
		var target = Vector2(cos(angle), sin(angle)) * 130
		scene.player.global_position = scene.player.global_position.move_toward(target, 2)
	if scene.ended or scene.elapsed > 650 or steps > 50000:
		print("SOAK elapsed=", scene.elapsed, " kills=", scene.kills, " peak_enemies=", max_enemies, " peak_world_children=", max_nodes, " bosses=", scene.boss_stage, " victory=", scene.final_boss_dead, " ascension=", scene.ascension, " guardians_defeated=", scene.guardians_defeated)
		finishing = true
		call_deferred("finish_test")
	return false

func finish_test():
	var succeeded = scene.final_boss_dead
	Engine.time_scale = 1
	paused = false
	scene.queue_free()
	await create_timer(0.3).timeout
	quit(0 if succeeded else 1)


