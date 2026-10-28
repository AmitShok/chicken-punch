extends SceneTree
# Plays one full run with a simple bot and prints a result line.
# Usage: godot --headless --path . --script res://tools/balance/sim_run.gd -- <profile> <seed> [character] [tier] [build]
#   profile: fresh (new save), veteran (everything unlocked, max training)
#   build:   greedy (default) or a build plan name from PLANS below
#   god:     pass "god" as a sixth argument to make the player unkillable,
#            which measures whether the build can out-damage the guardians
# The bot kites, dashes and picks upgrades by a fixed preference list. It is a
# relative yardstick for balance changes, not a model of a skilled human.

const Data = preload("res://scripts/survival/data.gd")
var scene: Node
var bot: Node
var args: PackedStringArray
var finishing = false
var lowest_hp = 1.0e9
var peak_dps_note = ""

# Preference order for upgrade picks; earlier entries are taken first.
const PLANS = {
	"greedy": ["egg", "shuriken", "thunder", "shell", "fire", "frost", "orbit", "sickle", "projectile_count", "might", "haste", "crit", "area", "vitality", "regen", "armor", "magnet", "speed", "duration", "projectile_size", "projectile_speed"],
	"overcrit": ["thunder", "frost", "crit", "duration", "might", "projectile_count", "haste", "vitality", "armor", "regen", "egg", "shuriken", "shell", "fire", "orbit", "sickle", "magnet", "area", "speed", "projectile_size", "projectile_speed"],
	"roast": ["fire", "egg", "area", "duration", "haste", "might", "vitality", "projectile_count", "armor", "regen", "crit", "shell", "frost", "thunder", "orbit", "sickle", "shuriken", "magnet", "speed", "projectile_size", "projectile_speed"]
}

func _initialize():
	call_deferred("start")

func start():
	args = OS.get_cmdline_user_args()
	var profile = args[0] if args.size() > 0 else "fresh"
	var seed_value = int(args[1]) if args.size() > 1 else 1
	var character = args[2] if args.size() > 2 else "nugget"
	var tier = int(args[3]) if args.size() > 3 else 0
	Data.save_path = "user://balance_sim_%s_%d_%s_%d.cfg" % [profile, seed_value, character, tier]
	var save = {"muted": true, "character": character, "unlocked": ["nugget", character]}
	if profile == "veteran":
		save.unlocked = Data.CHARACTERS.keys()
		save.equipment_unlocks = Data.UPGRADES.keys()
		save.item_unlocks = Data.ITEMS.keys()
		save.training = {}
		for key in Data.CHARACTERS:
			save.training[key] = {"power": 5, "heart": 5, "weapon_slots": 4, "tome_slots": 4}
		save.best = 600
		save.wins = 1
		save.stats = {"best_time": 600, "best_level": 60, "best_guardians": 3, "best_rank": 10, "best_crit": 10, "best_dashes": 200, "best_low_hp": 120, "best_tier_won": 3, "kills": 20000, "chests": 100, "guardians": 30, "evolutions": 10, "evolved_fire": 2, "wins": 5, "runs": 40}
	Data.write_save(save)
	set_meta("level_id", "meadow")
	set_meta("difficulty_tier", tier)
	set_meta("difficulty", Data.DIFFICULTIES[tier].power)
	scene = load("res://scenes/world/world.tscn").instantiate()
	scene.rng = RandomNumberGenerator.new()
	root.add_child(scene)
	current_scene = scene
	scene.rng.seed = seed_value
	seed(seed_value)
	bot = preload("res://tools/balance/sim_bot.gd").new()
	bot.run = scene
	if args.size() > 5 and args[5] == "god":
		scene.player.max_hp = 1.0e9
		scene.player.hp = 1.0e9
	bot.plan = PLANS.get(args[4] if args.size() > 4 else "greedy", PLANS.greedy)
	scene.add_child(bot)
	Engine.time_scale = 10
	Engine.max_physics_steps_per_frame = 16

func _process(_delta):
	if finishing or not is_instance_valid(scene):
		return false
	bot.handle_menus()
	if not scene.ended:
		lowest_hp = minf(lowest_hp, scene.player.hp)
	if scene.ended or scene.elapsed > 780:
		finishing = true
		var weapons = scene.ranks.keys().filter(func(k): return k in Data.WEAPONS)
		var tomes = scene.ranks.keys().filter(func(k): return not k in Data.WEAPONS)
		print("SIM god=%s profile=%s seed=%s char=%s tier=%s won=%s time=%d level=%d kills=%d guardians=%d evolved=%s ascension=%s weapons=%s tomes=%s items=%d" % [args.size() > 5 and args[5] == "god", args[0], args[1], scene.player.character_key, scene.difficulty_tier, scene.final_boss_dead, scene.elapsed, scene.player.level, scene.kills, scene.guardians_defeated, ",".join(scene.evolved.keys()), scene.ascension, ",".join(weapons.map(func(k): return "%s%d" % [k, scene.ranks[k]])), ",".join(tomes.map(func(k): return "%s%d" % [k, scene.ranks[k]])), scene.items.values().reduce(func(a, b): return a + b, 0)])
		call_deferred("finish_run")
	return false

func finish_run():
	Engine.time_scale = 1
	paused = false
	scene.queue_free()
	await create_timer(0.2).timeout
	quit()
