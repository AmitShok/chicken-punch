extends SceneTree
# Defender abilities, the new weapons, tomes and items, and rarity-as-strength.
const Data = preload("res://scripts/survival/data.gd")
const Shot = preload("res://scripts/survival/projectile.gd")
var failures = 0
var checks = 0
var run: Node

func _initialize(): call_deferred("test")

func check(ok: bool, title: String):
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ") + title)

func fresh(character: String = "nugget"):
	if is_instance_valid(run):
		run.queue_free()
		await process_frame
	var save = {"muted": true, "character": character, "unlocked": Data.CHARACTERS.keys()}
	Data.write_save(save)
	run = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	await process_frame
	run.set_physics_process(false)
	run.player.set_physics_process(false)
	for enemy in run.enemies: enemy.queue_free()
	run.enemies.clear()
	run.spawn_clock = 1.0e9
	run.elite_clock = 1.0e9

func dummy(offset: Vector2, hp: float = 5000.0) -> Node:
	var enemy = run.spawn_enemy("tank")
	enemy.position = run.player.position + offset
	enemy.max_hp = hp
	enemy.hp = hp
	enemy.set_physics_process(false)
	run.rebuild_combat_grid()
	return enemy

func step(seconds: float):
	for i in range(int(seconds * 30)):
		run.pending_levels = 0
		run.pending_treasures = 0
		run.player._physics_process(1.0 / 30)
		run._physics_process(1.0 / 30)
		for child in run.get_children():
			if child is Shot and child.active:
				child.set_physics_process(false)
				child._physics_process(1.0 / 30)
		if i % 6 == 0: await process_frame

func test():
	Data.save_path = "user://coop_content_test.cfg"
	# Every defender has an ability that fires, sets its cooldown and affects the fight.
	for key in Data.CHARACTERS:
		await fresh(key)
		var def = Data.character_def(key)
		check(def.ability_name != "" and def.ability_description != "" and def.passive_description != "" and def.ability_cooldown > 0, key + " has an ability and passive described")
		run.player.facing = Vector2.RIGHT
		# Leap lands well ahead, so the frog's target waits where it lands.
		var front = dummy(Vector2(112 if key == "frog" else 30, 0))
		var back = dummy(Vector2(-30, 0))
		run.ranks = {Data.CHARACTERS[key][1]: 1}
		run.abilities.use()
		check(is_equal_approx(run.player.ability_cooldown, def.ability_cooldown), key + " ability starts its cooldown")
		if key == "nugget": check(run.player.invulnerability >= run.player.lunge_time + 0.2, "Flutter Dash is invulnerable for the whole dash and a grace window")
		await step(0.5)
		var hurt = front.hp < 5000 or back.hp < 5000 or front.slow_time > 0 or back.slow_time > 0
		check(hurt or key in ["nugget", "clover"], key + " ability affects nearby enemies")
		if key == "clover": check(run.player.invulnerability > 1.5 and run.orbit_rush > 1.5, "Hold the Line grants invulnerability and faster blades")
		if key == "nugget": check(run.player.position.x > 20, "Flutter Dash moves the player")
		if key == "donkey": check(back.hp < 5000 and front.hp == 5000, "Buck Kick only hits enemies behind")
	# Passives.
	await fresh("whisker")
	check(is_equal_approx(run.critical_chance(), 0.1), "Whisker's passive adds critical chance")
	await fresh("truffle")
	check(run.armor_value() == 1 and run.player.max_hp == 120, "Truffle's passive adds armor and health")
	await fresh("parrot")
	check(is_equal_approx(run.coin_multiplier(), 1.25), "Captain Squawk's passive adds coins")
	# New weapons damage enemies.
	for weapon in ["pitchfork", "carrot", "stink", "parrot"]:
		await fresh()
		run.player.facing = Vector2.RIGHT
		var target = dummy(Vector2(28, 0), 100000)
		run.ranks = {weapon: 5}
		await step(2.5)
		check(target.hp < 100000, weapon + " damages enemies")
		check(run.damage_totals.get(weapon, 0) > 0, weapon + " records its damage")
	await fresh()
	run.ranks = {"stink": 3}
	await step(0.2)
	check(is_instance_valid(run.stink_sprite) and run.stink_sprite.visible, "Stink Cloud shows its aura")
	# Hot Foot patches carry a range ring the size of their burn area.
	await fresh()
	run.ranks = {"fire": 3}
	run.spawn_fire_patch(Vector2(40, 40))
	var patch = run.hazards[-1]
	var ring = patch.sprite.get_node_or_null("Range")
	check(ring != null and is_equal_approx(ring.RADIUS * patch.sprite.scale.x, patch.radius), "Each fire patch shows a ring matching its burn radius")
	# Rarity raises strength, not rank.
	await fresh()
	run.ranks = {"egg": 1}
	run.offers = ["might"]
	run.offer_rarities = {"might": 2}
	run.offer_kind = "upgrade"
	run.pending_levels = 1
	run.choose_upgrade("might")
	check(run.ranks.might == 1 and is_equal_approx(run.level("might"), 2.0) and is_equal_approx(run.power(), 1.2), "An epic pick is one rank at double strength")
	run.offers = ["egg"]
	run.offer_rarities = {"egg": 1}
	run.items = {"anvil": 2}
	run.pending_levels = 1
	run.choose_upgrade("egg")
	check(run.ranks.egg == 2 and is_equal_approx(run.level("egg"), 3.0), "Rare weapon picks gain 1.5 and Rusty Anvil adds 0.5")
	# Tomes.
	await fresh()
	run.ranks = {"egg": 1, "evasion": 20}
	check(is_equal_approx(run.dodge_chance(), 0.4), "Feather Step caps dodge at 40%")
	run.ranks = {"egg": 1, "greed": 5}
	run.coins = 0
	run.collect({"kind": "gold", "value": 10})
	check(run.coins == 16, "Golden Harvest raises coin pickups")
	run.ranks = {"egg": 1, "thorns": 2}
	var attacker = dummy(Vector2(5, 0))
	run.on_player_struck(attacker)
	check(attacker.hp < 5000 and run.damage_totals.get("thorns", 0) > 0, "Bramble Coat damages attackers")
	run.ranks = {"egg": 1, "luck": 10}
	var rare = 0
	for i in range(400): if run.roll_rarity() > 0: rare += 1
	check(rare > 200, "Lucky Horseshoe makes rare and epic picks common")
	# Items.
	run.ranks = {"egg": 1}
	run.items = {"mallet": 50}
	var bonked = dummy(Vector2(40, 0), 1.0e9)
	run.deal_damage(bonked, 10, Vector2.ZERO, "egg")
	check(1.0e9 - bonked.hp >= 200, "Big Bonk Mallet can deal 20x damage")
	run.items = {"cheese": 13}
	var sick = dummy(Vector2(-40, 0), 1.0e9)
	run.deal_damage(sick, 100, Vector2.ZERO, "egg")
	check(sick.poison_time > 0 and sick.poison_dps > 0, "Moldy Cheese poisons on hit")
	var before = sick.hp
	sick.set_physics_process(true)
	await create_timer(0.7).timeout
	check(sick.hp < before, "Poison deals damage over time")
	sick.set_physics_process(false)
	run.items = {"ice_cube": 40}
	var frozen = dummy(Vector2(0, 40), 1.0e9)
	run.deal_damage(frozen, 1, Vector2.ZERO, "egg")
	check(frozen.slow_time > 0 and frozen.slow_factor == 0.0, "Ice Cube freezes on hit")
	# Exactly 100% critical chance: every hit crits once, never overcrits.
	run.items = {"hot_sauce": 4, "lens": 12}
	run.potency["crit"] = 0.5
	var crit_target = dummy(Vector2(0, -40), 1.0e9)
	run.deal_damage(crit_target, 10, Vector2.ZERO, "egg")
	check(is_equal_approx(1.0e9 - crit_target.hp, 30.0), "Hot Sauce raises critical damage to 3x with four stacks")
	run.items = {}
	run.offers = ["oats"]
	run.offer_kind = "item"
	run.pending_treasures = 1
	var health = run.player.max_hp
	run.choose_upgrade("oats")
	check(run.player.max_hp == health + 10, "Oat Sack adds max health")
	run.queue_free()
	print("CONTENT RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
