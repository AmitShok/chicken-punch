extends SceneTree
const Data = preload("res://survival/data.gd")
const UI = preload("res://survival/interface.gd")
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
func remove_scene(node):
	paused = false
	root.remove_child(node)
	node.queue_free()
func test():
	Data.save_path = "user://coop_progression_test.cfg"
	Data.write_save({"gold":1000,"power":2,"heart":1,"character":"truffle","muted":true})
	var saved = Data.read_save()
	check(saved.gold == 1000 and saved.unlocked.has("truffle"),"Legacy balance and selected character are preserved")
	check(Data.training(saved,"pepper").power==2 and Data.training(saved).heart==1,"Legacy upgrade ranks preserved for every character")
	Data.write_save({"gold":1000,"muted":true})
	var menu = load("res://main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	check(menu.save.unlocked==["nugget"],"Fresh progression starts with Nugget")
	menu.select_character("pepper")
	menu.unlock_character()
	check(menu.save.gold==1000 and not menu.save.unlocked.has("pepper"),"Milestone blocks early character purchase")
	menu.save.best = 300
	menu.unlock_character()
	check(menu.save.gold==960 and menu.save.character=="pepper","Character purchase charges gold and selects defender")
	menu.unlock_character()
	check(menu.save.gold==960,"Character cannot be bought twice")
	menu.purchase("power")
	check(Data.training(menu.save,"pepper").power==1 and Data.training(menu.save,"nugget").power==0,"Damage upgrades belong to selected character only")
	menu.purchase("weapon_slots")
	menu.purchase("weapon_slots")
	menu.purchase("weapon_slots")
	check(Data.training(menu.save).weapon_slots==4 and menu.save.gold==680,"Weapon slots charge 80 then 160 and stop at four")
	check(Data.training(menu.save).tome_slots==2,"Tome capacity is independent")
	menu.purchase("tome_slots")
	check(Data.training(menu.save).tome_slots==3 and Data.training(menu.save,"nugget").weapon_slots==2,"Slot upgrades belong to selected character")
	await capture("coop-progression")
	remove_scene(menu)
	await process_frame
	var run = load("res://world.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	run.set_physics_process(false)
	run.player.set_physics_process(false)
	check(is_equal_approx(run.power(),1.05),"Run uses selected character damage rank")
	run.ranks={"egg":1,"fire":1,"might":1,"haste":1,"area":1}
	check(not run.eligible_upgrades().has("speed") and run.eligible_upgrades().has("shell"),"Purchased tome and weapon capacities govern upgrade offers")
	var mob=run.spawn_enemy("dog")
	var initial_hp=mob.max_hp
	var initial_damage=mob.damage
	mob.hp=mob.max_hp*0.5
	run.elapsed=600
	mob.update_scaling()
	check(mob.max_hp>initial_hp*9 and mob.damage>initial_damage*2,"Health and damage rise throughout the run")
	check(is_equal_approx(mob.hp/mob.max_hp,0.5),"Existing enemies scale without restoring lost health percentage")
	for key in Data.UPGRADES:
		check(Data.icon(key)!=null,"Upgrade icon loads: "+key)
		if key not in Data.WEAPONS: check(Data.icon(key).resource_path.contains("tome_"),"Tome uses book artwork: "+key)
	for key in Data.WEAPONS:
		check(Data.icon(key,false,true)!=Data.icon(key),"Evolution has distinct artwork: "+key)
		run.evolved[key]=true
	for key in ["egg","shuriken","frost","sickle","shell"]:
		var shot=run.make_shot(run.player.position,Vector2.RIGHT,key)
		check(shot.get_node("Sprite").texture==Data.icon(key,false,true) and shot.get_node("Sprite").hframes==1,"Evolved projectile uses new sprite: "+key)
		run.remove_child(shot)
		shot.queue_free()
	for pickup in get_nodes_in_group("run_pickups"):
		pickup.queue_free()
	await process_frame
	var magnet=run.drop("magnet",run.player.position+Vector2(100,0),1)
	check(magnet.get_node("Sprite").texture.resource_path.ends_with("Coop/magnet.png"),"Magnet pickup uses horseshoe magnet")
	run.ui.update_objectives()
	check(run.ui.compass.target_label=="Magnet" and is_zero_approx(run.ui.compass.bearing),"Compass labels nearest pickup and points east")
	magnet.position=run.player.position+Vector2(0,-100)
	run.ui.update_objectives()
	check(is_equal_approx(run.ui.compass.bearing,-PI/2),"Compass points north correctly")
	var chest=run.drop("chest",run.player.position+Vector2(-60,0),0)
	run.ui.update_objectives()
	check(run.ui.compass.target_label=="Free chest","Compass chooses closer chest and identifies free type")
	chest.queue_free()
	magnet.queue_free()
	await process_frame
	run.ui.update_objectives()
	check(not run.ui.compass.active,"Compass clears when targets disappear")
	run.drop("magnet",run.player.position+Vector2(75,0),1)
	run.ranks={"egg":5,"shell":5,"sickle":5,"orbit":5,"might":5,"haste":5,"area":5}
	run.ui.refresh_inventory()
	run.ui.banner_time=0
	run.update_orbits(0.1)
	run.ui.update_objectives()
	await capture("compass-evolutions")
	remove_scene(run)
	await process_frame
	# Artwork gallery also catches import failures and bad sprite framing.
	var gallery=PanelContainer.new()
	gallery.theme=UI.skin()
	gallery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(gallery)
	var grid=GridContainer.new()
	grid.columns=7
	gallery.add_child(grid)
	for key in Data.UPGRADES:
		var cell=VBoxContainer.new()
		cell.custom_minimum_size=Vector2(120,120)
		grid.add_child(cell)
		var art=UI.icon(key,false,64)
		art.texture=Data.icon(key,false,key in Data.WEAPONS)
		cell.add_child(art)
		cell.add_child(UI.label(Data.EVOLUTIONS[key][1] if key in Data.WEAPONS else Data.UPGRADES[key][0],14))
	await capture("tomes-evolved-art")
	gallery.queue_free()
	await process_frame
	print("PROGRESSION RESULT: %d checks, %d failures" % [checks,failures])
	quit(failures)
