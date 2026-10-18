extends SceneTree

const Data = preload("res://scripts/survival/data.gd")
var failures = 0
var checks = 0

func check(ok: bool, title: String):
	checks += 1
	if not ok:
		failures += 1
	print(("PASS: " if ok else "FAIL: ") + title)

func _initialize():
	call_deferred("test")

func tab():
	var key = InputEventKey.new()
	key.physical_keycode = KEY_TAB
	key.keycode = KEY_TAB
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	key = InputEventKey.new()
	key.physical_keycode = KEY_TAB
	key.keycode = KEY_TAB
	Input.parse_input_event(key)
	await process_frame

func capture(name: String):
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0] + "/" + name + ".png")

func test():
	Data.save_path = "user://coop_roster_test.cfg"
	var weapons = []
	for key in Data.CHARACTERS:
		Data.write_save({"character": key, "coins": 0, "muted": true})
		var run = load("res://scenes/world/world.tscn").instantiate()
		root.add_child(run)
		current_scene = run
		await process_frame
		run.set_physics_process(false)
		run.player.set_physics_process(false)
		run.ui.banner_time = 0
		var weapon = Data.CHARACTERS[key][1]
		check(run.ranks.size() == 1 and run.ranks.get(weapon, 0) == 1, key + " starts with exactly its own weapon")
		check(not weapons.has(weapon), key + " has a distinct starting weapon")
		weapons.append(weapon)
		check(run.player.animated_sprite_2d.sprite_frames.has_animation("Walk"), key + " has movement animation")
		check(Data.character_icon(key) != null, key + " portrait loads")
		if key == "nugget":
			await process_frame
			check(run.ui.health.size.x <= 180 and run.ui.health.size.y <= 10, "HP bar is compact")
			await capture("compact-hud")
			await tab()
			check(run.ui.compact_hud and run.ui.health.visible and run.ui.inventory_panel.visible and run.ui.inventory_panel.size.x <= 145, "Tab compacts inventory while preserving essential HUD")
			await capture("compact-mode")
			run.ui.show_pause()
			check(run.ui.modal.visible, "Pause menu remains visible with compact HUD")
			await tab()
			check(run.ui.compact_hud, "Tab in a menu preserves gameplay HUD preference")
			run.ui.close_modal()
			paused = false
			await tab()
			check(not run.ui.compact_hud and run.ui.health.visible, "Second gameplay Tab restores HUD")
		await capture("character-" + key)
		run.queue_free()
		await process_frame
	Data.write_save({"character": "invalid", "muted": true})
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	check(menu.save.character == "nugget", "Unknown saved character falls back safely")
	menu.save.unlocked.append("whisker")
	menu.select_character("whisker")
	check(Data.read_save().character == "whisker", "Character selection persists")
	menu.select_character("nugget")
	await process_frame
	check(menu.find_child("QuitGame", true, false).pressed.is_connected(menu._on_exist_button_pressed), "Quit button is wired to exit")
	await capture("character-menu")
	print("ROSTER RESULT: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
