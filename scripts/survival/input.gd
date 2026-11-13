extends Node

const TouchControls = preload("res://scripts/ui/touch_controls.gd")

func _ready():
	# The game is English-only. Without this, a phone set to a right-to-left
	# language (Hebrew, Arabic) mirrors every menu and the whole HUD, and even
	# controls placed before they join the scene take mirrored positions.
	TranslationServer.set_locale("en")
	get_tree().root.set_layout_direction(Window.LAYOUT_DIRECTION_LTR)
	for entry in [["interact", KEY_E], ["dash", KEY_SPACE], ["pause", KEY_ESCAPE], ["mute", KEY_M], ["left", KEY_LEFT], ["right", KEY_RIGHT], ["up", KEY_UP], ["down", KEY_DOWN]]:
		if not InputMap.has_action(entry[0]):
			InputMap.add_action(entry[0])
		var event = InputEventKey.new()
		event.physical_keycode = entry[1]
		InputMap.action_add_event(entry[0], event)


# The first real touch switches every screen to touch controls, in case the
# device did not report a touchscreen when the game started.
func _input(event):
	if event is InputEventScreenTouch and event.pressed and not TouchControls.seen_touch:
		TouchControls.seen_touch = true
		get_tree().call_group("touch_listeners", "on_touch_detected")
