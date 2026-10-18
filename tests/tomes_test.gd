extends SceneTree
const Data = preload("res://scripts/survival/data.gd")
const Inspection = preload("res://scripts/survival/inspection.gd")
const Shot = preload("res://scripts/survival/projectile.gd")
var checks = 0
var failures = 0
func _initialize(): call_deferred("test")
func check(ok: bool, title: String):
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ") + title)
func test():
	Data.save_path = "user://coop_tomes_test.cfg"
	Data.write_save({"muted":true})
	var run = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	run.set_physics_process(false)
	run.player.set_physics_process(false)
	for rarity in range(3):
		run.ranks = {"egg":1}
		run.offers = ["projectile_count"]
		run.offer_rarities = {"projectile_count":rarity}
		run.offer_kind = "upgrade"
		run.pending_levels = 1
		run.choose_upgrade("projectile_count")
		check(run.projectile_bonus() == rarity+1, "Rarity %d grants exactly +%d shots" % [rarity,rarity+1])
	run.ranks.projectile_count = 4
	run.offers = ["projectile_count"]
	run.offer_rarities = {"projectile_count":2}
	run.choose_upgrade("projectile_count")
	check(run.projectile_bonus() == 5, "Count bonus caps at five near maximum rank")
	run.ranks = {"egg":5,"shuriken":5,"fire":5,"orbit":5,"thunder":5,"frost":5,"sickle":5,"shell":5,"projectile_count":3,"projectile_size":5,"projectile_speed":5,"might":5,"haste":5}
	for i in range(12):
		var e = run.spawn_enemy("tank")
		e.position = run.player.position + Vector2(100+i*5,0)
		e.hp = 100000
		e.set_physics_process(false)
	run.attack_weapons()
	run.update_orbits(0.01)
	run.arsenal.tick(0.01)
	var counts = {}
	for child in run.get_children():
		if child.get_script() == Shot:
			counts[child.source] = counts.get(child.source,0)+1
			check(child.speed_scale == 2 and child.hit_radius == 8 and child.get_node("Sprite").scale == Vector2(2,2), child.source+" has matching visual, hitbox and speed multipliers")
	for entry in [["egg",8],["shuriken",10],["frost",6],["sickle",4],["shell",4]]:
		check(counts.get(entry[0],0) == entry[1], entry[0]+" receives the correct bonus count")
	check(run.hazards.size() == 1 and is_equal_approx(run.fire_spacing(),65.0*pow(0.9,5)/4), "Brood Burst reduces fire-trail spacing instead of spawning side-by-side patches")
	check(run.orbit_sprites.size() == 6, "Brood Burst adds orbit blades")
	check(is_equal_approx(run.cooldowns.egg,0.85*pow(0.9,5)), "Quick Hatch shortens actual attack cooldown")
	check(run.power() == 2, "Fighting Spirit doubles damage at rank five")
	for enemy in run.enemies: enemy.queue_free()
	run.enemies.clear()
	for child in run.get_children():
		if child.get_script() == Shot: child.queue_free()
	await process_frame
	var target = run.spawn_enemy("tank")
	target.position = run.player.position + Vector2(10,7)
	target.radius = 1
	target.hp = 1000
	target.set_physics_process(false)
	run.ranks = {"projectile_size":5}
	var large = run.make_shot(run.player.position,Vector2.RIGHT,"egg")
	large.speed = 100
	large.damage = 10
	large._physics_process(0.1)
	check(target.hp == 990, "Enlarged projectile really hits outside original hit radius")
	run.ranks = {}
	var small = run.make_shot(run.player.position,Vector2.RIGHT,"egg")
	small.speed = 100
	small.damage = 10
	small._physics_process(0.1)
	check(target.hp == 990, "Default projectile misses the same off-center target")
	run.enemies.clear()
	run.ranks = {"projectile_speed":5,"projectile_size":5}
	var fast = run.make_shot(run.player.position,Vector2.RIGHT,"egg")
	fast.speed = 100
	var start = fast.position
	fast._physics_process(0.1)
	check(is_equal_approx(fast.position.x-start.x,20), "Tailwind changes actual travel distance")
	var hostile = run.make_shot(Vector2.ZERO,Vector2.RIGHT,"hostile")
	check(hostile.speed_scale == 1 and hostile.hit_radius == 4 and hostile.get_node("Sprite").scale == Vector2.ONE, "Player tomes do not buff enemy projectiles")
	for key in ["projectile_speed","projectile_count","projectile_size"]:
		run.ranks[key] = 3
		check(Inspection.describe(run,key,false).contains("CURRENT EFFECT"), key+" is inspectable")
		check(not run.upgrade_preview(key).is_empty(), key+" has an upgrade preview")
	# Capture the new choices with real UI when rendered.
	if DisplayServer.get_name() != "headless":
		run.offers = ["projectile_speed","projectile_count","projectile_size"]
		run.offer_rarities = {"projectile_speed":0,"projectile_count":2,"projectile_size":1}
		run.offer_kind = "upgrade"
		run.ui.show_choices()
		paused = true
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0]+"/projectile-tomes.png")
	print("TOMES RESULT: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
