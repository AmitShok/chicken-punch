extends Control
const Data = preload("res://scripts/survival/data.gd")
const UI = preload("res://scripts/survival/interface.gd")
@export var game: PackedScene
var save: Dictionary
var menu: Control
var difficulty_index = 0
var level_id = "meadow"
var preview = "nugget"
var page = "home"
var shop_tab = 0
var upgrades_open = false
var options_open = false

func _ready():
	save = Data.read_save()
	for child in get_children():
		if child.name != "Panel": child.hide()
	theme = UI.skin()
	preview = save.character
	build_menu()

func build_menu():
	if is_instance_valid(menu):
		remove_child(menu)
		menu.queue_free()
	menu = CenterContainer.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu)
	var frame = PanelContainer.new()
	frame.custom_minimum_size = Vector2(860, 568)
	menu.add_child(frame)
	UI.book_frame(frame)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	frame.add_child(box)
	var masthead = HBoxContainer.new()
	box.add_child(masthead)
	masthead.add_child(UI.portrait(preview, 40))
	var title = UI.label({"home":"CHICKENPUNCH", "setup":"SURVIVE THE NIGHT", "shop":"COOP SHOP", "training":"COOP UPGRADES", "options":"OPTIONS"}[page], 30)
	title.add_theme_color_override("font_color", UI.LEAF)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	masthead.add_child(title)
	masthead.add_child(UI.stat_chip("gold", str(save.gold), "Permanent gold for unlocks and training"))
	masthead.add_child(UI.stat_chip("clock", "%02d:%02d" % [save.best / 60, save.best % 60], "Best survival time"))
	masthead.add_child(UI.stat_chip("trophy", str(save.wins), "Victories"))
	match page:
		"home": build_home(box)
		"setup": build_setup(box)
		"shop": build_shop(box)
		"training":
			var select = OptionButton.new()
			for key in Data.CHARACTERS: select.add_item(Data.CHARACTERS[key][0])
			select.select(Data.CHARACTERS.keys().find(preview))
			select.item_selected.connect(func(i): select_character(Data.CHARACTERS.keys()[i]))
			box.add_child(select)
			build_training_menu(box)
		"options":
			var tabs = TabContainer.new()
			tabs.name = "OptionsTabs"
			tabs.custom_minimum_size = Vector2(740, 340)
			box.add_child(tabs)
			UI.add_options_pages(tabs, save, apply_options_audio)
			box.add_child(UI.button("BACK", close_options))

func build_home(box: VBoxContainer):
	var center = CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(center)
	var content = VBoxContainer.new()
	content.custom_minimum_size.x = 350
	content.add_theme_constant_override("separation", 12)
	center.add_child(content)
	content.add_child(UI.portrait("nugget", 96))
	var start = UI.button("SURVIVE THE NIGHT", show_setup)
	start.name = "StartRun"
	start.custom_minimum_size.y = 52
	UI.paint_button(start, UI.LEAF)
	content.add_child(start)
	var shop = UI.button("COOP SHOP", show_shop)
	shop.name = "OpenShop"
	content.add_child(shop)
	var training = UI.button("COOP UPGRADES", show_training)
	training.name = "OpenUpgrades"
	content.add_child(training)
	var options = UI.button("OPTIONS", _on_option_button_pressed)
	options.name = "OpenOptions"
	content.add_child(options)
	var quit_button = UI.button("QUIT GAME", _on_exist_button_pressed)
	quit_button.name = "QuitGame"
	quit_button.visible = not OS.has_feature("web")
	content.add_child(quit_button)
	start.grab_focus()

func build_setup(box: VBoxContainer):
	var columns = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(columns)
	var roster = VBoxContainer.new()
	roster.custom_minimum_size.x = 238
	columns.add_child(roster)
	roster.add_child(UI.label("DEFENDER", 18))
	for key in Data.CHARACTERS:
		var owned = save.unlocked.has(key)
		var card = UI.button(Data.CHARACTERS[key][0], select_character.bind(key))
		card.name = "Character_" + key
		card.icon = Data.character_icon(key)
		card.expand_icon = true
		card.add_theme_constant_override("icon_max_width", 32)
		card.custom_minimum_size.y = 48
		card.toggle_mode = true
		card.button_pressed = preview == key
		card.tooltip_text = "Starts with " + Data.UPGRADES[Data.CHARACTERS[key][1]][0] if owned else "Unlock in Coop Shop > Characters"
		if not owned:
			for state in ["normal", "hover", "pressed", "focus"]: card.add_theme_color_override("icon_" + state + "_color", Color.BLACK)
		roster.add_child(card)
	roster.add_child(UI.label(Data.CHARACTERS[preview][3], 14))
	var settings = VBoxContainer.new()
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.add_theme_constant_override("separation", 8)
	columns.add_child(settings)
	settings.add_child(UI.label("LEVEL", 18))
	var maps = HBoxContainer.new()
	settings.add_child(maps)
	for key in Data.LEVELS:
		var entry = Data.LEVELS[key]
		var card = UI.button(entry.name.replace(" ", "\n"), select_level.bind(key))
		card.name = "Level_" + key
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size.y = 68
		card.disabled = not Data.level_available(save, key)
		card.toggle_mode = true
		card.button_pressed = level_id == key
		card.tooltip_text = entry.description if not card.disabled else "Survive %d minutes to unlock" % (entry.best / 60)
		maps.add_child(card)
	settings.add_child(UI.label(Data.LEVELS[level_id].description, 15))
	settings.add_child(UI.label("DIFFICULTY", 18))
	var modes = HBoxContainer.new()
	settings.add_child(modes)
	for i in range(Data.DIFFICULTIES.size()):
		var card = UI.button(Data.DIFFICULTIES[i].name, select_difficulty.bind(i))
		card.name = "Difficulty_" + str(i)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.disabled = not Data.difficulty_available(save, level_id, i)
		card.toggle_mode = true
		card.button_pressed = difficulty_index == i
		card.tooltip_text = "Clear the previous difficulty on this level" if card.disabled else Data.DIFFICULTIES[i].description
		modes.add_child(card)
	settings.add_child(UI.label(Data.DIFFICULTIES[difficulty_index].description, 15))
	settings.add_child(UI.label("Starting weapon: " + Data.UPGRADES[Data.CHARACTERS[preview][1]][0], 18))
	settings.add_child(UI.label("Weapon slots %d / Tome slots %d" % [Data.training(save,preview).weapon_slots, Data.training(save,preview).tome_slots], 14))
	var actions = HBoxContainer.new()
	box.add_child(actions)
	actions.add_child(UI.button("BACK", show_roster))
	var start = UI.button("BEGIN RUN" if save.unlocked.has(preview) else "UNLOCK IN COOP SHOP", _on_start_button_pressed)
	start.name = "BeginRun"
	start.disabled = not save.unlocked.has(preview)
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.paint_button(start, UI.LEAF)
	actions.add_child(start)

func build_shop(box: VBoxContainer):
	box.add_child(UI.label("Permanent access · purchased gear can appear in future runs", 15))
	var tabs = TabBar.new()
	for title in ["Weapons", "Tomes", "Items", "Characters"]: tabs.add_tab(title)
	tabs.current_tab = shop_tab
	tabs.tab_changed.connect(func(i): shop_tab = i; build_menu())
	box.add_child(tabs)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 345
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	var entries = Data.CHARACTERS.keys() if shop_tab == 3 else Data.ITEMS.keys() if shop_tab == 2 else Data.UPGRADES.keys().filter(func(k): return (k in Data.WEAPONS) == (shop_tab == 0))
	for key in entries:
		var character = shop_tab == 3
		var item = shop_tab == 2
		var info = Data.CHARACTERS[key] if character else Data.ITEMS[key] if item else Data.UPGRADES[key]
		var owned = save.unlocked.has(key) if character else Data.equipment_owned(save,key,item)
		var requirement = Data.CHARACTER_MILESTONES[key] if character else Data.unlock_requirement(key,item)
		var cost = Data.CHARACTER_COSTS[key] if character else Data.unlock_cost(key,item)
		var panel = PanelContainer.new()
		panel.custom_minimum_size.x = 376
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", UI.paper_style("Popup01a", 10))
		grid.add_child(panel)
		var content = VBoxContainer.new()
		panel.add_child(content)
		var heading = HBoxContainer.new()
		content.add_child(heading)
		var icon = UI.portrait(key,32) if character else UI.icon(key,item,32)
		if character and not owned: icon.modulate = Color.BLACK
		heading.add_child(icon)
		var equipment_title = UI.label(info[0],18)
		equipment_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(equipment_title)
		var detail = UI.label("Starts with " + Data.UPGRADES[info[1]][0] if character else info[1],14)
		detail.custom_minimum_size = Vector2(340, 44)
		content.add_child(detail)
		var text = "OWNED" if owned else "SURVIVE %d:%02d  (%d:%02d)" % [requirement / 60, requirement % 60, mini(save.best,requirement) / 60, mini(save.best,requirement) % 60] if save.best < requirement else "UNLOCK · %d GOLD" % cost
		var buy = UI.button(text, buy_shop.bind(key, character, item))
		buy.name = "Unlock_" + key
		buy.disabled = owned or save.best < requirement or save.gold < cost
		buy.tooltip_text = "Unlocks access, not an immediate run upgrade."
		content.add_child(buy)
	box.add_child(UI.button("BACK", show_roster))

func buy_shop(key: String, character: bool, item: bool):
	if character:
		preview = key
		unlock_character()
	else:
		Data.purchase_access(save,key,item)
		build_menu()

func select_level(key: String):
	if not Data.level_available(save,key): return
	level_id = key
	if not Data.difficulty_available(save,key,difficulty_index): difficulty_index = 0
	build_menu()

func select_difficulty(index: int):
	if not Data.difficulty_available(save,level_id,index): return
	difficulty_index = index
	build_menu()

func show_setup():
	page = "setup"
	build_menu()
func show_shop():
	page = "shop"
	build_menu()
func show_training():
	page = "training"
	upgrades_open = true
	build_menu()
func show_roster():
	page = "home"
	upgrades_open = false
	options_open = false
	build_menu()
func _on_option_button_pressed():
	page = "options"
	options_open = true
	build_menu()
func close_options(): show_roster()
func _unhandled_key_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		if page == "home": _on_option_button_pressed()
		else: show_roster()
		get_viewport().set_input_as_handled()

func _on_start_button_pressed():
	if page != "setup":
		show_setup()
		return
	if not save.unlocked.has(preview) or not Data.level_available(save,level_id) or not Data.difficulty_available(save,level_id,difficulty_index): return
	save.character = preview
	Data.write_save(save)
	get_tree().set_meta("difficulty", Data.DIFFICULTIES[difficulty_index].power)
	get_tree().set_meta("difficulty_tier", difficulty_index)
	get_tree().set_meta("level_id", level_id)
	get_tree().change_scene_to_file("res://scenes/world/world.tscn")

func build_training_menu(box: VBoxContainer):
	var owned = save.unlocked.has(preview)
	var summary = HBoxContainer.new()
	summary.add_theme_constant_override("separation", 24)
	box.add_child(summary)
	var hint = UI.label("Upgrades apply only to " + Data.CHARACTERS[preview][0] + "." if owned else "Unlock this defender in the Characters shop tab.", 14)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.add_theme_color_override("font_color", UI.MUTED)
	summary.add_child(hint)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.name = "UpgradeGrid"
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	box.add_child(grid)
	var track = Data.training(save, preview)
	for key in ["power", "heart", "weapon_slots", "tome_slots"]:
		var rank = track[key]
		var slots = key.ends_with("slots")
		var maximum = 4 if slots else 5
		var cost = 80 * (rank - 1) if slots else 40 + rank * 30
		var title = {"power": "Fighting Spirit", "heart": "A Hardy Hen", "weapon_slots": "Weapon Slots", "tome_slots": "Tome Slots"}[key]
		var card = PanelContainer.new()
		card.custom_minimum_size.x = 340
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", UI.paper_style("Popup01a", 12))
		grid.add_child(card)
		var content = VBoxContainer.new()
		content.add_theme_constant_override("separation", 4)
		card.add_child(content)
		content.add_child(UI.label(title, 19))
		var effect = "%d / 4 unlocked" % rank if slots else "+%d%% damage  /  Rank %d of 5" % [rank * 5, rank] if key == "power" else "+%d max HP  /  Rank %d of 5" % [rank * 10, rank]
		content.add_child(UI.label(effect, 14))
		var step = "+1 slot" if slots else "+5% damage" if key == "power" else "+10 HP"
		var buy = UI.button("MAXED" if rank >= maximum else "%s  /  %d gold" % [step, cost], purchase.bind(key))
		buy.name = "Buy_" + key
		buy.add_theme_font_size_override("font_size", 16)
		buy.disabled = not owned or rank >= maximum or save.gold < cost
		UI.paint_button(buy, UI.LEAF)
		content.add_child(buy)
	var back = UI.button("BACK", show_roster)
	back.name = "BackToCharacters"
	box.add_child(back)
	back.grab_focus()

func select_character(key: String):
	if not Data.CHARACTERS.has(key):
		return
	preview = key
	if save.unlocked.has(key):
		save.character = key
		Data.write_save(save)
	build_menu()
	var selected_button = menu.find_child("Character_" + key, true, false)
	if selected_button:
		selected_button.grab_focus()

func unlock_character():
	if save.unlocked.has(preview) or save.best < Data.CHARACTER_MILESTONES[preview] or save.gold < Data.CHARACTER_COSTS[preview]: return
	save.gold -= Data.CHARACTER_COSTS[preview]
	save.unlocked.append(preview)
	save.character = preview
	Data.write_save(save)
	build_menu()

func purchase(key: String):
	if not save.unlocked.has(preview): return
	var track = Data.training(save, preview)
	if not track.has(key): return
	var slots = key.ends_with("slots")
	var cost = 80 * (track[key] - 1) if slots else 40 + track[key] * 30
	if track[key] >= (4 if slots else 5) or save.gold < cost: return
	save.gold -= cost
	track[key] += 1
	Data.write_save(save)
	build_menu()
	var buy = menu.find_child("Buy_" + key, true, false)
	if buy and not buy.disabled: buy.grab_focus()

func apply_options_audio():
	AudioServer.set_bus_mute(0, save.muted)
	for entry in [["Music", "music_volume"], ["SFX", "sfx_volume"]]:
		var index = AudioServer.get_bus_index(entry[0])
		if index >= 0:
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.001, save[entry[1]])))
			AudioServer.set_bus_mute(index, save[entry[1]] <= 0)

func _on_exist_button_pressed():
	get_tree().quit()
