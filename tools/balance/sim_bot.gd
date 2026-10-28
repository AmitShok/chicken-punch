extends Node
# Steering and choices for sim_run.gd. Runs before the player each physics tick.

const Data = preload("res://scripts/survival/data.gd")
var run: Node
var plan: Array = []
var dash_held = false

func _ready():
	process_physics_priority = -100
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _physics_process(_delta):
	if run.ended or get_tree().paused:
		release()
		return
	var me: Vector2 = run.player.global_position
	var push = Vector2.ZERO
	var closest = INF
	for enemy in run.nearby_enemies(me, 140):
		if not is_instance_valid(enemy) or enemy.dead: continue
		var offset = me - enemy.global_position
		var d = maxf(offset.length(), 1.0)
		closest = minf(closest, d - enemy.radius)
		push += offset / d * (1.0 / (d * d)) * (4.0 if enemy.boss else 1.0) * 4000.0
	for child in run.get_children():
		if child.get("hostile") == true and child.visible:
			var offset = me - child.global_position
			var d = maxf(offset.length(), 1.0)
			if d < 70: push += offset / d * (1.0 / (d * d)) * 6000.0
	# Collect pickups and chests when nothing is close.
	var goal = Vector2.ZERO
	if closest > 32:
		var target = null
		var best = INF
		for pickup in get_tree().get_nodes_in_group("run_pickups"):
			if not is_instance_valid(pickup) or pickup.get("opened"): continue
			if pickup.kind == "chest" and not pickup.chest_free and run.coins < run.chest_price(): continue
			var d = me.distance_to(pickup.global_position) * (0.5 if pickup.kind == "chest" else 1.0)
			if d < best:
				best = d
				target = pickup
		if target: goal = me.direction_to(target.global_position) * (1.6 if closest > 70 else 0.9)
	# Stay away from the arena walls and keep circling.
	var centre = run.arena_bounds.get_center()
	var wall = (centre - me) / maxf(run.arena_bounds.size.x, 1.0) * 2.5
	var orbit = (me - centre).orthogonal().normalized() * 0.25
	var steer = push + goal + wall + orbit
	if steer.length() < 0.05: steer = orbit
	steer = steer.normalized()
	release()
	if steer.x > 0: Input.action_press("right", steer.x)
	else: Input.action_press("left", -steer.x)
	if steer.y > 0: Input.action_press("down", steer.y)
	else: Input.action_press("up", -steer.y)
	if closest < 18 and run.player.ability_cooldown <= 0 and not dash_held:
		Input.action_press("dash")
		dash_held = true
	elif dash_held:
		Input.action_release("dash")
		dash_held = false
	run.try_open_chest()

func release():
	for action in ["left", "right", "up", "down"]:
		Input.action_release(action)

func handle_menus():
	var ui = run.ui
	if ui.mode in ["evolution", "ascension"]:
		ui.close_modal()
		get_tree().paused = false
	elif ui.mode == "chest":
		run.choose_upgrade(run.offers[0])
	elif ui.mode == "upgrade":
		run.choose_upgrade(pick(run.offers))

func pick(offers: Array) -> String:
	var best = offers[0]
	var best_score = -INF
	for key in offers:
		var score = 0.0
		var index = plan.find(key)
		score = 100.0 - index if index >= 0 else 0.0
		if key in Data.WEAPONS and run.ranks.get(key, 0) > 0: score += 30
		# Finish an evolution recipe when the weapon is close to max.
		for weapon in Data.EVOLUTIONS:
			if Data.EVOLUTIONS[weapon][0] == key and run.ranks.get(weapon, 0) >= 6 and run.ranks.get(key, 0) == 0: score += 40
		if key == "vitality" and run.player.hp < run.player.max_hp * 0.5: score += 50
		if score > best_score:
			best_score = score
			best = key
	return best
