extends SceneTree
# The hidden developer page and in-run debug keys.
const Data = preload("res://scripts/survival/data.gd")
var failures = 0
var checks = 0
func _initialize(): call_deferred("test")
func check(ok: bool, title: String):
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ") + title)
func key(code: int) -> InputEventKey:
	var event = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event
func test():
	Data.save_path = "user://coop_dev_test.cfg"
	Data.write_save({"gold": 0, "muted": true, "music_volume": 0.3})
	check(OS.is_debug_build(), "Tests run in a debug build, where the developer tools exist")
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu._unhandled_key_input(key(KEY_F12))
	check(menu.page == "dev" and menu.menu.find_child("Dev_quests", true, false) != null, "F12 opens the developer page")
	check(menu.menu.find_child("Tab_dev", true, false) == null, "The developer page has no visible tab")
	menu.menu.find_child("Dev_next_quest", true, false).pressed.emit()
	check(Data.quests_completed(menu.save) == 1, "Complete the next quest finishes exactly one")
	menu.menu.find_child("Dev_quests", true, false).pressed.emit()
	check(Data.quests_completed(Data.read_save()) == Data.QUESTS.size(), "Complete every quest persists")
	check(Data.tool_uses(menu.save, "banish") == 3 and Data.tool_uses(menu.save, "reroll") == 4, "Completed quests grant every build tool")
	menu.menu.find_child("Dev_gold", true, false).pressed.emit()
	check(Data.read_save().gold == 1000, "Add gold persists")
	menu.menu.find_child("Dev_unlock_all", true, false).pressed.emit()
	var saved = Data.read_save()
	check(Data.UPGRADES.keys().all(func(k): return Data.equipment_owned(saved, k)) and Data.ITEMS.keys().all(func(k): return Data.equipment_owned(saved, k, true)) and saved.unlocked.size() == Data.CHARACTERS.size(), "Unlock all owns every weapon, tome, item and defender")
	menu.menu.find_child("Dev_training", true, false).pressed.emit()
	check(Data.read_save().training.values().all(func(t): return t.power == 5 and t.weapon_slots == 4 and t.tome_slots == 4), "Max training applies to every defender")
	menu.menu.find_child("Dev_levels", true, false).pressed.emit()
	saved = Data.read_save()
	check(Data.LEVELS.keys().all(func(l): return Data.level_available(saved, l) and Data.difficulty_available(saved, l, 2)), "Every level and difficulty unlocks")
	menu.menu.find_child("Dev_reset", true, false).pressed.emit()
	check(Data.read_save().gold == 1000 and menu.menu.find_child("Dev_reset", true, false).text == "PRESS AGAIN TO RESET", "Reset needs a second press")
	menu.menu.find_child("Dev_reset", true, false).pressed.emit()
	saved = Data.read_save()
	check(saved.gold == 0 and Data.quests_completed(saved) == 0 and saved.unlocked == ["nugget"] and is_equal_approx(saved.music_volume, 0.3), "Reset clears progress but keeps audio settings")
	menu._unhandled_key_input(key(KEY_F12))
	check(menu.page == "home", "F12 closes the developer page")
	menu.queue_free()
	await process_frame
	# In-run keys.
	var run = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	await process_frame
	run.set_physics_process(false)
	var level = run.player.level
	check(run.dev_key(KEY_F1) and run.player.level == level + 1 and run.pending_levels == 1, "F1 gains a level")
	run.pending_levels = 0
	run.dev_key(KEY_F2)
	check(run.nearest_chest(30) != null and run.nearest_chest(30).chest_free, "F2 drops a free chest at your feet")
	run.dev_key(KEY_F3)
	check(run.coins == 100, "F3 adds coins")
	run.dev_key(KEY_F4)
	check(is_equal_approx(run.elapsed, 175.0), "F4 skips to just before the next guardian")
	run.ranks = {"egg": 2, "might": 1}
	run.dev_key(KEY_F5)
	check(run.ranks.egg == 10 and run.ranks.might == 10 and is_equal_approx(run.level("might"), 10.0), "F5 maxes everything owned")
	check(not run.dev_key(KEY_F9), "Other keys are left alone")
	run.queue_free()
	print("DEV RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
