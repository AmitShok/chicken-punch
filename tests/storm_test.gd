extends SceneTree
var failures := 0
func _initialize(): call_deferred("test")
func check(ok: bool, title: String):
	print(("PASS: " if ok else "FAIL: ") + title)
	if not ok: failures += 1
func test():
	var data = preload("res://scripts/survival/data.gd")
	data.save_path = "user://storm_test.cfg"
	data.write_save({"muted": true})
	var run = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	run.set_physics_process(false)
	run.player.set_physics_process(false)
	var targets = []
	for i in range(3):
		var enemy = run.spawn_enemy("tank")
		enemy.position = run.player.position + Vector2(40 + i * 25, 0)
		enemy.hp = 1000
		enemy.set_physics_process(false)
		targets.append(enemy)
	run.arsenal.chain(targets[0], 3, 20)
	var bolts = get_nodes_in_group("sky_strikes")
	check(bolts.size() == 3, "Each chained target gets a sky strike")
	check(targets.all(func(e): return e.hp == 980), "Chain damage lands immediately with the bolt")
	check(bolts[0].position == targets[0].position and bolts[0].offset == Vector2(-16,-350), "Bolt tip is anchored to impact")
	paused = true
	await create_timer(0.1).timeout
	check(bolts[0].frame == 0, "Pausing freezes the strike")
	paused = false
	bolts[0]._process(0.1)
	check(bolts[0].frame == 2, "Bolt flickers through animation frames")
	bolts[0].configure(2.0, true)
	check(bolts[0].scale == Vector2(3,1), "Thunderhead and size tome widen bolt while preserving sky height")
	for i in range(15): run.arsenal.chain(targets[0], 3, 1)
	check(get_nodes_in_group("sky_strikes").size() == 32, "Endgame visual cap prevents excessive columns")
	check(targets.all(func(e): return e.hp == 965), "Visual cap never suppresses damage")
	await create_timer(0.45).timeout
	check(get_nodes_in_group("sky_strikes").is_empty(), "Strikes clean up after animation")
	quit(1 if failures else 0)
