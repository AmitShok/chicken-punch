extends SceneTree
# Quest-gated unlocks, build-tool milestones and run recording.
const Data = preload("res://scripts/survival/data.gd")
var failures = 0
var checks = 0
func _initialize(): call_deferred("test")
func check(ok: bool, title: String):
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ") + title)
func test():
	Data.save_path = "user://coop_quest_test.cfg"
	Data.write_save({"gold": 1000, "muted": true})
	var save = Data.read_save()
	check(Data.quests_completed(save) == 0, "A new save has no quests complete")
	check(Data.tool_uses(save, "reroll") == 1 and Data.tool_uses(save, "skip") == 0 and Data.tool_uses(save, "banish") == 0, "A new save starts with one reroll only")
	for key in ["egg", "fire", "vitality", "speed", "magnet", "regen"]:
		check(Data.equipment_owned(save, key), key + " is starter gear")
	for key in ["shuriken", "frost", "might", "haste", "projectile_count", "crit"]:
		check(not Data.equipment_owned(save, key), key + " starts locked")
	for key in ["honey", "lunch", "bead"]:
		check(Data.equipment_owned(save, key, true), key + " is a starter item")
	for key in ["lens", "berserk", "powder", "crown"]:
		check(not Data.equipment_owned(save, key, true), key + " starts locked")
	check(not Data.purchase_access(save, "might") and save.gold == 1000, "Gold alone cannot buy quest-locked gear")
	var unlocked = Data.record_run(save, {"best_time": 200, "best_level": 16, "best_guardians": 1, "kills": 600, "chests": 4, "guardians": 1, "runs": 1})
	for id in ["survive_3", "level_15", "kills_500", "guardian_1"]:
		check(unlocked.has(id), "Run completes " + id)
	check(not unlocked.has("survive_5") and not unlocked.has("kills_1000"), "Unmet quests stay open")
	check(Data.purchase_access(save, "might") and save.gold == 920, "A finished quest lets gold buy its gear")
	check(Data.equipment_owned(Data.read_save(), "might"), "Purchases persist")
	check(Data.tool_uses(save, "reroll") == 2 and Data.tool_uses(save, "skip") == 1, "Quest milestones add build tools")
	var again = Data.record_run(save, {"best_time": 100, "kills": 500, "runs": 1})
	check(again.has("kills_1000") and Data.stat(save, "best_time") == 200 and Data.stat(save, "kills") == 1100, "Totals add up while bests keep the maximum")
	# Older saves keep credit for their best time and wins.
	var legacy = ConfigFile.new()
	legacy.set_value("coop", "best", 320)
	legacy.set_value("coop", "wins", 2)
	legacy.save(Data.save_path)
	var migrated = Data.read_save()
	check(Data.quest_done(migrated, "survive_5") and Data.quest_done(migrated, "win") and not Data.quest_done(migrated, "wins_3"), "Old saves keep quest credit for best time and wins")
	for id in Data.QUESTS:
		check(Data.STAT_KEYS.has(Data.QUESTS[id][1]), id + " reads a tracked stat")
	for def in Data.CATALOG.equipment + Data.CATALOG.items + Data.CATALOG.characters:
		check(def.unlock_quest == "" or Data.QUESTS.has(def.unlock_quest), def.key + " names a real quest")
		var is_starter = def.get("starter") == true or def.key == "nugget"
		check(is_starter or def.unlock_quest != "", def.key + " is either a starter or quest-locked")
	# A run records its stats when it ends.
	Data.write_save({"gold": 0, "muted": true})
	var run = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	await process_frame
	run.set_physics_process(false)
	run.elapsed = 190
	run.kills = 520
	run.player.level = 15
	run.ranks = {"egg": 10}
	run.dashes = 3
	run.chests_opened = 2
	run.finish(false)
	var after = Data.read_save()
	check(run.new_quests.has("survive_3") and run.new_quests.has("kills_500") and run.new_quests.has("max_rank") and run.new_quests.has("level_15"), "Ending a run records its quests")
	check(Data.stat(after, "chests") == 2 and Data.stat(after, "runs") == 1, "Run counters are saved")
	check(run.gold_earned == 12 + 13, "Gold pays for time and kills")
	paused = false
	run.queue_free()
	print("QUEST RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
