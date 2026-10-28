extends SceneTree
# Options toggles: the lit switch means ON, the label agrees, and the setting takes effect.
const Data = preload("res://scripts/survival/data.gd")
const Book = preload("res://scripts/ui/book_surface.gd")
var failures = 0
var checks = 0
func _initialize(): call_deferred("test")
func check(ok: bool, title: String):
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ") + title)
func test():
	Data.save_path = "user://coop_settings_test.cfg"
	Data.write_save({"muted": false, "combat_feedback": true})
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu._on_option_button_pressed()
	await process_frame
	var mute: CheckButton = menu.menu.find_child("MuteToggle", true, false)
	var motion: CheckButton = menu.menu.find_child("MotionToggle", true, false)
	check(mute.get_theme_icon("checked") == Book.art_scaled("Toggle03b", 3) and mute.get_theme_icon("unchecked") == Book.art_scaled("Toggle03a", 3), "The lit switch is used for ON and the dark switch for OFF")
	check(not mute.button_pressed and mute.text.ends_with("OFF") and not AudioServer.is_bus_mute(0), "Mute starts OFF, unlit, and sound plays")
	mute.button_pressed = true
	check(mute.text.ends_with("ON") and AudioServer.is_bus_mute(0) and Data.read_save().muted, "Turning mute ON lights the switch, silences audio and saves")
	mute.button_pressed = false
	check(mute.text.ends_with("OFF") and not AudioServer.is_bus_mute(0) and not Data.read_save().muted, "Turning mute OFF restores sound and saves")
	check(motion.button_pressed and motion.text.ends_with("ON"), "Combat motion effects start ON")
	motion.button_pressed = false
	check(motion.text.ends_with("OFF") and Data.read_save().combat_feedback == false, "Turning motion effects OFF saves reduced motion")
	menu.queue_free()
	print("SETTINGS RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
