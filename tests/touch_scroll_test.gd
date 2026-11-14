extends SceneTree
# Touch scrolling in menu lists: a drag that starts on a button scrolls the list
# without pressing the button, a flick keeps gliding, and a plain tap still works.
const Data = preload("res://scripts/survival/data.gd")
var failures = 0
var checks = 0
var menu
func _initialize(): call_deferred("test")
func check(ok: bool, title: String):
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ") + title)

# A finger event sent through the engine, which also makes the mouse copy that
# buttons react to, in the same order a phone produces.
func finger(kind: String, pos: Vector2):
	var touch
	if kind == "drag":
		touch = InputEventScreenDrag.new()
	else:
		touch = InputEventScreenTouch.new()
		touch.pressed = kind == "down"
	touch.position = pos
	Input.parse_input_event(touch)
	Input.flush_buffered_events()

func swipe(from: Vector2, to: Vector2, steps: int, step_time: float, lift = true):
	finger("down", from)
	await process_frame
	for i in range(1, steps + 1):
		await create_timer(step_time).timeout
		finger("drag", from.lerp(to, float(i) / steps))
	if lift:
		finger("up", to)
	await process_frame

func list() -> ScrollContainer:
	return menu.find_child("ListScroll", true, false)

func test():
	Data.save_path = "user://coop_touch_scroll_test.cfg"
	Data.write_save({"muted": true})
	# Headless windows start tiny; match the game's size so positions line up.
	root.size = Vector2i(960, 640)
	# The first touch on a device rebuilds the menu for touch; get that out of the way.
	preload("res://scripts/ui/touch_controls.gd").seen_touch = true
	menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	menu.open_page("quests")
	await process_frame
	await process_frame
	var scroll = list()
	check(scroll != null and scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page, "The quest list is long enough to scroll")
	var start_selected = menu.quest_selected
	var rect = scroll.get_global_rect()
	var top = Vector2(rect.get_center().x, rect.position.y + 60)
	# A slow drag that starts on a quest button, then holds still before lifting.
	await swipe(top + Vector2(0, 200), top, 10, 0.05, false)
	await create_timer(0.2).timeout
	finger("up", top)
	await process_frame
	scroll = list()
	check(scroll.scroll_vertical >= 150, "Dragging up over the buttons scrolls the list (now %d)" % scroll.scroll_vertical)
	check(menu.quest_selected == start_selected, "The button under the drag is not pressed")
	var before = scroll.scroll_vertical
	await create_timer(0.3).timeout
	check(list().scroll_vertical == before, "A drag that holds still before lifting does not glide")
	# A quick flick keeps gliding after the finger lifts.
	list().scroll_vertical = 0
	await swipe(top + Vector2(0, 120), top, 4, 0.016)
	var lifted = list().scroll_vertical
	await create_timer(0.4).timeout
	check(list().scroll_vertical > lifted + 30, "A flick keeps gliding (%d -> %d)" % [lifted, list().scroll_vertical])
	# A new touch stops the glide.
	list().scroll_vertical = 0
	await swipe(top + Vector2(0, 120), top, 4, 0.016)
	finger("down", top)
	await process_frame
	var held = list().scroll_vertical
	await create_timer(0.2).timeout
	check(list().scroll_vertical == held, "Touching the list stops a glide")
	finger("up", top)
	await process_frame
	# A plain tap on another quest still selects it.
	await create_timer(0.2).timeout
	list().scroll_vertical = 0
	await process_frame
	var buttons = list().find_children("*", "Button", true, false)
	var target: Button = null
	var skipped = 0
	for b in buttons:
		if b.get_global_rect().get_center().y > list().get_global_rect().position.y + 120 and b.is_visible_in_tree():
			if not menu.quest_selected.is_empty() and b.text.to_lower().contains(menu.quest_selected.replace("_", " ")):
				continue
			target = b
			skipped += 1
			if skipped == 2: break
	var picked = menu.quest_selected
	finger("down", target.get_global_rect().get_center())
	await process_frame
	finger("drag", target.get_global_rect().get_center() + Vector2(0, 4))
	finger("up", target.get_global_rect().get_center() + Vector2(0, 4))
	await process_frame
	await process_frame
	check(menu.quest_selected != picked, "A tap with a little wobble still presses the button")
	# Godot's own drag never scrolls a second time.
	check(list().scroll_deadzone > 10000, "Built-in drag scrolling is off for lists")
	menu.queue_free()
	print("TOUCH SCROLL RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
