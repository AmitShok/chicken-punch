extends SceneTree
func _initialize(): call_deferred("probe")
func probe():
	var data = preload("res://scripts/survival/data.gd")
	data.save_path = "user://performance_probe.cfg"
	data.write_save({"muted":true})
	var run = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	run.set_physics_process(false)
	run.player.set_physics_process(false)
	run.rng.seed = 74021
	run.ranks = {"fire":10,"duration":10,"haste":10,"projectile_count":10}
	for i in range(180):
		var e = run.spawn_enemy("tank")
		e.position = Vector2((i % 18)*32-272,(i / 18)*32-144)
		e.hp = 100000000
		e.set_physics_process(false)
	for i in range(960): run.spawn_fire_patch(Vector2((i % 48)*12-282,(i / 48)*12-114))
	for h in run.hazards: h.life = 1000; h.damage = 0
	var shots = []
	for i in range(240):
		var shot = run.make_shot(Vector2.ZERO,Vector2.RIGHT,"shuriken")
		shot.set_physics_process(false)
		shot.lifetime = 1000
		shot.damage = 0
		shot.pierce = 100000
		shots.append(shot)
	var samples = []
	for tick in range(90):
		var begin = Time.get_ticks_usec()
		if run.has_method("rebuild_combat_grid"): run.rebuild_combat_grid()
		run.update_hazards(1.0/60)
		for i in range(shots.size()):
			var shot = shots[i]
			shot.position = Vector2((i % 24)*24-280,(i / 24)*24-110)
			shot.hit_ids.clear()
			shot._physics_process(1.0/60)
		samples.append((Time.get_ticks_usec()-begin)/1000.0)
		await process_frame
	samples.sort()
	print("PERFORMANCE_PROBE median_ms=",samples[45]," p95_ms=",samples[85]," hazards=",run.hazards.size()," enemies=",run.enemies.size()," shots=",shots.size())
	quit()
