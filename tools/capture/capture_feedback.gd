extends SceneTree
func _initialize(): call_deferred("capture")
func capture():
	var data = preload("res://scripts/survival/data.gd")
	data.save_path = "user://feedback_capture.cfg"
	data.write_save({"muted": true, "combat_feedback": true})
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
	for i in range(9):
		var enemy = run.spawn_enemy("tank" if i % 3 == 0 else "dog")
		enemy.set_physics_process(false)
		enemy.position = run.player.position + Vector2(50 + (i % 3) * 35, (i / 3) * 35 - 45)
		enemy.hp = 100
		enemy.max_hp = 100
		enemy.take_damage(35, Vector2.RIGHT)
		enemy.update_feedback(0.04 if i % 3 == 0 else 0.1)
		enemy.queue_redraw()
		targets.append(enemy)
	run.player.hp = 100
	await process_frame
	run.player.take_damage(30)
	run.make_shot(run.player.position, Vector2.RIGHT, "egg")
	run.enemy_bullet(run.player.position + Vector2(-90, -30), Vector2.RIGHT, 5)
	await create_timer(0.07).timeout
	paused = true
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0] + "/archvale-feedback.png")
	print("Feedback native renderer capture complete")
	quit()
