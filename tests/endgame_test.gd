extends SceneTree
const Data = preload("res://scripts/survival/data.gd")
var checks = 0
var failures = 0
func _initialize(): call_deferred("test")
func check(ok: bool, label: String):
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ") + label)
func test():
	Data.save_path = "user://endgame_test.cfg"
	Data.write_save({"muted":true})
	var run = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	run.set_physics_process(false)
	run.player.set_physics_process(false)
	run.ranks = {"crit":10}
	run.items = {"lens":3}
	check(run.critical_tier(0.039) == 2 and run.critical_tier(0.041) == 1, "104% crit guarantees crits and gives 4% overcrits")
	run.items.lens = 10
	check(run.critical_tier(0.59) == 2 and run.critical_tier(0.61) == 1, "160% crit retains investment beyond 100%")
	var crit_target = run.spawn_enemy("tank")
	crit_target.hp = 100000
	crit_target.set_physics_process(false)
	run.items.berserk = 3
	run.player.hp = run.player.max_hp * 0.49
	var seed_value = 0
	while true:
		run.rng.seed = seed_value
		if run.critical_tier(run.rng.randf()) == 2: break
		seed_value += 1
	run.rng.seed = seed_value
	run.deal_damage(crit_target, 100, Vector2.ZERO, "egg")
	check(is_equal_approx(crit_target.hp, 99200), "Redline produces 8x hits with three feathers below half HP")
	run.player.hp = run.player.max_hp * 0.5
	run.rng.seed = seed_value
	run.deal_damage(crit_target, 100, Vector2.ZERO, "egg")
	check(is_equal_approx(crit_target.hp, 98800), "Healing to half HP disables Redline")
	run.ranks = {"fire":10,"duration":5}
	run.evolved = {"fire":true}
	run.items = {"powder":2}
	check(not run.slow_roast_ready(), "Two rare powders cannot activate Slow Roast")
	run.items.powder = 3
	check(run.slow_roast_ready(), "Evolution, three rare powders and duration rank five activate Slow Roast")
	var enemy = run.spawn_enemy("tank")
	enemy.position = Vector2.ZERO
	enemy.hp = 100000
	enemy.set_physics_process(false)
	for i in range(50): run.deal_damage(enemy, 1, Vector2.ZERO, "fire")
	check(enemy.roast_stacks == 30 and enemy.roast_time == 4, "Heat caps at 30 and duration extends retention")
	var before = enemy.hp
	run.deal_damage(enemy, 100, Vector2.ZERO, "egg")
	check(is_equal_approx(before - enemy.hp, 340), "Other weapons cash in Heat for 3.4x damage")
	before = enemy.hp
	run.deal_damage(enemy, 100, Vector2.ZERO, "powder")
	check(is_equal_approx(before - enemy.hp, 100), "Secondary procs cannot amplify themselves through Heat")
	enemy._physics_process(4.1)
	check(enemy.roast_stacks == 0, "Heat expires when an enemy escapes the fire")
	enemy.position = Vector2.ZERO
	run.ranks = {"fire":1}
	run.items = {}
	run.evolved = {}
	for i in range(8): run.spawn_fire_patch(Vector2(i * 4, 0))
	before = enemy.hp
	run.fire_damage_clock = 0
	run.update_hazards(0.01)
	check(is_equal_approx(before - enemy.hp, 8), "Overlapping fire damages each enemy only once per tick")
	for i in range(1000): run.spawn_fire_patch(Vector2(i * 5, 100))
	check(run.hazards.size() == run.MAX_FIRE_PATCHES, "Fire population remains bounded")
	var total = 0
	for i in range(200): run.drop("xp",Vector2(i * 30, 200), 3)
	for pickup in run.pickup_registry.xp: total += pickup.value
	check(total == 600 and run.pickup_registry.xp.size() == 96, "Pickup consolidation preserves every base reward")
	var shot = run.make_shot(Vector2.ZERO,Vector2.RIGHT,"shell")
	shot.hostile = true
	shot.detonates = true
	shot.hit_ids[123] = true
	shot.retire()
	var recycled = run.make_shot(Vector2.ZERO,Vector2.RIGHT,"egg")
	check(recycled == shot and not recycled.hostile and not recycled.detonates and recycled.hit_ids.is_empty(), "Pooled projectiles reset allegiance, detonation and collision history")
	enemy.position = Vector2(65,0)
	run.combat_grid_dirty = true
	recycled.damage = 10
	before = enemy.hp
	recycled._physics_process(0.4)
	check(enemy.hp < before, "Swept projectile collision crosses spatial cells without tunneling")
	run.elapsed = 0
	var early = run.spawn_enemy("tank")
	run.elapsed = 600
	var late = run.spawn_enemy("tank")
	check(late.hp > early.hp * 10 and late.damage > early.damage * 3, "Late enemies are substantially tougher and more lethal")
	print("ENDGAME RESULT: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
