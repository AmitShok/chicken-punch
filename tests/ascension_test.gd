extends SceneTree
const Data = preload("res://scripts/survival/data.gd")
const Inspection = preload("res://scripts/survival/inspection.gd")
var checks = 0
var failures = 0
func _initialize():
	call_deferred("test")
func check(ok: bool, title: String):
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ") + title)
func test():
	Data.save_path = "user://coop_ascension_test.cfg"
	Data.write_save({"muted":true})
	for key in Data.ASCENSIONS:
		var run = load("res://scenes/world/world.tscn").instantiate()
		root.add_child(run)
		current_scene = run
		run.set_physics_process(false)
		run.player.set_physics_process(false)
		var rule = Data.ASCENSIONS[key]
		run.ranks = {rule[1]:5,rule[2]:5,rule[3]:5,rule[4]:5}
		run.evolved = {rule[1]:true,rule[2]:true}
		run.items = {rule[5]:3}
		run.guardians_defeated = 2
		check(run.ascension_ready(key), key+" exact recipe qualifies")
		run.guardians_defeated = 1
		check(not run.ascension_ready(key), key+" blocked until two guardians are defeated")
		run.guardians_defeated = 2
		for weapon in [rule[1],rule[2]]:
			run.evolved.erase(weapon)
			check(not run.ascension_ready(key), key+" requires evolution "+weapon)
			run.evolved[weapon] = true
		for tome in [rule[3],rule[4]]:
			run.ranks[tome] = 4
			check(not run.ascension_ready(key), key+" requires maxed tome "+tome)
			run.ranks[tome] = 5
		run.items[rule[5]] = 2
		check(not run.ascension_ready(key), key+" requires three item stacks")
		run.items[rule[5]] = 3
		check(run.ascension == "", key+" does not activate without a chest")
		run.collect({"kind":"chest"})
		check(run.ascension == key and run.pending_ascension == key and run.pending_treasures == 0, key+" chest activates and queues reveal instead of treasure")
		run.collect({"kind":"chest"})
		check(run.pending_treasures == 1, key+" subsequent chests grant ordinary treasure")
		check(not run.ascension_ready(key), key+" cannot be claimed twice")
		var target = run.spawn_enemy("tank")
		target.hp = 10000
		run.ranks.erase("crit")
		run.items.erase("lens")
		run.deal_damage(target,10,Vector2.ZERO,rule[1])
		check(is_equal_approx(target.hp,9970), key+" triples actual weapon damage")
		check(run.ascension_cooldown(rule[1]) == 0.5 and run.ascension_damage("unrelated") == 1, key+" doubles casting rate only for paired weapons")
		run.ui.show_pause()
		check(paused and run.ui.inspect_body.text.contains("CURRENT EFFECT"), key+" pause opens populated inspector")
		run.ui.inspect_equipment(rule[5],true)
		check(run.ui.inspect_title.text == Data.ITEMS[rule[5]][0] and paused, key+" selecting item updates details without resuming")
		run.ui.close_modal()
		paused = false
		run.ui.show_ascension(key)
		check(run.ui.mode == "ascension", key+" reveal opens")
		run.ui.close_modal()
		# Stress the actual cast paths against a dense, durable horde.
		for i in range(100):
			var enemy = run.spawn_enemy("tank")
			enemy.position = run.player.position + Vector2.RIGHT.rotated(i*TAU/100)*(30+i)
			enemy.hp = 100000
			enemy.set_physics_process(false)
		run.attack_weapons()
		run.update_orbits(0.01)
		run.arsenal.tick(0.01)
		var projectiles = {}
		for child in run.get_children():
			if child.get_script() == preload("res://scripts/survival/projectile.gd"):
				projectiles[child.source] = projectiles.get(child.source,0)+1
		if key == "whiteout":
			check(projectiles.get("frost",0) == 11, "Absolute Zero launches eleven ice shards")
			check(is_equal_approx(run.arsenal.clocks.thunder,1.0), "Absolute Zero halves lightning cooldown")
		elif key == "henpocalypse":
			check(projectiles.get("egg",0) == 16, "Henpocalypse launches sixteen eggs")
			check(is_equal_approx(run.cooldowns.egg,0.85*pow(0.9,5)*0.5), "Henpocalypse stacks with Quick Hatch")
		else:
			check(projectiles.get("sickle",0) == 4, "Last Harvest launches four sickles")
			check(run.orbit_sprites.size() == 13, "Last Harvest creates thirteen orbiting blades")
		run.player.hp = 100000
		for tick in range(180):
			for weapon in run.cooldowns: run.cooldowns[weapon] -= 1.0/60
			run.attack_weapons()
			run.update_orbits(1.0/60)
			run.update_hazards(1.0/60)
			run.arsenal.tick(1.0/60)
			await physics_frame
		check(run.get_child_count() < 2000, key+" dense-horde effects stay bounded")
		print("STRESS ",key," children=",run.get_child_count()," damage=",run.damage_totals)
		run.queue_free()
		await process_frame
	# All equipment descriptions render without errors at maximum rank/stacks.
	var run = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(run)
	run.set_physics_process(false)
	for key in Data.UPGRADES: run.ranks[key] = 5
	for key in Data.ITEMS: run.items[key] = 3
	for key in Data.UPGRADES:
		check(Inspection.describe(run,key,false).contains("CURRENT EFFECT"), "inspect "+key)
	for key in Data.ITEMS:
		check(Inspection.describe(run,key,true).contains("CURRENT EFFECT"), "inspect "+key)
	run.queue_free()
	await process_frame
	print("ASCENSION RESULT: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
