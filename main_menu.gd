extends Control

const Data = preload("res://survival/data.gd")
const UI = preload("res://survival/interface.gd")
@export var game: PackedScene
var save: Dictionary
var menu: Control
var difficulty_index = 1
var preview = ""
var upgrades_open = false
var options_open = false

func _ready():
	save = Data.read_save()
	for child in get_children():
		if child.name != "Panel":
			child.hide()
	theme = UI.skin()
	preview = save.character
	build_menu()

func build_menu():
	if not Data.CHARACTERS.has(save.get("character", "")):
		save.character = "nugget"
	if is_instance_valid(menu):
		remove_child(menu)
		menu.queue_free()
	menu = CenterContainer.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu)
	var frame = PanelContainer.new()
	frame.custom_minimum_size = Vector2(780, 0)
	menu.add_child(frame)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	frame.add_child(box)
	var masthead = HBoxContainer.new()
	masthead.add_theme_constant_override("separation", 12)
	box.add_child(masthead)
	masthead.add_child(UI.portrait("nugget", 48))
	var brand = UI.label("OPTIONS" if options_open else "COOP UPGRADES" if upgrades_open else "CHICKENPUNCH", 34)
	brand.add_theme_color_override("font_color", UI.LEAF)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	masthead.add_child(brand)
	var stats = HBoxContainer.new()
	stats.add_theme_constant_override("separation", 32)
	box.add_child(stats)
	stats.add_child(UI.stat_chip("gold", str(save.gold), "Permanent upgrade gold: 1 per 15 seconds survived, +50 for victory"))
	stats.add_child(UI.stat_chip("clock", "%02d:%02d" % [save.best / 60, save.best % 60], "Best survival time"))
	stats.add_child(UI.stat_chip("trophy", str(save.wins), "Victories"))
	if options_open:
		var tabs = TabContainer.new()
		tabs.name = "OptionsTabs"
		tabs.custom_minimum_size = Vector2(740, 340)
		box.add_child(tabs)
		UI.add_options_pages(tabs, save, apply_options_audio)
		var back = UI.button("BACK", close_options)
		box.add_child(back)
		back.grab_focus()
		return
	var roster = HBoxContainer.new()
	roster.add_theme_constant_override("separation", 8)
	box.add_child(roster)
	for key in Data.CHARACTERS:
		var info = Data.CHARACTERS[key]
		var card = UI.button(info[0], select_character.bind(key))
		var colors = {"nugget": Color("f3d47c"), "pepper": Color("c4d49d"), "whisker": Color("f3bc8f"), "truffle": Color("eeb9ba"), "clover": Color("b8d9c8")}
		UI.paint_button(card, colors[key], UI.INK)
		card.name = "Character_" + key
		card.icon = Data.character_icon(key)
		# Tint only the portrait, leaving the card and its name readable in every state.
		if not save.unlocked.has(key):
			for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
				card.add_theme_color_override("icon_" + state + "_color", Color.BLACK)
		card.expand_icon = true
		card.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		card.add_theme_constant_override("icon_max_width", 48)
		card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		card.custom_minimum_size = Vector2(144, 80)
		card.toggle_mode = true
		card.button_pressed = preview == key
		if card.button_pressed:
			card.add_theme_stylebox_override("pressed", UI.box_style(Color("ffe6a0"), Color("b96332"), 8))
		card.tooltip_text = ("Locked. " if not save.unlocked.has(key) else "") + "Starts with " + Data.UPGRADES[info[1]][0]
		roster.add_child(card)
	var selected = Data.CHARACTERS[preview]
	box.add_child(UI.label(selected[0] + "  /  " + Data.UPGRADES[selected[1]][0], 19))
	if upgrades_open:
		build_training_menu(box)
		return
	var flavor = UI.label(selected[3], 14)
	flavor.custom_minimum_size.y = 38
	flavor.add_theme_color_override("font_color", UI.MUTED)
	box.add_child(flavor)
	var owned = save.unlocked.has(preview)
	var ready = save.best >= Data.CHARACTER_MILESTONES[preview]
	var start = UI.button("SURVIVE THE NIGHT" if owned else "UNLOCK %s / %d GOLD" % [selected[0], Data.CHARACTER_COSTS[preview]] if ready else "SURVIVE %d:%02d TO UNLOCK" % [Data.CHARACTER_MILESTONES[preview] / 60, Data.CHARACTER_MILESTONES[preview] % 60], _on_start_button_pressed if owned else unlock_character)
	start.name = "StartRun"
	start.disabled = not owned and (not ready or save.gold < Data.CHARACTER_COSTS[preview])
	UI.paint_button(start, UI.LEAF)
	box.add_child(start)
	var mode = OptionButton.new()
	mode.add_item("Relaxed")
	mode.add_item("Standard")
	mode.add_item("Ferocious")
	mode.select(difficulty_index)
	mode.item_selected.connect(func(index): difficulty_index = index)
	box.add_child(mode)
	var training_button = UI.button("COOP UPGRADES", show_training)
	training_button.name = "OpenUpgrades"
	box.add_child(training_button)
	var actions = HBoxContainer.new()
	box.add_child(actions)
	var options = UI.button("OPTIONS", _on_option_button_pressed)
	options.name = "OpenOptions"
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(options)
	var quit_button = UI.button("QUIT GAME", _on_exist_button_pressed)
	quit_button.name = "QuitGame"
	quit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.paint_button(quit_button, Color("a4513e"))
	actions.add_child(quit_button)
	start.grab_focus()

func show_training():
	upgrades_open = true
	build_menu()

func show_roster():
	upgrades_open = false
	build_menu()
	var opener = menu.find_child("OpenUpgrades", true, false)
	if opener: opener.grab_focus()

func _unhandled_key_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		if options_open: close_options()
		elif upgrades_open: show_roster()
		else: _on_option_button_pressed()
		get_viewport().set_input_as_handled()

func build_training_menu(box: VBoxContainer):
	var owned = save.unlocked.has(preview)
	var summary = HBoxContainer.new()
	summary.add_theme_constant_override("separation", 24)
	box.add_child(summary)
	var hint = UI.label("Upgrades apply only to " + Data.CHARACTERS[preview][0] + "." if owned else "Unlock this defender from the character menu first.", 14)
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
		card.custom_minimum_size.x = 360
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", UI.box_style(Color("fff8df"), Color("c4ac79"), 10))
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
	var back = UI.button("BACK TO CHARACTERS", show_roster)
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

func _on_start_button_pressed():
	if not save.unlocked.has(preview): return
	save.character = preview
	Data.write_save(save)
	get_tree().set_meta("difficulty", [0.75, 1.0, 1.3][difficulty_index])
	get_tree().change_scene_to_file("res://world.tscn")

func _on_option_button_pressed():
	options_open = true
	build_menu()

func close_options():
	options_open = false
	build_menu()
	var opener = menu.find_child("OpenOptions", true, false)
	if opener: opener.grab_focus()

func apply_options_audio():
	AudioServer.set_bus_mute(0, save.muted)
	for entry in [["Music", "music_volume"], ["SFX", "sfx_volume"]]:
		var index = AudioServer.get_bus_index(entry[0])
		if index >= 0:
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.001, save[entry[1]])))
			AudioServer.set_bus_mute(index, save[entry[1]] <= 0)

func _on_exist_button_pressed():
	get_tree().quit()
