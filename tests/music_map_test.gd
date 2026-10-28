extends SceneTree
const Data = preload("res://scripts/survival/data.gd")
var failures = 0
var checks = 0
func _initialize(): call_deferred("test")
func check(ok: bool, title: String):
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ") + title)
func test():
	Data.save_path = "user://coop_music_map_test.cfg"
	Data.write_save({"gold": 0, "muted": true})
	for key in Data.MUSIC:
		check(Data.music_stream(key) != null, "Track loads: " + key)
	for level in Data.LEVELS:
		set_meta("level_id", level)
		var run = load("res://scenes/world/world.tscn").instantiate()
		root.add_child(run)
		current_scene = run
		await process_frame
		run.set_physics_process(false)
		check(run.music_key == level, level + " opens with its own theme")
		check(run.music_phase() == level, level + " keeps its theme before 3:00")
		run.elapsed = 200
		check(run.music_phase() == "mid", level + " rises to the mid track at 3:00")
		run.elapsed = 400
		check(run.music_phase() == "late", level + " rises to the late track at 6:00")
		var boss = run.spawn_enemy("boss", true)
		run.boss_stage = 1
		check(run.music_phase() == "guardian", level + " plays the guardian track while one lives")
		run.boss_stage = 3
		check(run.music_phase() == "final", level + " plays the final track for the last guardian")
		boss.queue_free()
		run.enemies.clear()
		run.play_music(run.music_phase())
		check(run.music_key == "late" and run.get_children().filter(func(c): return c is AudioStreamPlayer and c.stream == run.music.stream).size() == 1, level + " switches tracks without duplicating the player")
		var detail = run.get_node("Ground layer/GroundDetail")
		check(detail != null and detail.pieces.size() > 100, level + " has ground decoration")
		check(detail.pieces.all(func(p): return p[2].distance_to(run.player.position) > 20), level + " keeps the start point clear")
		var bodies = 0
		for child in detail.get_children(): if child is CollisionObject2D: bodies += 1
		check(bodies == 0, level + " decoration never collides")
		run.finish(true)
		check(run.music_key == "victory", level + " plays the victory theme on a win")
		paused = false
		run.queue_free()
		await process_frame
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	check(menu.get_node_or_null("MenuMusic") != null and menu.get_node("MenuMusic").bus == "Music", "Main menu has its own music on the Music bus")
	menu.queue_free()
	print("MUSIC MAP RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
