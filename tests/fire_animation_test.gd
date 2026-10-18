extends SceneTree
var failures = 0
var checks = 0
func _initialize(): call_deferred("test")
func check(ok: bool, title: String):
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ") + title)
func test():
	preload("res://scripts/survival/data.gd").save_path = "user://coop_fire_test.cfg"
	var run = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(run)
	run.set_physics_process(false)
	run.player.set_physics_process(false)
	run.ranks = {"fire":1}
	run.attack_weapons()
	var h = run.hazards[0]
	check(h.sprite.hframes == 12 and h.sprite.texture.get_width()/h.sprite.hframes == 8, "Twelve complete 8x12 flame frames")
	var enemy = run.spawn_enemy("tank")
	enemy.position = h.sprite.position
	enemy.hp = 1000
	enemy.set_physics_process(false)
	run.update_hazards(0.09)
	check(h.sprite.frame == 1, "Ignition advances at 12 fps")
	var first_hp = enemy.hp
	run.update_hazards(0.09)
	check(h.sprite.frame == 2 and enemy.hp == first_hp, "Animation advances between damage ticks")
	run.update_hazards(0.09)
	check(h.sprite.frame == 3, "Ignition enters sustained flame")
	for i in range(10):
		run.update_hazards(0.09)
		check(h.sprite.frame >= 3 and h.sprite.frame <= 7, "Sustained fire stays within flicker frames")
	check(enemy.hp < first_hp, "Fire continues dealing damage")
	h.life = 0.3
	run.update_hazards(0.01)
	check(h.sprite.frame == 8, "Expiring fire enters ember sequence")
	run.update_hazards(0.2)
	check(h.sprite.frame >= 10 and h.sprite.frame <= 11, "Embers burn out without restarting")
	run.update_hazards(0.2)
	check(run.hazards.is_empty() and h.sprite.is_queued_for_deletion(), "Expired flame is removed")
	print("FIRE RESULT: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
