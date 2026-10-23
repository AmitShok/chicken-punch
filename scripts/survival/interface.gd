extends CanvasLayer

const Data = preload("res://scripts/survival/data.gd")
const GOLD = Color("98601f")
const PAPER = Color("fff1cc")
const INK = Color("3e3029")
const LEAF = Color("426344")
const YOLK = Color("f5c957")
const MUTED = Color("6a634a")
const Inspection = preload("res://scripts/survival/inspection.gd")
var chest_prompt: Label
var chest_cost_label: Label
var inspect_title: Label
var inspect_body: Label
var inspect_icon: TextureRect
var inspect_scroll: ScrollContainer
var run: Node
var root: Control
var hud: Label
var health: ProgressBar
var xp: ProgressBar
var loadout: Label
var compass: Control
var banner: Label
var banner_time = 0.0
var modal: Control
var modal_open = false
var mode = ""
var inventory_box: VBoxContainer
var inventory_panel: PanelContainer
var timer_label: Label
var health_text: Label
var level_text: Label
var boss_bar: ProgressBar
var boss_label: Label
var hud_refresh = 0.0
var compact_hud = false
var hud_hint: Label
var clock_icon: TextureRect
var coin_icon: TextureRect
var pause_button: Button


static func box_style(color: Color = Color("fff1cc"), border: Color = Color("896346"), margin: int = 12) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.shadow_color = Color(0.18, 0.12, 0.07, 0.3)
	box.shadow_size = 2
	box.shadow_offset = Vector2(0, 3)
	box.set_content_margin_all(margin)
	return box

static func paper_style(asset: String = "Popup01a", margin: int = 10, tint: Color = Color.WHITE) -> StyleBoxTexture:
	var style = StyleBoxTexture.new()
	style.texture = load("res://assets/ui/travel_book/Sprites/UI_TravelBook_" + asset + ".png")
	style.set_texture_margin_all(5)
	style.set_content_margin_all(margin)
	style.modulate_color = tint
	return style

static func book_frame(frame: PanelContainer, split: float = 0.0):
	var padding = StyleBoxEmpty.new()
	padding.set_content_margin_all(28)
	frame.add_theme_stylebox_override("panel", padding)
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var surface = preload("res://scripts/ui/book_surface.gd").new()
	surface.split = split
	# Top-level layout offsets keep decoration outside the container's content padding.
	frame.add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	surface.set_meta("book_decoration", true)
	frame.resized.connect(func():
		surface.position = Vector2.ZERO
		surface.size = frame.size)
	frame.sort_children.connect(func():
		surface.position = Vector2.ZERO
		surface.size = frame.size)

static func skin() -> Theme:
	var theme = Theme.new()
	theme.default_font = ThemeDB.fallback_font
	theme.default_font_size = 17
	for type in ["Label", "Button", "OptionButton", "TooltipLabel", "PopupMenu", "TabContainer"]:
		theme.set_color("font_color", type, INK)
	for type in ["Button", "OptionButton"]:
		for state in ["font_hover_color", "font_pressed_color", "font_focus_color"]:
			theme.set_color(state, type, INK)
	theme.set_color("font_disabled_color", "Button", Color("81795d"))
	for type in ["Button", "OptionButton"]:
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			var color = Color("f9dfa4") if state == "normal" else Color("ffe9b2") if state == "hover" else Color("edcb81") if state == "pressed" else Color("e2d7b7")
			var style = box_style(color, Color("a8804e"), 8)
			if state == "focus":
				style.bg_color = Color.TRANSPARENT
				style.border_color = Color("b96332")
				style.set_border_width_all(3)
				style.shadow_size = 0
			theme.set_stylebox(state, type, style if state == "focus" else paper_style("FrameSelect01a", 8, Color.WHITE if state == "normal" else Color(1.08, 1.08, 1.08) if state == "hover" else Color("d7bc91") if state == "disabled" else Color("e0bb8b")))
	theme.set_stylebox("panel", "PanelContainer", paper_style())
	theme.set_stylebox("panel", "TooltipPanel", box_style(PAPER, GOLD))
	theme.set_font_size("font_size", "TooltipLabel", 16)
	theme.set_stylebox("panel", "PopupMenu", box_style(PAPER, GOLD))
	theme.set_stylebox("hover", "PopupMenu", box_style(Color("f5d781"), GOLD, 4))
	theme.set_color("font_hover_color", "PopupMenu", INK)
	theme.set_stylebox("panel", "TabContainer", paper_style("Popup01a", 10))
	for state in ["tab_selected", "tab_unselected", "tab_hovered"]:
		theme.set_stylebox(state, "TabContainer", paper_style("FrameSelect01a", 9, Color("a9c99a") if state == "tab_selected" else Color.WHITE))
	theme.set_color("font_selected_color", "TabContainer", INK)
	theme.set_color("font_unselected_color", "TabContainer", INK)
	theme.set_color("font_hovered_color", "TabContainer", INK)
	return theme

static func paint_button(item: Button, color: Color, text_color: Color = PAPER):
	for state in ["normal", "hover", "pressed"]:
		item.add_theme_stylebox_override(state, paper_style("FrameSelect01a", 8, color.lightened(0.2) if state == "hover" else color.darkened(0.12) if state == "pressed" else color))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		item.add_theme_color_override(state, text_color)

static func symbol(kind: String, size: int = 24) -> TextureRect:
	var paths = {"coin": "Items/Treasure/Coin2.png", "gold": "Items/Resource/BarGold.png", "clock": "Items/Object/Hourglass.png", "trophy": "Items/Treasure/GoldCup.png"}
	var item = TextureRect.new()
	var texture = load("res://assets/Characters/Trophy.png" if kind == "trophy" else Data.PACK + paths[kind])
	if kind == "coin" and texture.get_width() > 16:
		var atlas = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(0,0,10,10)
		item.texture = atlas
	else:
		item.texture = texture
	item.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.custom_minimum_size = Vector2(size,size)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item

static func stat_chip(kind: String, value: String, tip: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.tooltip_text = tip
	row.add_child(symbol(kind))
	var text = label(value, 16)
	text.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(text)
	return row

static func portrait(key: String, size: int = 48) -> TextureRect:
	var item = TextureRect.new()
	item.texture = Data.character_icon(key)
	item.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.custom_minimum_size = Vector2(size, size)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item

static func label(text: String, size: int = 16) -> Label:
	var item = Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size", maxi(14, size))
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return item

static func button(text: String, action: Callable) -> Button:
	var item = Button.new()
	item.text = text
	item.pressed.connect(action)
	item.custom_minimum_size.y = 38
	return item

static func icon(key: String, is_item: bool = false, size: int = 40) -> TextureRect:
	var item = TextureRect.new()
	item.texture = Data.icon(key, is_item)
	item.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.custom_minimum_size = Vector2(size, size)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = skin()
	add_child(root)
	timer_label = overlay("00:00", Vector2(380, 10), Vector2(200, 42), 32)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_icon = symbol("clock", 24)
	clock_icon.position = Vector2(405, 20)
	root.add_child(clock_icon)
	hud = overlay("", Vector2(850, 16), Vector2(90, 30), 16)
	coin_icon = symbol("coin", 24)
	coin_icon.position = Vector2(820, 18)
	root.add_child(coin_icon)
	hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	pause_button = button("Esc / Build", show_pause)
	pause_button.position = Vector2(812, 52)
	pause_button.size = Vector2(134, 36)
	root.add_child(pause_button)
	inventory_panel = PanelContainer.new()
	inventory_panel.position = Vector2(14, 65)
	inventory_panel.custom_minimum_size = Vector2(202, 0)
	inventory_panel.add_theme_stylebox_override("panel", paper_style("Popup01a", 10))
	root.add_child(inventory_panel)
	inventory_box = VBoxContainer.new()
	inventory_box.add_theme_constant_override("separation", 6)
	inventory_panel.add_child(inventory_box)
	refresh_inventory()
	health_text = overlay("", Vector2(390, 568), Vector2(180, 20), 14)
	health_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health = progress(Vector2(390, 590), Vector2(180, 8), Color("e76a76"), true)
	xp = progress(Vector2(14, 620), Vector2(932, 8), Color("75aeff"))
	level_text = overlay("", Vector2(14, 590), Vector2(270, 26), 15)
	loadout = overlay("", Vector2(330, 595), Vector2(300, 22), 14)
	loadout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	compass = preload("res://scripts/survival/compass.gd").new()
	compass.position = Vector2(740, 550)
	compass.size = Vector2(210, 80)
	root.add_child(compass)
	boss_bar = progress(Vector2(330, 86), Vector2(300, 8), Color("bb83f3"))
	boss_label = overlay("", Vector2(320, 58), Vector2(320, 22), 15)
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner = overlay("", Vector2(235, 128), Vector2(490, 76), 18)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chest_prompt = overlay("", Vector2(300, 500), Vector2(360, 32), 17)
	chest_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chest_cost_label = overlay("", Vector2(690, 18), Vector2(125, 24), 14)
	hud_hint = overlay("Tab: compact", Vector2(14, 556), Vector2(190, 24), 14)

func overlay(text: String, pos: Vector2, dimensions: Vector2, size: int) -> Label:
	var item = label(text, size)
	item.position = pos
	item.size = dimensions
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_color_override("font_color", Color("fff7df"))
	item.add_theme_color_override("font_outline_color", Color("382c25"))
	item.add_theme_constant_override("outline_size", 4)
	root.add_child(item)
	return item

func progress(pos: Vector2, dimensions: Vector2, color: Color, damage_feedback: bool = false) -> ProgressBar:
	var bar = preload("res://scripts/ui/damage_bar.gd").new() if damage_feedback else ProgressBar.new()
	bar.position = pos
	bar.size = dimensions
	bar.show_percentage = false
	bar.add_theme_font_size_override("font_size", 1)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("fill", bar_style(color))
	bar.add_theme_stylebox_override("background", bar_style(Color("263146")))
	root.add_child(bar)
	bar.set_deferred("size", dimensions)
	return bar

func build_icon(key: String, is_item: bool = false, size: int = 40) -> TextureRect:
	var result = icon(key, is_item, size)
	result.texture = Data.icon(key, is_item, not is_item and run.evolved.has(key))
	return result

func refresh_inventory():
	if not is_instance_valid(inventory_box):
		return
	for child in inventory_box.get_children():
		inventory_box.remove_child(child)
		child.queue_free()
	if compact_hud:
		compact_inventory()
	else:
		inventory_contents(inventory_box, false)

func compact_inventory():
	for group in [0, 1, 2]:
		var grid = GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 3)
		grid.add_theme_constant_override("v_separation", 3)
		inventory_box.add_child(grid)
		var keys = run.items.keys() if group == 2 else run.ranks.keys().filter(func(key): return (key in Data.WEAPONS) == (group == 0))
		for key in keys:
			var badge = PanelContainer.new()
			badge.add_theme_stylebox_override("panel", box_style(Color("fff7df"), GOLD if run.evolved.has(key) else Color("ba9f69"), 2))
			badge.add_child(build_icon(key, group == 2, 20))
			var info = Data.ITEMS[key] if group == 2 else Data.UPGRADES[key]
			badge.tooltip_text = info[0] + (" x" + str(run.items[key]) if group == 2 else " / Rank " + str(run.ranks[key])) + "\n" + info[1]
			grid.add_child(badge)

func apply_hud_layout():
	inventory_panel.custom_minimum_size.x = 125 if compact_hud else 202
	inventory_panel.size = Vector2.ZERO
	refresh_inventory()
	inventory_panel.set_deferred("size", Vector2.ZERO)
	timer_label.add_theme_font_size_override("font_size", 22 if compact_hud else 32)
	clock_icon.position = Vector2(420 if compact_hud else 405, 17 if compact_hud else 20)
	hud.add_theme_font_size_override("font_size", 14 if compact_hud else 16)
	health.size = Vector2(140 if compact_hud else 180, 8)
	health.position.x = 410 if compact_hud else 390
	hud_hint.text = "Tab: expand" if compact_hud else "Tab: compact"
	pause_button.text = "Esc" if compact_hud else "Esc / Build"
	pause_button.add_theme_font_size_override("font_size", 14 if compact_hud else 17)
	pause_button.custom_minimum_size = Vector2(48, 32) if compact_hud else Vector2(134, 38)
	pause_button.size = pause_button.custom_minimum_size
	pause_button.position.x = 898 if compact_hud else 812

func inventory_contents(parent: VBoxContainer, detailed: bool):
	for weapons in [true, false]:
		var title = label(("WEAPONS" if weapons else "TOMES") + "  %d / %d" % [run.owned_count(weapons), Data.slot_limit(run.save, weapons)], 14)
		title.add_theme_color_override("font_color", MUTED)
		parent.add_child(title)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		parent.add_child(row)
		var count = 0
		for key in run.ranks:
			if run.ranks[key] <= 0 or (key in Data.WEAPONS) != weapons:
				continue
			row.add_child(slot(key, false))
			count += 1
		for i in range(maxi(0, Data.slot_limit(run.save, weapons) - count)):
			var empty = PanelContainer.new()
			empty.custom_minimum_size = Vector2(40, 46)
			empty.add_theme_stylebox_override("panel", box_style(Color("e4d5ab"), Color("c4ac79"), 2))
			row.add_child(empty)
	var title = label("ITEMS  /  %d" % run.items.size(), 14)
	title.add_theme_color_override("font_color", MUTED)
	parent.add_child(title)
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	parent.add_child(grid)
	for key in run.items:
		grid.add_child(slot(key, true))
	if run.items.is_empty():
		var hint = label("Find chests to collect\nstackable items.", 14)
		hint.add_theme_color_override("font_color", MUTED)
		parent.add_child(hint)
	if detailed:
		parent.add_child(label("Hover for details.", 14))

func slot(key: String, is_item: bool) -> PanelContainer:
	var frame = PanelContainer.new()
	var color = Data.RARITY_COLORS[Data.ITEMS[key][3]] if is_item else GOLD if run.evolved.has(key) else Color("a88d5e")
	frame.add_theme_stylebox_override("panel", box_style(Color("fff7df"), color, 2))
	frame.custom_minimum_size = Vector2(40, 46)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	frame.add_child(column)
	column.add_child(build_icon(key, is_item, 28))
	var rank = label(("x" if is_item else "Lv ") + str(run.items[key] if is_item else run.ranks[key]), 14)
	rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(rank)
	var info = Data.ITEMS[key] if is_item else Data.UPGRADES[key]
	frame.tooltip_text = info[0] + "\n" + info[1]
	if not is_item and Data.EVOLUTIONS.has(key):
		var recipe = Data.EVOLUTIONS[key]
		frame.tooltip_text += "\nEvolution: rank 10 + " + Data.UPGRADES[recipe[0]][0] + " + chest\n" + Data.EVOLUTION_EFFECTS[key]
	return frame

func _process(delta):
	if not is_instance_valid(run.player):
		return
	var p = run.player
	timer_label.text = "%02d:%02d" % [int(run.elapsed) / 60, int(run.elapsed) % 60]
	hud.text = str(run.coins)
	chest_cost_label.text = "Chest: %d" % run.chest_price()
	chest_cost_label.visible = not compact_hud
	var nearby_chest = run.nearest_chest(30)
	chest_prompt.visible = nearby_chest != null and not modal_open
	if nearby_chest != null:
		var cost = 0 if nearby_chest.chest_free else run.chest_price()
		chest_prompt.text = "E / Open  / FREE" if cost == 0 else "E / Open  / %d coins" % cost if run.coins >= cost else "%d coins needed  /  Have %d" % [cost,run.coins]
	hud.tooltip_text = "%d kills" % run.kills
	health.motion_enabled = run.save.get("combat_feedback", true)
	health.max_value = p.max_hp
	health.value = p.hp
	health_text.text = "%d / %d HP" % [p.hp, p.max_hp]
	xp.max_value = p.max_xp
	xp.value = p.current_xp
	level_text.text = "Lv %d" % p.level if compact_hud else "Lv %d  /  %d kills" % [p.level, run.kills]
	loadout.text = "Space" if p.dash_cooldown <= 0 else "Dash %.1fs" % p.dash_cooldown
	inventory_panel.visible = not modal_open
	hud_refresh -= delta
	if hud_refresh <= 0:
		hud_refresh = 0.25
		update_objectives()
	if not get_tree().paused:
		banner_time -= delta
	banner.visible = banner_time > 0 and not modal_open

func update_objectives():
	var guardian = null
	for enemy in run.enemies:
		if is_instance_valid(enemy) and not enemy.dead and enemy.boss:
			guardian = enemy
			break
	boss_bar.visible = guardian != null
	boss_label.visible = guardian != null
	if guardian != null:
		boss_bar.max_value = guardian.max_hp
		boss_bar.value = guardian.hp
		boss_label.text = "GUARDIAN  /  %d HP" % guardian.hp
	var nearest = null
	var distance = INF
	for pickup in get_tree().get_nodes_in_group("run_pickups"):
		if not is_instance_valid(pickup) or pickup.is_queued_for_deletion() or pickup.opened or pickup.kind not in ["chest", "magnet"]: continue
		var d = run.player.global_position.distance_squared_to(pickup.global_position)
		if d < distance:
			nearest = pickup
			distance = d
	compass.track(nearest, run.player.global_position)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_TAB or event.physical_keycode == KEY_TAB) and not modal_open:
		compact_hud = not compact_hud
		apply_hud_layout()
		update_objectives()
		get_viewport().set_input_as_handled()

func _unhandled_input(event):
	if event.is_action_pressed("interact") and not event.is_echo():
		run.try_open_chest()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("mute"):
		run.save.muted = not run.save.muted
		AudioServer.set_bus_mute(0, run.save.muted)
		Data.write_save(run.save)
	if event.is_action_pressed("pause") and not run.ended:
		if mode == "pause":
			close_modal()
			get_tree().paused = false
		elif not modal_open:
			show_pause()
	if mode == "upgrade" and event is InputEventKey and event.pressed and not event.echo:
		var index = event.physical_keycode - KEY_1
		if index >= 0 and index < run.offers.size():
			run.choose_upgrade(run.offers[index])

func announce(title: String, subtitle: String):
	banner.text = title + "\n" + subtitle
	banner_time = 4

func panel(title: String, subtitle: String) -> VBoxContainer:
	close_modal()
	modal_open = true
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)
	var shade = ColorRect.new()
	shade.color = Color(0.12, 0.17, 0.10, 0.86)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var frame = PanelContainer.new()
	frame.custom_minimum_size = Vector2(928, 0)
	book_frame(frame)
	center.add_child(frame)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	frame.add_child(box)
	var heading_row = HBoxContainer.new()
	heading_row.add_theme_constant_override("separation", 12)
	box.add_child(heading_row)
	heading_row.add_child(portrait(run.save.get("character", "nugget") if Data.CHARACTERS.has(run.save.get("character", "nugget")) else "nugget", 38))
	var heading = label(title, 28)
	heading.add_theme_color_override("font_color", LEAF)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(heading)
	var hint = label(subtitle, 15)
	hint.add_theme_color_override("font_color", MUTED)
	box.add_child(hint)
	return box

func show_choices():
	var is_item = run.offer_kind == "item"
	var box = panel("COOP TREASURE" if is_item else "LEVEL UP!  /  FRESH PICKINGS", "Choose an item to keep for this run." if is_item else "Choose one. Time is paused.")
	mode = "upgrade"
	var body = HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	box.add_child(body)
	var sidebar = VBoxContainer.new()
	sidebar.custom_minimum_size = Vector2(182, 0)
	sidebar.add_theme_constant_override("separation", 6)
	body.add_child(sidebar)
	inventory_contents(sidebar, true)
	var first: Button
	for i in range(run.offers.size()):
		var key = run.offers[i]
		var fallback = key in ["feast", "gold"]
		var rarity = run.offer_rarities.get(key, 0)
		var tint = Data.RARITY_COLORS[rarity]
		var card_frame = PanelContainer.new()
		card_frame.custom_minimum_size = Vector2(226, 0)
		card_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_frame.add_theme_stylebox_override("panel", paper_style("Popup01a", 12, [Color.WHITE, Color("c9efbf"), Color("e4c9ef")][rarity]))
		body.add_child(card_frame)
		var card = VBoxContainer.new()
		card.add_theme_constant_override("separation", 8)
		card_frame.add_child(card)
		var tier = label(Data.RARITIES[rarity], 14)
		tier.add_theme_color_override("font_color", tint)
		card.add_child(tier)
		if not fallback:
			card.add_child(build_icon(key, is_item, 52))
		var info = ["Field Rations" if key == "feast" else "Coin Pouch", "Heal 30 health." if key == "feast" else "Gain 15 coins."] if fallback else Data.ITEMS[key] if is_item else Data.UPGRADES[key]
		var title = label(info[0], 21)
		title.custom_minimum_size.y = 28
		card.add_child(title)
		if not is_item and Data.EVOLUTIONS.has(key):
			card_frame.tooltip_text = "EVOLUTION: " + Data.UPGRADES[Data.EVOLUTIONS[key][0]][0] + " tome + weapon rank 10 + chest\n" + Data.EVOLUTION_EFFECTS[key]
		var rank = run.items.get(key, 0) if is_item else run.ranks.get(key, 0)
		var category = "ITEM" if is_item else "WEAPON" if key in Data.WEAPONS else "TOME"
		var sub = "%s  /  STACK %d > %d" % [category, rank, rank + 1] if is_item else "%s  /  LV %d > %d" % [category, rank, run.offered_rank(key)]
		if rank == 0 and not fallback:
			sub = "NEW " + category
		card.add_child(label("BONUS" if fallback else sub, 14))
		var desc = label(info[1], 15)
		desc.custom_minimum_size.y = 96
		card.add_child(desc)
		var preview = label("Stacks up to 3 times." if is_item else "" if fallback else run.upgrade_preview(key), 15)
		preview.add_theme_color_override("font_color", Color("356343"))
		preview.custom_minimum_size.y = 58
		card.add_child(preview)
		var pick = button("%d  /  TAKE" % [i + 1], run.choose_upgrade.bind(key))
		paint_button(pick, LEAF)
		card.add_child(pick)
		if i == 0:
			first = pick
		if not is_item:
			var banish_button = button("Banish", run.banish.bind(key))
			banish_button.custom_minimum_size.y = 30
			banish_button.add_theme_font_size_override("font_size", 14)
			banish_button.disabled = run.banishes <= 0 or fallback
			card.add_child(banish_button)
	var actions = HBoxContainer.new()
	box.add_child(actions)
	var reroll_button = button("REROLL  /  %d LEFT" % run.rerolls, run.reroll)
	reroll_button.disabled = run.rerolls <= 0
	reroll_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(reroll_button)
	if not is_item:
		var skip_button = button("SKIP  /  %d LEFT" % run.skips, run.skip_offer)
		skip_button.disabled = run.skips <= 0
		skip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(skip_button)
	box.add_child(label("1 / 2 / 3 to select.  " + ("Treasure items do not use weapon or tome slots." if is_item else "Rare = +2 ranks. Epic = +3 ranks. Capped at rank 10. Banishes left: %d" % run.banishes), 14))
	if first:
		first.grab_focus()

static func scroll_page(tabs: TabContainer, title: String) -> VBoxContainer:
	var scroll = ScrollContainer.new()
	scroll.name = title
	tabs.add_child(scroll)
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)
	return box

func show_pause():
	if modal_open or run.ended:
		return
	var box = panel("THE FIELD JOURNAL", "Paused")
	mode = "pause"
	var tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(890, 380)
	box.add_child(tabs)
	add_loadout_page(tabs)
	var stats = scroll_page(tabs, "Stats")
	stats.add_child(label("Damage x%.2f    Critical %d%%    Armor %d    Regen %.1f/s\nPickup radius %d    Dash %.2fs    Duration x%.2f" % [run.power(), run.critical_chance() * 100, run.armor_value(), run.regeneration(), run.pickup_radius(), run.dash_recharge(), run.duration_multiplier()], 18))
	stats.add_child(label("DAMAGE DEALT  /  Actual damage, excluding overkill", 15))
	add_damage_rows(stats)
	add_options_pages(tabs, run.save, func():
		AudioServer.set_bus_mute(0, run.save.muted)
		run.apply_audio_settings())
	var row = HBoxContainer.new()
	box.add_child(row)
	var resume = button("RESUME", func():
		close_modal()
		get_tree().paused = false)
	paint_button(resume, LEAF)
	resume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(resume)
	row.add_child(button("End run & collect gold", func(): run.finish(false)))
	resume.grab_focus()
	get_tree().paused = true

func add_damage_rows(parent: VBoxContainer):
	var keys = run.damage_totals.keys()
	keys.sort_custom(func(a, b): return run.damage_totals[a] > run.damage_totals[b])
	if keys.is_empty():
		parent.add_child(label("No damage dealt yet.", 16))
	for key in keys:
		var name = Data.UPGRADES[key][0] if Data.UPGRADES.has(key) else {"powder": "Blast Powder", "steam": "Steam Engine", "cluster": "Cluster Nest", "wake": "Iron Wake"}.get(key, key)
		if run.evolved.has(key):
			name = Data.EVOLUTIONS[key][1]
		parent.add_child(label("%s     %s damage" % [name, int(run.damage_totals[key])], 17))

func show_result(won: bool):
	var box = panel("DAWN BELONGS TO YOU" if won else "THE FLOCK REMEMBERS", "Gold saved to your Coop  /  Unspent coins expire")
	mode = "result"
	box.add_child(label("%02d:%02d survived     LEVEL %d     %d KILLS     +%d GOLD" % [int(run.elapsed) / 60, int(run.elapsed) % 60, run.player.level, run.kills, run.gold_earned], 22))
	var tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(890, 285)
	box.add_child(tabs)
	var stats = scroll_page(tabs, "Weapon damage")
	add_damage_rows(stats)
	var retry = button("ONE MORE NIGHT", func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	paint_button(retry, LEAF)
	box.add_child(retry)
	box.add_child(button("Return to the Coop  /  %d gold" % run.save.gold, func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")))
	retry.grab_focus()

func close_modal():
	if is_instance_valid(modal):
		root.remove_child(modal)
		modal.queue_free()
	modal = null
	modal_open = false
	mode = ""

static func bar_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	return style

func show_evolution(key: String):
	var recipe = Data.EVOLUTIONS[key]
	var box = panel("WEAPON EVOLVED", "A new form, for the rest of this run.")
	mode = "evolution"
	run.play_sound("evolution")
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	box.add_child(row)
	row.add_child(build_icon(key, false, 96))
	var explanation = VBoxContainer.new()
	explanation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(explanation)
	explanation.add_child(label(Data.UPGRADES[key][0] + "  >  " + recipe[1], 28))
	var effect_text = label(Data.EVOLUTION_EFFECTS[key], 22)
	effect_text.add_theme_color_override("font_color", LEAF)
	explanation.add_child(effect_text)
	box.add_child(label("Recipe completed: " + Data.UPGRADES[key][0] + " rank 10 + " + Data.UPGRADES[recipe[0]][0] + " rank 1+ + a chest.", 17))
	box.add_child(label("This chest granted the evolution instead of a treasure item. Your weapon keeps its slot and all your damage bonuses.", 16))
	var continue_button = button("UNLEASH " + recipe[1].to_upper(), func():
		close_modal()
		get_tree().paused = false)
	paint_button(continue_button, LEAF)
	box.add_child(continue_button)
	continue_button.grab_focus()

func add_loadout_page(tabs: TabContainer):
	var page = HBoxContainer.new()
	page.name = "Loadout"
	page.add_theme_constant_override("separation", 16)
	tabs.add_child(page)
	var list_scroll = ScrollContainer.new()
	list_scroll.custom_minimum_size.x = 240
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(list_scroll)
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.add_child(list)
	inspect_scroll = ScrollContainer.new()
	inspect_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspect_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(inspect_scroll)
	var details = VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 12)
	inspect_scroll.add_child(details)
	var heading = HBoxContainer.new()
	details.add_child(heading)
	inspect_icon = build_icon(run.ranks.keys()[0], false, 48)
	heading.add_child(inspect_icon)
	inspect_title = label("", 23)
	inspect_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(inspect_title)
	inspect_body = label("", 16)
	details.add_child(inspect_body)
	for group in [0,1,2]:
		list.add_child(label(["WEAPONS", "TOMES", "ITEMS"][group], 14))
		var keys = run.items.keys() if group == 2 else run.ranks.keys().filter(func(key): return (key in Data.WEAPONS) == (group == 0))
		if keys.is_empty():
			list.add_child(label("None collected", 14))
		for key in keys:
			var is_item = group == 2
			var info = Data.ITEMS[key] if is_item else Data.UPGRADES[key]
			var entry = button(info[0] + (" x%d" % run.items[key] if is_item else " %d" % run.ranks[key]), inspect_equipment.bind(key,is_item))
			entry.add_theme_font_size_override("font_size",14)
			entry.icon = Data.icon(key,is_item,not is_item and run.evolved.has(key))
			entry.expand_icon = true
			entry.add_theme_constant_override("icon_max_width",24)
			entry.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			entry.alignment = HORIZONTAL_ALIGNMENT_LEFT
			list.add_child(entry)
	inspect_equipment(run.ranks.keys()[0],false)

func inspect_equipment(key: String, item: bool):
	inspect_icon.texture = Data.icon(key,item,not item and run.evolved.has(key))
	inspect_title.text = Data.ITEMS[key][0] if item else Data.EVOLUTIONS[key][1] if run.evolved.has(key) else Data.UPGRADES[key][0]
	inspect_body.text = Inspection.describe(run,key,item)
	inspect_scroll.scroll_vertical = 0

func show_ascension(key: String):
	var rule = Data.ASCENSIONS[key]
	var box = panel("ASCENSION!", "The flock has become the catastrophe.")
	mode = "ascension"
	run.play_sound("evolution")
	var art = HBoxContainer.new()
	art.add_theme_constant_override("separation",24)
	box.add_child(art)
	art.add_child(build_icon(rule[1],false,80))
	art.add_child(build_icon(rule[2],false,80))
	art.add_child(build_icon(rule[5],true,80))
	box.add_child(label(rule[0],32))
	box.add_child(label(rule[6],22))
	box.add_child(label("Active for the rest of this run. This chest granted your Ascension instead of a treasure item.",16))
	var unleash = button("UNLEASH",func():
		close_modal()
		get_tree().paused = false)
	paint_button(unleash,LEAF)
	box.add_child(unleash)
	unleash.grab_focus()

func show_chest_reward():
	var key = run.offers[0]
	var salvage = key == "gold"
	var rarity = run.offer_rarities.get(key,0)
	var box = panel("CHEST OPENED", run.last_chest_note)
	mode = "chest"
	var reward = PanelContainer.new()
	reward.add_theme_stylebox_override("panel",box_style([Color("fff8df"),Color("e1f0d9"),Color("f0dff2")][rarity],Data.RARITY_COLORS[rarity],18))
	box.add_child(reward)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation",24)
	reward.add_child(row)
	row.add_child(symbol("coin",80) if salvage else icon(key,true,80))
	var details = VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)
	details.add_child(label("COLLECTION COMPLETE" if salvage else Data.RARITIES[rarity],15))
	details.add_child(label("Coin salvage" if salvage else Data.ITEMS[key][0],28))
	details.add_child(label("All items are maxed. Receive %d coins." % maxi(15,run.last_chest_paid) if salvage else Data.ITEMS[key][1],18))
	if not salvage:
		details.add_child(label("Level %d > %d / 10" % [run.items.get(key,0),run.items.get(key,0)+1],17))
	var take = button("TAKE & CONTINUE",run.choose_upgrade.bind(key))
	paint_button(take,LEAF)
	box.add_child(take)
	box.add_child(label("Next paid chest: %d coins. Free openings do not raise the price." % run.chest_price(),14))
	take.grab_focus()

static func add_options_pages(tabs: TabContainer, settings: Dictionary, apply_audio: Callable):
	var audio_page = scroll_page(tabs, "Audio")
	for entry in [["Music", "music_volume"], ["Sound effects", "sfx_volume"]]:
		var caption = label("%s  /  %d%%" % [entry[0], settings[entry[1]] * 100], 18)
		audio_page.add_child(caption)
		var slider = HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.value = settings[entry[1]] * 100
		slider.custom_minimum_size = Vector2(500, 34)
		slider.value_changed.connect(func(value):
			settings[entry[1]] = value / 100.0
			caption.text = "%s  /  %d%%" % [entry[0], value]
			apply_audio.call()
			Data.write_save(settings))
		audio_page.add_child(slider)
	var mute = CheckButton.new()
	mute.text = "Mute all sound"
	mute.button_pressed = settings.muted
	mute.toggled.connect(func(enabled):
		settings.muted = enabled
		apply_audio.call()
		Data.write_save(settings))
	audio_page.add_child(mute)
	var controls = scroll_page(tabs, "Controls")
	controls.add_child(label("WASD / Arrow keys: move\nE: open nearby chest (costs coins; elite chests are free)\nSpace: dash\n1 / 2 / 3: choose an upgrade\nEscape: pause / resume\nTab: compact / full HUD\nM: mute sound\n\nWeapon and tome slots are committed for the run. Items are separate.\nMax a weapon and own its matching tome, then collect a chest to evolve.\nSurvive to 10:00, then defeat the final guardian.", 18))
	var credits = scroll_page(tabs, "Credits")
	credits.add_child(label("CHICKENPUNCH", 24))
	credits.add_child(label("Pixel art", 19))
	credits.add_child(label("ChickenPack\nNinja Adventure / Pixel-boy & AAA", 18))
	credits.add_child(label("Travel Book Lite / Crusenho Agus Hennihuno\ncrusenho.itch.io/complete-ui-book-styles-pack\nUI sprites resized with nine-slicing and tinted in-engine; original art unchanged.", 16))
	credits.add_child(label("Additional pixel art created in Aseprite.", 16))

	var effects_page = scroll_page(tabs, "Effects")
	var feedback_toggle = CheckButton.new()
	feedback_toggle.text = "Combat motion effects"
	feedback_toggle.button_pressed = settings.get("combat_feedback", true)
	feedback_toggle.toggled.connect(func(value):
		settings.combat_feedback = value
		Data.write_save(settings))
	effects_page.add_child(feedback_toggle)
	effects_page.add_child(label("Camera impacts, directional puffs, dash trails, recoil and health-bar trails. Disable for reduced motion.", 16))
