extends SceneTree
const Data = preload("res://scripts/survival/data.gd")
var failures = 0
var checks = 0
func _initialize(): call_deferred("test")
func check(ok: bool, title: String):
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ") + title)
func capture(name: String):
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0]+"/"+name+".png")
func test():
	Data.save_path = "user://coop_chest_test.cfg"
	Data.write_save({"muted":true})
	var run = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	run.set_physics_process(false)
	run.player.set_physics_process(false)
	var chest = run.drop("chest",run.player.position,1)
	check(run.chest_price()==30, "First paid chest costs 30")
	chest._process(0.1)
	check(not chest.opened and not chest.is_queued_for_deletion(), "Walking onto chest does not collect or spend")
	check(not run.try_open_chest(chest) and run.coins==0 and not chest.opened, "Unaffordable chest remains intact")
	run.coins = 100
	chest.position += Vector2(100,0)
	check(not run.try_open_chest(chest) and run.coins==100, "Out-of-range chest cannot be bought")
	chest.position = run.player.position + Vector2(20,0)
	run.ui.banner_time = 0
	await capture("chest-prompt")
	check(run.try_open_chest(chest), "Nearby chest opens deliberately")
	check(run.coins==70 and run.chest_price()==45, "Paid opening charges once and increases global price")
	check(paused and run.ui.mode=="chest" and run.offers.size()==1, "Chest pauses for a single random item reveal")
	check(not run.try_open_chest(chest) and run.coins==70, "Repeated input cannot double-charge chest")
	await capture("chest-reward")
	var rerolls = run.rerolls
	var reward = run.offers[0]
	run.reroll()
	check(run.rerolls==rerolls and run.offers==[reward], "Chest rewards cannot be rerolled")
	run.pending_levels = 2
	run.choose_upgrade(reward)
	check(run.items[reward]==1 and run.pending_levels==2 and not paused, "Claim stacks item without consuming level-ups")
	run.choose_upgrade(reward)
	check(run.items[reward]==1, "Reward cannot be claimed twice")
	run.items.clear()
	var free = run.drop("chest",run.player.position,0)
	run.coins=0
	check(run.try_open_chest(free), "Elite chest opens with no coins")
	check(run.coins==0 and run.paid_chests==1, "Free chest leaves price unchanged")
	run.choose_upgrade(run.offers[0])
	run.items = {"key":3}
	check(is_equal_approx(run.key_chance(),3.0/13), "Three keys use diminishing-return free chance")
	# Find a reproducible seed for a free proc without bypassing normal opening logic.
	var probe = RandomNumberGenerator.new()
	for seed_value in range(1000):
		probe.seed=seed_value
		if probe.randf()<run.key_chance():
			run.rng.seed=seed_value
			break
	run.coins=100
	var key_chest=run.drop("chest",run.player.position,1)
	check(run.try_open_chest(key_chest) and run.coins==100 and run.paid_chests==1, "Key proc grants free opening without price escalation")
	run.choose_upgrade(run.offers[0])
	run.items.clear()
	run.ranks={"egg":5,"haste":1}
	run.coins=100
	check(run.try_open_chest(run.drop("chest",run.player.position,1)) and run.evolved.has("egg") and run.ui.mode=="evolution", "Paid chests preserve evolution recipes")
	check(run.coins==55 and run.paid_chests==2, "Evolution chest still pays displayed price")
	run.ui.close_modal()
	paused=false
	for item in Data.ITEMS: run.items[item]=3
	run.try_open_chest(run.drop("chest",run.player.position,0))
	check(run.offers==["gold"], "Full collection safely falls back to coins")
	run.choose_upgrade("gold")
	check(run.pending_treasures==0, "Reward queue drains after salvage")
	print("CHEST RESULT: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
