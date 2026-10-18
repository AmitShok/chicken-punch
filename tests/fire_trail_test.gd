extends SceneTree
var checks = 0
var failures = 0
func _initialize(): call_deferred("test")
func check(ok: bool, title: String):
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ") + title)
func reset_trail(run, bonus: int):
	for h in run.hazards: h.sprite.queue_free()
	run.hazards.clear()
	run.fire_trail_started = false
	run.ranks = {"fire":1,"projectile_count":bonus}
	run.player.position = Vector2.ZERO
	run.update_fire_trail()
func test():
	preload("res://scripts/survival/data.gd").save_path = "user://coop_fire_trail_test.cfg"
	var run = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(run)
	run.set_physics_process(false)
	run.player.set_physics_process(false)
	var previous = INF
	for bonus in range(6):
		reset_trail(run,bonus)
		var spacing = run.fire_spacing()
		check(spacing < previous, "Rank %d makes spacing smaller" % bonus)
		previous = spacing
		run.player.position = Vector2(195,0)
		run.update_fire_trail()
		check(run.hazards.size() == 1+roundi(195/spacing), "Rank %d fills a fast movement segment" % bonus)
		var aligned = true
		for i in range(run.hazards.size()):
			aligned = aligned and run.hazards[i].sprite.position.is_equal_approx(Vector2(i*spacing,0))
		check(aligned, "Rank %d places flames along the path, not sideways" % bonus)
	reset_trail(run,3)
	for i in range(195):
		run.player.position.x += 1
		run.update_fire_trail()
	check(run.hazards.size() == 13, "Small movement steps produce same density as a dash")
	reset_trail(run,3)
	run.player.position = Vector2(10,0)
	run.update_fire_trail()
	run.player.position = Vector2(10,10)
	run.update_fire_trail()
	check(run.hazards[1].sprite.position.is_equal_approx(Vector2(10,6.25)), "Trail follows corners instead of cutting diagonally")
	run.ranks.haste = 5
	run.ascension = "henpocalypse"
	check(is_equal_approx(run.fire_spacing(),65*pow(0.9,5)*0.5/4), "Reload speed and Henpocalypse still improve density")
	run.cooldowns.fire = 0
	var count = run.hazards.size()
	run.update_fire_trail()
	check(run.hazards.size() == count+1, "Stationary fire still works")
	print("TRAIL RESULT: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
