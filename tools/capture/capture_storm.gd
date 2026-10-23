extends SceneTree
func _initialize(): call_deferred("capture")
func capture():
	var data = preload("res://scripts/survival/data.gd")
	data.save_path = "user://storm_capture.cfg"
	data.write_save({"muted": true})
	var run = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	await process_frame
	run.set_physics_process(false)
	run.player.set_physics_process(false)
	run.ui.compact_hud = true
	run.ui.apply_hud_layout()
	run.ui.banner_time = 0
	var targets = []
	for i in range(3):
		var enemy = run.spawn_enemy("tank")
		enemy.set_physics_process(false)
		enemy.position = run.player.position + Vector2(50 + i * 55, 15 + i * 18)
		enemy.hp = 1000
		enemy.max_hp = 1000
		targets.append(enemy)
	run.arsenal.chain(targets[0], 3, 20)
	paused = true
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0] + "/storm-call.png")
	print("Storm native renderer capture complete")
	quit()
