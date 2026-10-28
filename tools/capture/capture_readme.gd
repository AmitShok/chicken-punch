extends SceneTree
# Regenerates docs/logo.png and the README screenshots in docs/screenshots/.
# godot --path . --script res://tools/capture/capture_readme.gd
# Uses its own save file, so your progress is untouched.

const Data = preload("res://scripts/survival/data.gd")
const UI = preload("res://scripts/survival/interface.gd")
var out = ""

func _initialize(): call_deferred("capture")

func snap(name: String, settle: int = 3):
	for i in range(settle): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + "/" + name + ".png")
	print("saved ", name)

func veteran_save(character: String):
	var save = {"muted": true, "character": character, "gold": 845, "best": 612, "wins": 3, "unlocked": Data.CHARACTERS.keys(), "equipment_unlocks": Data.UPGRADES.keys(), "item_unlocks": Data.ITEMS.keys()}
	save.stats = {"best_time": 612, "best_level": 41, "best_guardians": 3, "best_rank": 10, "kills": 6200, "chests": 31, "guardians": 9, "evolutions": 4, "wins": 3, "runs": 27, "best_dashes": 120}
	Data.write_save(save)

func start_run(character: String, ranks: Dictionary, items: Dictionary, evolved: Array, elapsed: float) -> Node:
	veteran_save(character)
	var run = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	await process_frame
	paused = false
	run.elapsed = elapsed
	run.boss_stage = 1 if elapsed >= 180 else 0
	run.spawn_clock = 1.0e9
	run.elite_clock = 1.0e9
	run.ranks = ranks
	run.items = items
	for key in evolved: run.evolved[key] = true
	run.player.max_hp = 1.0e6
	run.player.hp = 1.0e6 * 0.82
	run.player.level = 23
	# Kills during a capture must not open the level-up screen.
	run.player.max_xp = 1000000000
	run.coins = 64
	run.ui.refresh_inventory()
	return run

func horde(run: Node, count: int):
	for i in range(count):
		var e = run.spawn_enemy(["dog", "bat", "tank", "caster", "dog", "bat"][i % 6])
		e.position = run.player.position + Vector2.RIGHT.rotated(i * 2.4) * (70 + (i % 9) * 22)

func move(direction: Vector2, seconds: float):
	for action in ["left", "right", "up", "down"]: Input.action_release(action)
	if direction.x > 0: Input.action_press("right", direction.x)
	if direction.x < 0: Input.action_press("left", -direction.x)
	if direction.y > 0: Input.action_press("down", direction.y)
	if direction.y < 0: Input.action_press("up", -direction.y)
	await create_timer(seconds).timeout
	for action in ["left", "right", "up", "down"]: Input.action_release(action)

func end_run(run: Node):
	paused = false
	run.music.stop()
	run.queue_free()
	await process_frame

func capture():
	out = ProjectSettings.globalize_path("res://docs/screenshots")
	DirAccess.make_dir_recursive_absolute(out)
	Data.save_path = "user://readme_capture.cfg"

	# Logo: the Travel Book banner with the title in m6x11 at 4x.
	get_root().transparent_bg = true
	var logo_root = Control.new()
	logo_root.theme = UI.skin()
	logo_root.size = Vector2(960, 640)
	root.add_child(logo_root)
	var center = CenterContainer.new()
	center.size = Vector2(960, 640)
	logo_root.add_child(center)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	center.add_child(row)
	row.add_child(UI.portrait("nugget", 112))
	var plate = UI.title_banner("CHICKENPUNCH")
	plate.get_node("BannerTitle").add_theme_font_size_override("font_size", 64)
	plate.custom_minimum_size = Vector2(560, 0)
	row.add_child(plate)
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	var image = root.get_texture().get_image()
	image.crop(960, 640)
	var used = image.get_used_rect()
	image.blit_rect(image, used, Vector2i.ZERO)
	image.crop(used.size.x, used.size.y)
	image.save_png(ProjectSettings.globalize_path("res://docs/logo.png"))
	print("saved logo")
	logo_root.queue_free()
	get_root().transparent_bg = false
	await process_frame

	# Menus.
	veteran_save("pepper")
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await snap("main_menu")
	menu.show_setup()
	menu.select_character("pepper")
	await snap("run_setup")
	menu.show_quests()
	menu.select_quest("guardian_2")
	await snap("quests")
	menu.show_shop()
	menu.shop_tab = 0
	menu.shop_selected = "carrot"
	menu.build_menu()
	await snap("shop")
	var key = InputEventKey.new()
	key.keycode = KEY_F12
	key.pressed = true
	menu._unhandled_key_input(key)
	await snap("dev_menu")
	menu.queue_free()
	await process_frame

	# Combat: a mid-run build with several weapons and a crowd.
	var run = await start_run("nugget", {"egg": 8, "fire": 7, "stink": 6, "parrot": 6, "might": 5, "area": 4, "haste": 4}, {"lens": 2, "honey": 2, "bead": 1, "crown": 1}, ["egg"], 250)
	horde(run, 70)
	await move(Vector2(0.8, 0.3), 1.0)
	await move(Vector2(-0.2, -0.9), 0.9)
	run.ui.banner_time = 0
	await snap("combat")
	await end_run(run)

	# Abilities: Barnaby's Buck Kick into a crowd.
	run = await start_run("donkey", {"pitchfork": 7, "carrot": 6, "might": 4, "thorns": 3}, {"oats": 2}, [], 140)
	horde(run, 40)
	await move(Vector2(1, 0), 0.8)
	run.player.facing = Vector2.RIGHT
	run.abilities.use()
	await create_timer(0.1).timeout
	run.ui.banner_time = 0
	await snap("ability")
	await end_run(run)

	# A guardian fight.
	run = await start_run("truffle", {"shell": 8, "frost": 7, "thunder": 6, "might": 6, "crit": 4}, {"crown": 2, "lens": 3}, ["shell"], 365)
	run.boss_stage = 2
	var boss = run.spawn_enemy("boss", true)
	boss.position = run.player.position + Vector2(70, -30)
	horde(run, 26)
	await move(Vector2(-0.5, 0.3), 1.4)
	await move(Vector2(0.3, 0.6), 1.0)
	run.ui.announce("GUARDIAN 2 / 3", "Rotating rings and aimed volleys. The horde keeps coming.")
	run.ui.banner_time = 0
	await snap("guardian")
	await end_run(run)

	# Level up and the build inspector.
	run = await start_run("whisker", {"sickle": 6, "thunder": 4, "crit": 3, "luck": 2}, {"lens": 1, "silk": 1}, [], 200)
	run.ui.banner_time = 0
	run.pending_levels = 0
	run.show_upgrades()
	run.offers = ["sickle", "crit", "luck"]
	run.offer_rarities = {"sickle": 2, "crit": 1, "luck": 0}
	run.ui.show_choices()
	await snap("level_up")
	run.ui.close_modal()
	paused = false
	run.ui.show_pause()
	await snap("build")
	await end_run(run)
	quit()
