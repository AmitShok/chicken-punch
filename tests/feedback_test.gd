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
	await process_frame
	await process_frame
	check(run.feedback.ghosts == 0, "Effects clean up after expiry")
	# Ranged crowd control must not refresh on every rapid hit, but damage must.
	enemy.hp = 100
	enemy.max_hp = 100
	enemy.knockback_lock = 0
	enemy.take_damage(1, Vector2.RIGHT)
	var first_velocity = enemy.knockback_velocity
	enemy.take_damage(1, Vector2.LEFT)
	check(enemy.knockback_velocity == first_velocity and enemy.hp == 98, "Rapid hits preserve damage without resetting shove")
	enemy.update_feedback(0.17)
	enemy.take_damage(1, Vector2.LEFT)
	check(enemy.knockback_velocity.x < 0, "Knockback returns after its cooldown")
	enemy.update_feedback(0.01)
	check(enemy.health_trail > enemy.hp / enemy.max_hp and enemy.health_reveal > 0, "Recent damage has a visible health trail")
	check(enemy.hit_material.get_shader_parameter("flash_amount") > 0, "Hits drive the outline-preserving shader")
	enemy.update_feedback(1.7)
	check(is_equal_approx(enemy.health_trail, enemy.hp / enemy.max_hp) and enemy.health_reveal == 0, "Enemy damage trail settles and reveal expires")
	var effect = run.feedback
	effect.update_particles(1.0)
	for i in range(50): effect.puff(Vector2.ZERO, Vector2.RIGHT * 55, Color.WHITE, 0.5, 0.24)
	check(effect.particles.size() == 36, "Normal puffs leave capacity for hostile cues")
	for i in range(20): effect.puff(Vector2.ZERO, Vector2.ZERO, Color.WHITE, 0.5, 0.24, true)
	check(effect.particles.size() == 48, "All puffs obey the hard cap")
	effect.update_particles(0.05)
	check(effect.particles[0].sprite.position.x > 0, "Impact puffs inherit directional momentum")
	check(effect.particles[0].sprite.position == effect.particles[0].sprite.position.round(), "Puffs move on the pixel grid")
	effect.update_particles(0.25)
	check(effect.particles.is_empty(), "Puff records and sprites expire")
	effect.launch_clocks.clear()
	for i in range(20): effect.launch(Vector2.ZERO, Vector2.RIGHT, "egg")
	check(effect.particles.size() == 1, "A large volley produces one launch cue")
	effect.launch(Vector2(0, 0), Vector2.RIGHT, "hostile")
	effect.launch(Vector2(80, 0), Vector2.RIGHT, "hostile")
	check(effect.particles.size() == 3, "Separate enemy volleys each retain a launch cue")
	var bar = run.ui.health
	bar.set_process(false)
	bar.max_value = 100
	bar.value = 100
	bar._process(0)
	bar.value = 50
	bar._process(0.01)
	check(bar.trail_ratio > 0.5, "Player HP immediately updates with a delayed damage trail")
	paused = true
	var frozen = bar.trail_ratio
	bar._process(0.5)
	check(bar.trail_ratio == frozen, "Health animation freezes while paused")
	paused = false
	bar.motion_enabled = false
	bar._process(0.01)
	check(bar.trail_ratio == 0.5, "Reduced motion settles the HP bar immediately")
	run.feedback.kick(100)
	check(run.feedback.shake <= 3, "Camera motion has a hard bound")
	run.save.combat_feedback = false
	run.feedback._process(0.016)
	check(run.player.get_node("Camera2D").offset == Vector2.ZERO, "Reduced motion resets camera")
	run.feedback.echo(enemy.get_node("Sprite2D"), Vector2.ZERO, Color.WHITE, 0.1)
	check(run.feedback.ghosts == 0, "Reduced motion disables echoes")
	check(run.feedback.particles.is_empty(), "Reduced motion clears active puffs")
	data.write_save(run.save)
	check(not data.read_save().combat_feedback, "Motion preference persists")
	run.queue_free()
	await process_frame
	print("FEEDBACK RESULT: ", failures, " failures")
	quit(1 if failures else 0)
