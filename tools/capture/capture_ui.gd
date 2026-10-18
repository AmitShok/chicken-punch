extends SceneTree

func _initialize():
	call_deferred("capture")

func capture():
	preload("res://scripts/survival/data.gd").save_path = "user://coop_visual_test.cfg"
	var scene = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	scene.set_physics_process(false)
	scene.player.set_physics_process(false)
	scene.ranks = {"thunder": 3, "frost": 2, "sickle": 3, "shell": 2, "crit": 1, "duration": 2, "magnet": 1, "might": 2}
	scene.items = {"lens": 2, "honey": 1, "powder": 1, "crown": 1}
	scene.ui.refresh_inventory()
	scene.player.level = 9
	scene.elapsed = 185
	scene.boss_stage = 1
	for i in range(30):
		var enemy = scene.spawn_enemy(["dog", "bat", "tank", "caster"][i % 4])
		enemy.position = scene.player.position + Vector2.RIGHT.rotated(i * TAU / 30) * (70 + i * 3)
	var boss = scene.spawn_enemy("boss", true)
	boss.position = scene.player.position + Vector2(90, -40)
	scene.attack_weapons()
	scene.arsenal.tick(0.1)
	scene.ui.banner_time = 0
	scene.update_orbits(0.1)
	await create_timer(0.3).timeout
	paused = true
	await RenderingServer.frame_post_draw
	var directory = OS.get_cmdline_user_args()[0]
	root.get_texture().get_image().save_png(directory + "/combat.png")
	scene.offers = ["thunder", "sickle", "crit"]
	scene.offer_rarities = {"thunder": 1, "sickle": 2, "crit": 0}
	scene.ui.show_choices()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory + "/upgrades.png")
	scene.offer_kind = "item"
	scene.offers = ["powder", "lens", "honey"]
	scene.offer_rarities = {"powder": 2, "lens": 1, "honey": 0}
	scene.ui.show_choices()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory + "/items.png")
	scene.ui.close_modal()
	scene.ui.show_pause()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory + "/build.png")
	scene.ui.inspect_equipment("lens", true)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory + "/item-inspector.png")
	var tabs = scene.ui.modal.find_children("*", "TabContainer", true, false)[0]
	tabs.current_tab = 2
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory + "/audio.png")
	tabs.current_tab = 4
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory + "/credits.png")
	scene.ui.show_ascension("whiteout")
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory + "/ascension.png")
	scene.ui.show_evolution("frost")
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory + "/evolution.png")
	scene.ui.close_modal()
	for key in preload("res://scripts/survival/data.gd").ITEMS:
		scene.items[key] = 3
	scene.ui.refresh_inventory()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory + "/full-inventory.png")
	scene.ui.compact_hud = true
	scene.ui.apply_hud_layout()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory + "/compact-inventory.png")
	paused = false
	scene.music.stop()
	scene.queue_free()
	await create_timer(0.3).timeout
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory + "/menu.png")
	quit()


