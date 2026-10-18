extends SceneTree
const Data = preload("res://survival/data.gd")
var failures = 0
var checks = 0
func _initialize(): call_deferred("test")
func check(ok: bool, title: String):
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ") + title)
func test():
	Data.save_path = "user://coop_currency_test.cfg"
	var legacy = ConfigFile.new()
	legacy.set_value("coop", "coins", 321)
	legacy.set_value("coop", "power", 2)
	legacy.set_value("coop", "muted", true)
	legacy.save(Data.save_path)
	var saved = Data.read_save()
	check(saved.gold == 321 and saved.power == 2, "Legacy balance and upgrade ranks survive migration")
	check(not saved.has("coins"), "Persistent save exposes gold only")
	Data.write_save(saved)
	var migrated = ConfigFile.new()
	migrated.load(Data.save_path)
	check(migrated.get_value("coop", "gold") == 321 and not migrated.has_section_key("coop", "coins"), "Writing migrates to a single permanent gold balance")
	migrated.set_value("coop", "coins", 999)
	migrated.save(Data.save_path)
	check(Data.read_save().gold == 321, "Gold takes precedence over stale legacy coins")
	var run = load("res://world.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	run.set_physics_process(false)
	run.player.set_physics_process(false)
	check(run.coins == 0 and run.save.gold == 321, "Run starts without coins despite banked gold")
	var chest = run.drop("chest",run.player.position,1)
	check(not run.try_open_chest(chest), "Permanent gold cannot buy a chest")
	run.coins = 100
	check(run.try_open_chest(chest) and run.coins == 70 and run.save.gold == 321, "Chest spends only coins")
	run.choose_upgrade(run.offers[0])
	run.elapsed = 150
	run.finish(false)
	check(run.gold_earned == 10 and Data.read_save().gold == 331, "Survival awards gold independently of unspent coins")
	check(run.coins == 70, "Results do not convert coins into gold")
	run.finish(true)
	check(Data.read_save().gold == 331, "Finishing twice cannot duplicate rewards")
	paused = false
	root.remove_child(run)
	run.queue_free()
	await process_frame
	var menu = load("res://main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu.purchase("heart")
	check(Data.read_save().gold == 291 and Data.training(Data.read_save()).heart == 1, "Coop upgrade spends permanent gold")
	root.remove_child(menu)
	menu.queue_free()
	await process_frame
	run = load("res://world.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	run.set_physics_process(false)
	run.player.set_physics_process(false)
	check(run.coins == 0 and run.save.gold == 291, "Retry resets coins and preserves gold")
	run.elapsed = 600
	run.finish(true)
	check(run.gold_earned == 90 and Data.read_save().gold == 381, "Victory awards survival gold plus 50")
	paused = false
	root.remove_child(run)
	run.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks,failures])
	quit(failures)
