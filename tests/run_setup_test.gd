extends SceneTree
const Data = preload("res://scripts/survival/data.gd")
var failures = 0
var checks = 0
func _initialize(): call_deferred("test")
func check(ok: bool, title: String):
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ") + title)
func snap(title: String):
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0] + "/" + title + ".png")
func test():
	Data.save_path = "user://run_setup_test.cfg"
	Data.write_save({"gold":500,"muted":true})
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	check(menu.page == "home" and menu.menu.find_child("Character_nugget",true,false) == null, "Home is separate from run setup")
	await snap("new-home")
	menu.menu.find_child("StartRun",true,false).pressed.emit()
	check(menu.page == "setup" and current_scene == menu, "Survive the Night opens setup without launching")
	check(menu.menu.find_child("BeginRun",true,false) != null, "Setup has an explicit begin action")
	menu.select_character("pepper")
	check(menu.menu.find_child("BeginRun",true,false).disabled, "Locked character cannot start")
	menu.select_level("orchard")
	check(menu.level_id == "meadow", "Locked level cannot be selected")
	menu.select_difficulty(2)
	check(menu.difficulty_index == 0, "Locked tier cannot be selected")
	menu.select_character("nugget")
	await snap("new-setup")
	menu.show_shop()
	check(not Data.purchase_access(menu.save,"thunder"), "Quest requirement blocks early purchase")
	menu.save.best = 360
	menu.build_menu()
	await snap("new-shop")
	for tab in [1,2,3]:
		menu.shop_tab = tab
		menu.build_menu()
		await snap("shop-tab-" + str(tab))
	menu.show_training()
	await snap("new-training")
	menu._on_option_button_pressed()
	await snap("new-options")
	check(Data.purchase_access(menu.save,"thunder"), "Eligible equipment purchase succeeds")
	check(menu.save.gold == 440, "Shop charges permanent gold")
	check(not Data.purchase_access(menu.save,"thunder") and menu.save.gold == 440, "Duplicate purchase never charges twice")
	check(Data.equipment_owned(Data.read_save(),"thunder"), "Equipment access persists after reload")
	menu.save.gold = 0
	check(not Data.purchase_access(menu.save,"frost"), "Insufficient gold blocks purchase")
	menu.save.gold = 440
	menu.preview = "pepper"
	menu.unlock_character()
	check(Data.equipment_owned(menu.save,"fire"), "Character ownership includes starting weapon access")
	menu.save.level_clears.meadow = 1
	check(Data.difficulty_available(menu.save,"meadow",1) and not Data.difficulty_available(menu.save,"orchard",1), "Difficulty unlocks are per level")
	Data.write_save(menu.save)
	menu.queue_free()
	await process_frame
	var run = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	run.set_physics_process(false)
	run.player.set_physics_process(false)
	run.ranks = {}
	check(run.eligible_upgrades().has("thunder") and not run.eligible_upgrades().has("frost"), "Only unlocked equipment enters level-up pool")
	for key in Data.UPGRADES:
		run.ranks = {key:9}
		run.offers = [key]
		run.offer_rarities = {key:2}
		run.offer_kind = "upgrade"
		run.choose_upgrade(key)
		check(run.ranks[key] == 10 and not run.eligible_upgrades().has(key), key + " caps at ten and leaves reward pool")
	for key in Data.ITEMS:
		run.items = {key:9}
		run.offers = [key]
		run.offer_kind = "item"
		run.choose_upgrade(key)
		check(run.items[key] == 10, key + " item caps at ten")
	run.items = {}
	for i in range(15):
		run.show_treasure()
		check(run.offers.all(func(k): return k == "gold" or Data.equipment_owned(run.save,k,true)), "Chest respects item access")
		run.ui.close_modal()
		paused = false
	for pickup in get_nodes_in_group("run_pickups"): pickup.queue_free()
	await process_frame
	for kind in ["xp","gold","heal"]: run.drop(kind,run.player.position + Vector2(5,0),1)
	var magnet = run.drop("magnet",run.player.position + Vector2(120,0),1)
	run.ui.update_objectives()
	check(run.ui.compass.target_label == "Magnet", "Compass ignores nearer XP, coins and health")
	magnet.queue_free()
	await process_frame
	run.ui.update_objectives()
	check(not run.ui.compass.active, "Compass clears when only excluded pickups remain")
	run.queue_free()
	await process_frame
	for level in Data.LEVELS:
		set_meta("level_id",level)
		set_meta("difficulty",1.35)
		set_meta("difficulty_tier",1)
		run = load("res://scenes/world/world.tscn").instantiate()
		root.add_child(run)
		current_scene = run
		run.set_physics_process(false)
		run.player.set_physics_process(false)
		await physics_frame
		check(run.level_id == level and run.reward_multiplier == 1.3, level + " run receives selected settings")
		check(level == "meadow" or run.get_node("LevelScenery").get_child_count() > 20, level + " has real level geometry")
		for i in range(10):
			var pos = run.walkable_position(250)
			check(run.arena_bounds.has_point(pos), level + " spawn stays inside arena")
		run.ui.banner_time = 0
		await snap("level-" + level)
		run.elapsed = 600
		run.finish(true)
		check(Data.read_save().level_clears[level] >= 2 and run.gold_earned == 117, "Victory saves tier unlock and reward multiplier")
		paused = false
		run.queue_free()
		await process_frame
	for key in ["level_id","difficulty","difficulty_tier"]: remove_meta(key)
	menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu.show_setup()
	menu.select_character("pepper")
	menu.select_level("orchard")
	menu.select_difficulty(1)
	menu._on_start_button_pressed()
	await process_frame
	await process_frame
	check(current_scene != menu and current_scene.level_id == "orchard" and current_scene.difficulty_tier == 1 and current_scene.ranks.has("fire"), "Begin Run launches selected character, level and difficulty")
	for key in ["level_id","difficulty","difficulty_tier"]: remove_meta(key)
	print("RUN SETUP RESULT: %d checks, %d failures" % [checks,failures])
	quit(failures)
