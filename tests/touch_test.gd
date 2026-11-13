extends SceneTree
# On-screen touch controls: hidden on desktops, joystick moves, the button uses
# the ability, fingers work together, and the chest prompt can be tapped.
const Data = preload("res://scripts/survival/data.gd")
var failures = 0
var checks = 0
# Headless runs have a 64x64 root window, so pushed events would be rescaled;
# events go straight to the controls in viewport coordinates instead.
var pad: Control
func _initialize(): call_deferred("test")
func check(ok: bool, title: String):
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ") + title)
func touch(index: int, pos: Vector2, pressed: bool):
	var event = InputEventScreenTouch.new()
	event.index = index
	event.position = pos
	event.pressed = pressed
	pad._input(event)
func drag(index: int, pos: Vector2):
	var event = InputEventScreenDrag.new()
	event.index = index
	event.position = pos
	pad._input(event)
func test():
	Data.save_path = "user://coop_touch_test.cfg"
	Data.write_save({"muted": true, "character": "nugget"})
	var run = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	await process_frame
	run.spawn_clock = 1.0e9
	run.elite_clock = 1.0e9
	var ui = run.ui
	check(not preload("res://scripts/ui/touch_controls.gd").touch_device() and ui.touch_controls == null, "A desktop without a touchscreen gets no touch controls")
	check(ui.hud_hint.get_parent().visible, "Desktop keeps its keyboard hints")
	# A touch on a device that did not report a touchscreen switches it over at once.
	var first = InputEventScreenTouch.new()
	first.pressed = true
	first.position = Vector2(700, 300)
	root.get_node("SurvivalInput")._input(first)
	await process_frame
	check(ui.touch_controls != null and not ui.hud_hint.get_parent().visible, "The first real touch turns on touch controls")
	check(preload("res://scripts/ui/touch_controls.gd").touch_device(), "Later screens also see a touch device")
	ui.set_touch(true)
	await process_frame
	pad = ui.touch_controls
	check(pad != null and pad.visible, "Touch mode adds the on-screen controls")
	check(not ui.hud_hint.get_parent().visible, "Touch mode hides keyboard hints")
	# Joystick: thumb down on the left, drag right.
	var start = run.player.global_position
	touch(0, Vector2(150, 450), true)
	drag(0, Vector2(150 + 60, 450))
	await process_frame
	check(Input.get_action_strength("right") > 0.9 and Input.get_action_strength("left") == 0.0, "Dragging right presses right at full strength")
	await create_timer(0.4).timeout
	check(run.player.global_position.x > start.x + 20, "The joystick moves the defender")
	drag(0, Vector2(150 - 20, 450 + 30))
	await process_frame
	check(Input.get_action_strength("left") > 0 and Input.get_action_strength("down") > 0 and Input.get_action_strength("right") == 0.0, "The stick is analogue in every direction")
	# Second finger on the ability button while still steering.
	touch(1, pad.button_centre, true)
	await process_frame
	await process_frame
	check(run.player.ability_cooldown > 0, "The ability button uses the defender's ability")
	check(Input.get_action_strength("left") > 0, "Moving and the ability work at the same time")
	touch(1, pad.button_centre, false)
	touch(0, Vector2(130, 480), false)
	await process_frame
	check(["left", "right", "up", "down", "dash"].all(func(a): return not Input.is_action_pressed(a)), "Lifting every finger releases every action")
	# Taps in the top strip or on the right half never grab the stick.
	touch(2, Vector2(100, 60), true)
	touch(3, Vector2(700, 300), true)
	await process_frame
	check(pad.stick_finger == -1, "Taps near the build panel or on the right leave the stick alone")
	touch(2, Vector2(100, 60), false)
	touch(3, Vector2(700, 300), false)
	# The chest prompt is tappable.
	run.dev_key(KEY_F2)
	await process_frame
	await process_frame
	check(ui.chest_plate.visible, "Standing on a chest shows the prompt")
	var rect = ui.chest_plate.get_global_rect()
	var tap = InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	tap.position = rect.get_center()
	ui.chest_plate.gui_input.emit(tap)
	await process_frame
	check(ui.mode == "chest", "Tapping the prompt opens the chest")
	check(not pad.visible, "Controls hide while a menu is open")
	ui.close_modal()
	paused = false
	ui.set_touch(false)
	await process_frame
	check(ui.touch_controls == null and ui.hud_hint.get_parent().visible, "Turning touch off removes the controls and restores hints")
	preload("res://scripts/ui/touch_controls.gd").seen_touch = false
	run.queue_free()
	print("TOUCH RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
