extends Control
const Data = preload("res://scripts/survival/data.gd")
const UI = preload("res://scripts/survival/interface.gd")
const Book = preload("res://scripts/ui/book_surface.gd")
@export var game: PackedScene
var save: Dictionary
var menu: Control
var difficulty_index = 0
var level_id = "meadow"
var preview = "nugget"
var page = "home"
var shop_tab = 0
var shop_selected = ""
var quest_selected = ""
# Rebuilding a page recreates its list, so selections carry the scroll offset over.
var list_scroll = 0
var detail_page: VBoxContainer
var reset_armed = false
var upgrades_open = false
var options_open = false

func _ready():
	save = Data.read_save()
	for child in get_children():
		if child.name != "Panel": child.hide()
	theme = UI.skin()
	preview = save.character
	Data.ensure_audio_buses()
	apply_options_audio()
	var music = AudioStreamPlayer.new()
	music.name = "MenuMusic"
	music.stream = Data.music_stream("menu")
	music.volume_db = -17
	music.bus = "Music"
	music.finished.connect(music.play)
	add_child(music)
	if DisplayServer.get_name() != "headless":
		music.play()
	build_menu()

const PAGES = {
	"home": ["COOP", "IconHome01a", "CHICKENPUNCH"],
	"setup": ["RUN", "IconPlay01a", "SURVIVE THE NIGHT"],
	"quests": ["QUESTS", "IconTick01a", "COOP QUESTS"],
	"shop": ["SHOP", "IconCoin01a", "COOP SHOP"],
	"training": ["TRAINING", "IconStar01a", "COOP UPGRADES"],
	"options": ["OPTIONS", "IconGear01a", "OPTIONS"]
}

func build_menu():
	if is_instance_valid(menu):
		remove_child(menu)
		menu.queue_free()
	menu = CenterContainer.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu)
	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 0)
	menu.add_child(stack)
	var title = UI.title_banner(PAGES[page][2] if PAGES.has(page) else "DEVELOPER")
	title.z_index = 1
	stack.add_child(title)
	# Bookmark tabs sit behind the cover's top edge; a paper wallet holds the records.
	var tab_row = HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 4)
	tab_row.custom_minimum_size.y = 44
	stack.add_child(tab_row)
	var inset = Control.new()
	inset.custom_minimum_size.x = 26
	tab_row.add_child(inset)
	for key in PAGES:
		var tab = UI.book_tab(PAGES[key][0], PAGES[key][1], page == key, open_page.bind(key))
		tab.name = "Tab_" + key
		tab_row.add_child(tab)
	var gap = Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_row.add_child(gap)
	var wallet = PanelContainer.new()
	wallet.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	wallet.add_theme_stylebox_override("panel", UI.paper_style("Popup01a", 6))
	tab_row.add_child(wallet)
	var chips = HBoxContainer.new()
	chips.add_theme_constant_override("separation", 10)
	wallet.add_child(chips)
	chips.add_child(UI.stat_chip("gold", str(save.gold), "Permanent gold for unlocks and training"))
	chips.add_child(UI.stat_chip("clock", "%02d:%02d" % [save.best / 60, save.best % 60], "Best survival time"))
	chips.add_child(UI.stat_chip("trophy", str(save.wins), "Victories"))
	var tuck = Control.new()
	tuck.custom_minimum_size.x = 18
	tab_row.add_child(tuck)
	var frame = PanelContainer.new()
	frame.custom_minimum_size = Vector2(880, 486)
	stack.add_child(frame)
	var pages = UI.book_spread(frame, {"home": 330, "setup": 300, "quests": 420, "shop": 400, "training": 300, "options": 250, "dev": 330}[page])
	match page:
		"home": build_home(pages[0], pages[1])
		"setup": build_setup(pages[0], pages[1])
		"shop": build_shop(pages[0], pages[1])
		"quests": build_quests(pages[0], pages[1])
		"training": build_training_menu(pages[0], pages[1])
		"options": build_options(pages[0], pages[1])
		"dev": build_dev(pages[0], pages[1])
	var footer = Control.new()
	footer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pages[0].add_child(footer)
	pages[0].add_child(UI.hint_row([["Esc", "Options" if page == "home" else "Back"], ["Enter", "Select"]]))

func open_page(key: String):
	match key:
		"home": show_roster()
		"setup": show_setup()
		"shop": show_shop()
		"quests": show_quests()
		"training": show_training()
		"options": _on_option_button_pressed()

static func page_heading(text: String) -> Label:
	var heading = UI.label(text, 16)
	heading.add_theme_color_override("font_color", UI.MUTED)
	return heading

static func list_row(text: String, icon: Texture2D, action: Callable, selected: bool = false) -> Button:
	var row = UI.button(text, action)
	row.icon = icon
	row.expand_icon = true
	row.add_theme_constant_override("icon_max_width", 28)
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.custom_minimum_size.y = 40
	row.toggle_mode = true
	row.button_pressed = selected
	return row

func build_home(left: VBoxContainer, right: VBoxContainer):
	var showcase = UI.portrait(preview, 128)
	showcase.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	left.add_child(showcase)
	var name_label = UI.label(Data.CHARACTERS[preview][0].to_upper(), 32)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(name_label)
	var flavor = UI.label(Data.CHARACTERS[preview][3], 16)
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(flavor)
	left.add_child(UI.label("Starts with " + Data.UPGRADES[Data.CHARACTERS[preview][1]][0], 16))
	left.add_child(ability_text(preview))
	left.add_child(UI.label("Defenders owned  %d / %d" % [save.unlocked.size(), Data.CHARACTERS.size()], 16))
	right.add_child(page_heading("WHAT WILL IT BE TONIGHT?"))
	var start = list_row("SURVIVE THE NIGHT", Book.art("IconPlay01a"), show_setup)
	start.name = "StartRun"
	start.toggle_mode = false
	start.custom_minimum_size.y = 52
	UI.paint_button(start, UI.LEAF)
	right.add_child(start)
	var shop = list_row("COOP SHOP", Book.art("IconCoin01a"), show_shop)
	shop.name = "OpenShop"
	right.add_child(shop)
	var training = list_row("COOP UPGRADES", Book.art("IconStar01a"), show_training)
	training.name = "OpenUpgrades"
	right.add_child(training)
	var options = list_row("OPTIONS", Book.art("IconGear01a"), _on_option_button_pressed)
	options.name = "OpenOptions"
	right.add_child(options)
	var quit_button = list_row("QUIT GAME", Book.art("IconCross01a"), _on_exist_button_pressed)
	quit_button.name = "QuitGame"
	quit_button.visible = not OS.has_feature("web")
	right.add_child(quit_button)
	for row in [shop, training, options, quit_button]:
		row.toggle_mode = false
	start.grab_focus()

func build_setup(left: VBoxContainer, right: VBoxContainer):
	left.add_child(page_heading("DEFENDER"))
	for key in Data.CHARACTERS:
		var owned = save.unlocked.has(key)
		var card = list_row(Data.CHARACTERS[key][0] + ("" if owned else "  (locked)"), Data.character_icon(key), select_character.bind(key), preview == key)
		card.name = "Character_" + key
		card.add_theme_constant_override("icon_max_width", 32)
		card.custom_minimum_size.y = 46
		card.tooltip_text = "Starts with " + Data.UPGRADES[Data.CHARACTERS[key][1]][0] if owned else "Unlock in Coop Shop > Characters"
		if not owned:
			for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]: card.add_theme_color_override("icon_" + state + "_color", Color.BLACK)
		left.add_child(card)
	right.add_child(page_heading("LEVEL"))
	var maps = HBoxContainer.new()
	right.add_child(maps)
	for key in Data.LEVELS:
		var entry = Data.LEVELS[key]
		var card = UI.button(entry.name.replace(" ", "\n"), select_level.bind(key))
		card.name = "Level_" + key
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size.y = 60
		card.disabled = not Data.level_available(save, key)
		card.toggle_mode = true
		card.button_pressed = level_id == key
		card.tooltip_text = entry.description if not card.disabled else "Survive %d minutes to unlock" % (entry.best / 60)
		maps.add_child(card)
	right.add_child(UI.label(Data.LEVELS[level_id].description, 16))
	right.add_child(page_heading("DIFFICULTY"))
	var modes = HBoxContainer.new()
	right.add_child(modes)
	for i in range(Data.DIFFICULTIES.size()):
		var card = UI.button(Data.DIFFICULTIES[i].name, select_difficulty.bind(i))
		card.name = "Difficulty_" + str(i)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.disabled = not Data.difficulty_available(save, level_id, i)
		card.toggle_mode = true
		card.button_pressed = difficulty_index == i
		card.tooltip_text = "Clear the previous difficulty on this level" if card.disabled else Data.DIFFICULTIES[i].description
		modes.add_child(card)
	right.add_child(UI.label(Data.DIFFICULTIES[difficulty_index].description, 16))
	right.add_child(UI.label(Data.CHARACTERS[preview][3], 16))
	right.add_child(ability_text(preview))
	right.add_child(UI.label("Starting weapon: %s    Weapon slots %d / Tome slots %d" % [Data.UPGRADES[Data.CHARACTERS[preview][1]][0], Data.training(save,preview).weapon_slots, Data.training(save,preview).tome_slots], 16))
	var push = Control.new()
	push.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(push)
	var start = UI.button("BEGIN RUN" if save.unlocked.has(preview) else "UNLOCK IN COOP SHOP", _on_start_button_pressed)
	start.name = "BeginRun"
	start.disabled = not save.unlocked.has(preview)
	start.custom_minimum_size.y = 48
	UI.paint_button(start, UI.LEAF)
	right.add_child(start)

func build_shop(left: VBoxContainer, right: VBoxContainer):
	var tabs = TabBar.new()
	for title in ["Weapons", "Tomes", "Items", "Defenders"]: tabs.add_tab(title)
	tabs.current_tab = shop_tab
	tabs.tab_changed.connect(func(i):
		shop_tab = i
		shop_selected = ""
		build_menu())
	left.add_child(tabs)
	var scroll = ScrollContainer.new()
	scroll.name = "ListScroll"
	restore_scroll.call_deferred(scroll)
	scroll.custom_minimum_size.y = 330
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var character = shop_tab == 3
	var item = shop_tab == 2
	var entries = Data.CHARACTERS.keys() if character else Data.ITEMS.keys() if item else Data.UPGRADES.keys().filter(func(k): return (k in Data.WEAPONS) == (shop_tab == 0))
	if not entries.has(shop_selected):
		shop_selected = entries[0]
	for key in entries:
		var info = Data.CHARACTERS[key] if character else Data.ITEMS[key] if item else Data.UPGRADES[key]
		var owned = save.unlocked.has(key) if character else Data.equipment_owned(save, key, item)
		var row = list_row(info[0], Data.character_icon(key) if character else Data.icon(key, item), select_shop_entry.bind(key), key == shop_selected)
		row.name = "Entry_" + key
		var status = UI.label("Owned" if owned else "%d g" % (Data.CHARACTER_COSTS[key] if character else Data.unlock_cost(key, item)), 16)
		status.add_theme_color_override("font_color", UI.LEAF if owned else UI.MUTED)
		status.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
		status.offset_left = -70
		status.offset_right = -10
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(status)
		list.add_child(row)
	detail_page = right
	build_shop_detail(right)

# Right page: the selected entry in detail. Rebuilt alone on selection so the
# list on the left keeps its scroll position without a flicker.
func build_shop_detail(right: VBoxContainer):
	var character = shop_tab == 3
	var item = shop_tab == 2
	var key = shop_selected
	var info = Data.CHARACTERS[key] if character else Data.ITEMS[key] if item else Data.UPGRADES[key]
	var owned = save.unlocked.has(key) if character else Data.equipment_owned(save, key, item)
	var quest = Data.CHARACTER_QUESTS[key] if character else Data.unlock_quest(key, item)
	var quest_ready = Data.quest_done(save, quest)
	var cost = Data.CHARACTER_COSTS[key] if character else Data.unlock_cost(key, item)
	var heading = HBoxContainer.new()
	heading.add_theme_constant_override("separation", 12)
	right.add_child(heading)
	var art = UI.portrait(key, 64) if character else UI.icon(key, item, 64)
	if character and not owned: art.modulate = Color.BLACK
	heading.add_child(art)
	var heading_text = VBoxContainer.new()
	heading_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(heading_text)
	var entry_name = UI.label(info[0], 32)
	entry_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading_text.add_child(entry_name)
	heading_text.add_child(page_heading(["WEAPON", "TOME", "ITEM", "DEFENDER"][shop_tab]))
	right.add_child(UI.label("Starts with " + Data.UPGRADES[info[1]][0] + ". " + info[3] if character else info[1], 16))
	if character: right.add_child(ability_text(key))
	var push = Control.new()
	push.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(push)
	if quest == "" and not owned:
		right.add_child(UI.label("Starter gear.", 16))
	elif quest != "":
		var line = UI.label(("QUEST DONE  /  " if quest_ready else "QUEST  /  ") + Data.QUESTS[quest][0] + ("" if quest_ready else "  (" + Data.quest_progress(save, quest) + ")"), 16)
		line.add_theme_color_override("font_color", UI.LEAF if quest_ready else UI.INK)
		right.add_child(line)
	right.add_child(page_heading("Purchased gear can appear in future runs. It is not an immediate upgrade."))
	var text = "OWNED" if owned else "COMPLETE THE QUEST FIRST" if not quest_ready else "UNLOCK  /  %d GOLD" % cost
	var buy = UI.button(text, buy_shop.bind(key, character, item))
	buy.name = "Unlock_" + key
	buy.disabled = owned or not quest_ready or save.gold < cost
	buy.custom_minimum_size.y = 48
	UI.paint_button(buy, UI.LEAF)
	right.add_child(buy)

func select_shop_entry(key: String):
	shop_selected = key
	refresh_selection("Entry_", key, build_shop_detail)

func build_options(left: VBoxContainer, right: VBoxContainer):
	var tabs = TabContainer.new()
	tabs.name = "OptionsTabs"
	tabs.tabs_visible = false
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(tabs)
	UI.add_options_pages(tabs, save, apply_options_audio)
	left.add_child(page_heading("SETTINGS"))
	var rows: Array[Button] = []
	for i in range(tabs.get_tab_count()):
		var row = list_row(tabs.get_tab_title(i), null, func(): tabs.current_tab = i, i == 0)
		row.name = "Options_" + tabs.get_tab_title(i)
		rows.append(row)
		left.add_child(row)
	tabs.tab_changed.connect(func(index):
		for i in range(rows.size()): rows[i].set_pressed_no_signal(i == index))
	rows[0].grab_focus()

func buy_shop(key: String, character: bool, item: bool):
	remember_scroll()
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
	# Hidden developer page: debug builds only (the editor and debug exports).
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F12:
		if page == "dev": show_roster()
		else:
			page = "dev"
			build_menu()
		get_viewport().set_input_as_handled()
		return
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

func build_training_menu(left: VBoxContainer, right: VBoxContainer):
	left.add_child(page_heading("DEFENDER"))
	for key in Data.CHARACTERS:
		var row = list_row(Data.CHARACTERS[key][0], Data.character_icon(key), select_character.bind(key), preview == key)
		row.name = "Train_" + key
		row.add_theme_constant_override("icon_max_width", 32)
		if not save.unlocked.has(key):
			for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]: row.add_theme_color_override("icon_" + state + "_color", Color.BLACK)
		left.add_child(row)
	var owned = save.unlocked.has(preview)
	var hint = page_heading("Upgrades apply only to " + Data.CHARACTERS[preview][0] + "." if owned else "Unlock this defender in the Shop's Defenders tab.")
	right.add_child(hint)
	var grid = VBoxContainer.new()
	grid.name = "UpgradeGrid"
	grid.add_theme_constant_override("separation", 8)
	right.add_child(grid)
	var track = Data.training(save, preview)
	var first: Button
	for key in ["power", "heart", "weapon_slots", "tome_slots"]:
		var rank = track[key]
		var slots = key.ends_with("slots")
		var maximum = 4 if slots else 5
		var cost = 80 * (rank - 1) if slots else 40 + rank * 30
		var title = {"power": "Fighting Spirit", "heart": "A Hardy Hen", "weapon_slots": "Weapon Slots", "tome_slots": "Tome Slots"}[key]
		var card = PanelContainer.new()
		card.add_theme_stylebox_override("panel", UI.paper_style("Popup01a", 10))
		grid.add_child(card)
		var content = HBoxContainer.new()
		content.add_theme_constant_override("separation", 10)
		card.add_child(content)
		var text = VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(text)
		text.add_child(UI.label(title, 16))
		var effect = "%d / 4 unlocked" % rank if slots else "+%d%% damage  /  Rank %d of 5" % [rank * 5, rank] if key == "power" else "+%d max HP  /  Rank %d of 5" % [rank * 10, rank]
		var effect_label = UI.label(effect, 16)
		effect_label.add_theme_color_override("font_color", UI.MUTED)
		text.add_child(effect_label)
		var step = "+1 slot" if slots else "+5% damage" if key == "power" else "+10 HP"
		var buy = UI.button("MAXED" if rank >= maximum else "%s  /  %d g" % [step, cost], purchase.bind(key))
		buy.name = "Buy_" + key
		buy.custom_minimum_size.x = 170
		buy.disabled = not owned or rank >= maximum or save.gold < cost
		UI.paint_button(buy, UI.LEAF)
		content.add_child(buy)
		if first == null and not buy.disabled:
			first = buy
	if first:
		first.grab_focus()

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
	if save.unlocked.has(preview) or not Data.quest_done(save, Data.CHARACTER_QUESTS[preview]) or save.gold < Data.CHARACTER_COSTS[preview]: return
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

func show_quests():
	page = "quests"
	build_menu()

# Quests list on the left; the selected quest's rewards and the build-tool
# ladder on the right.
func build_quests(left: VBoxContainer, right: VBoxContainer):
	left.add_child(page_heading("%d / %d QUESTS COMPLETE" % [Data.quests_completed(save), Data.QUESTS.size()]))
	var scroll = ScrollContainer.new()
	scroll.name = "ListScroll"
	restore_scroll.call_deferred(scroll)
	scroll.custom_minimum_size.y = 344
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	if not Data.QUESTS.has(quest_selected):
		var open = Data.QUESTS.keys().filter(func(id): return not Data.quest_done(save, id))
		quest_selected = open[0] if not open.is_empty() else Data.QUESTS.keys()[0]
	for id in Data.QUESTS:
		var done = Data.quest_done(save, id)
		var row = list_row(Data.QUESTS[id][0], Book.art("IconTick01a") if done else null, select_quest.bind(id), id == quest_selected)
		row.name = "Quest_" + id
		row.add_theme_font_size_override("font_size", 16)
		if done: row.add_theme_color_override("font_color", UI.LEAF)
		list.add_child(row)
	detail_page = right
	build_quest_detail(right)

func build_quest_detail(right: VBoxContainer):
	var id = quest_selected
	var done = Data.quest_done(save, id)
	var title = UI.label(Data.QUESTS[id][0], 16)
	right.add_child(page_heading("QUEST COMPLETE" if done else "IN PROGRESS  /  " + Data.quest_progress(save, id)))
	right.add_child(title)
	right.add_child(page_heading("UNLOCKS IN THE SHOP"))
	var rewards = HFlowContainer.new()
	rewards.add_theme_constant_override("h_separation", 6)
	rewards.add_theme_constant_override("v_separation", 6)
	right.add_child(rewards)
	var found = false
	for group in [[Data.CATALOG.equipment, false, false], [Data.CATALOG.items, true, false], [Data.CATALOG.characters, false, true]]:
		for def in group[0]:
			if def.unlock_quest != id: continue
			found = true
			var chip = PanelContainer.new()
			chip.add_theme_stylebox_override("panel", UI.paper_style("Popup01a", 6))
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			chip.add_child(row)
			row.add_child(UI.portrait(def.key, 24) if group[2] else UI.icon(def.key, group[1], 24))
			var reward = UI.label("%s  %d g" % [def.display_name, def.unlock_gold], 16)
			reward.autowrap_mode = TextServer.AUTOWRAP_OFF
			row.add_child(reward)
			rewards.add_child(chip)
	if not found:
		var note = UI.label("No gear; counts toward build tools.", 16)
		note.autowrap_mode = TextServer.AUTOWRAP_OFF
		rewards.add_child(note)
	var push = Control.new()
	push.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(push)
	right.add_child(page_heading("BUILD TOOLS PER RUN"))
	right.add_child(UI.label("Reroll %d    Skip %d    Banish %d" % [Data.tool_uses(save, "reroll"), Data.tool_uses(save, "skip"), Data.tool_uses(save, "banish")], 16))
	var next = Data.MILESTONES.filter(func(m): return Data.quests_completed(save) < m[0])
	right.add_child(UI.label("Next: +1 %s at %d quests." % [next[0][1].capitalize(), next[0][0]] if not next.is_empty() else "Every build tool earned.", 16))

func select_quest(id: String):
	quest_selected = id
	refresh_selection("Quest_", id, build_quest_detail)

# Highlights the chosen row and redraws only the detail page.
func refresh_selection(prefix: String, key: String, build_detail: Callable):
	if not is_instance_valid(detail_page):
		build_menu()
		return
	for row in menu.find_children(prefix + "*", "Button", true, false):
		row.set_pressed_no_signal(row.name == prefix + key)
	for child in detail_page.get_children():
		detail_page.remove_child(child)
		child.queue_free()
	build_detail.call(detail_page)

func remember_scroll():
	var scroll = menu.find_child("ListScroll", true, false) if is_instance_valid(menu) else null
	list_scroll = scroll.scroll_vertical if scroll else 0

# The new list has no height until containers lay it out, so restore a frame later.
func restore_scroll(scroll: ScrollContainer):
	var offset = list_scroll
	list_scroll = 0
	if offset == 0: return
	# Hide the list for the one frame it would sit at the top.
	scroll.modulate.a = 0.0
	await get_tree().process_frame
	if is_instance_valid(scroll):
		scroll.scroll_vertical = offset
		scroll.modulate.a = 1.0

static func ability_text(key: String) -> Label:
	var def = Data.character_def(key)
	var text = UI.label("SPACE  /  %s (%ds): %s\nPASSIVE  /  %s" % [def.ability_name, def.ability_cooldown, def.ability_description, def.passive_description], 16)
	text.add_theme_color_override("font_color", UI.LEAF)
	return text

const DEV_ACTIONS = [
	["quests", "Complete every quest"],
	["next_quest", "Complete the next quest"],
	["gold", "Add 1,000 gold"],
	["unlock_all", "Unlock all gear and defenders"],
	["training", "Max training for every defender"],
	["levels", "Unlock all levels and difficulties"],
	["reset", "Reset all progress"]
]

func build_dev(left: VBoxContainer, right: VBoxContainer):
	left.add_child(page_heading("DEBUG BUILDS ONLY  /  F12 TO CLOSE"))
	for entry in DEV_ACTIONS:
		var reset = entry[0] == "reset"
		var row = list_row("PRESS AGAIN TO RESET" if reset and reset_armed else entry[1], null, dev_action.bind(entry[0]))
		row.name = "Dev_" + entry[0]
		row.toggle_mode = false
		if reset: UI.paint_button(row, Color("8a3b35"))
		left.add_child(row)
	right.add_child(page_heading("SAVE"))
	var owned_gear = Data.UPGRADES.keys().filter(func(k): return Data.equipment_owned(save, k)).size()
	var owned_items = Data.ITEMS.keys().filter(func(k): return Data.equipment_owned(save, k, true)).size()
	right.add_child(UI.label("Gold %d    Best %d:%02d    Wins %d\nQuests %d / %d    Build tools: reroll %d, skip %d, banish %d\nGear %d / %d    Items %d / %d    Defenders %d / %d" % [save.gold, save.best / 60, save.best % 60, save.wins, Data.quests_completed(save), Data.QUESTS.size(), Data.tool_uses(save, "reroll"), Data.tool_uses(save, "skip"), Data.tool_uses(save, "banish"), owned_gear, Data.UPGRADES.size(), owned_items, Data.ITEMS.size(), save.unlocked.size(), Data.CHARACTERS.size()], 16))
	right.add_child(page_heading("IN-RUN KEYS  (DEBUG BUILDS)"))
	right.add_child(UI.label("F1  Gain a level\nF2  Drop a free chest at your feet\nF3  +100 coins\nF4  Skip to 5 seconds before the next guardian\nF5  Max every weapon and tome you own (rank 10)", 16))

func dev_action(action: String):
	if action == "reset" and not reset_armed:
		reset_armed = true
		build_menu()
		return
	reset_armed = false
	Data.dev_grant(save, action)
	if not save.unlocked.has(preview): preview = save.character
	build_menu()
