extends SceneTree
var failures = 0
func _initialize(): call_deferred("test")
func check(ok: bool, message: String):
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok: failures += 1
func test():
	var data = preload("res://scripts/survival/data.gd")
	data.save_path = "user://feedback_test.cfg"
	data.write_save({"combat_feedback": true, "muted": true})
	var run = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(run)
	run.set_physics_process(false)
	run.player.set_physics_process(false)
	var enemy = run.spawn_enemy("dog")
	enemy.set_physics_process(false)
	var original_hp = enemy.hp
	enemy.take_damage(1, Vector2.RIGHT)
	check(is_equal_approx(enemy.hp, original_hp - 1), "Recoil preserves damage")
	check(enemy.get_node("Sprite2D").scale.x > enemy.rest_scale.x, "Hit stretches sprite")
	for i in range(40): run.feedback.echo(enemy.get_node("Sprite2D"), Vector2.ZERO, Color.WHITE, 0.1)
	check(run.feedback.ghosts == 24, "Crowd effects are capped")
	await create_timer(0.25).timeout
	check(run.feedback.ghosts == 0, "Effects clean up after expiry")
	run.feedback.kick(100)
	check(run.feedback.shake <= 3, "Camera motion has a hard bound")
	run.save.combat_feedback = false
	run.feedback._process(0.016)
	check(run.player.get_node("Camera2D").offset == Vector2.ZERO, "Reduced motion resets camera")
	run.feedback.echo(enemy.get_node("Sprite2D"), Vector2.ZERO, Color.WHITE, 0.1)
	check(run.feedback.ghosts == 0, "Reduced motion disables echoes")
	data.write_save(run.save)
	check(not data.read_save().combat_feedback, "Motion preference persists")
	run.queue_free()
	await process_frame
	print("FEEDBACK RESULT: ", failures, " failures")
	quit(1 if failures else 0)
