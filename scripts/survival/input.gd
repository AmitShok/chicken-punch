extends Node

func _ready():
	for entry in [["interact", KEY_E], ["dash", KEY_SPACE], ["pause", KEY_ESCAPE], ["mute", KEY_M], ["left", KEY_LEFT], ["right", KEY_RIGHT], ["up", KEY_UP], ["down", KEY_DOWN]]:
		if not InputMap.has_action(entry[0]):
			InputMap.add_action(entry[0])
		var event = InputEventKey.new()
		event.physical_keycode = entry[1]
		InputMap.action_add_event(entry[0], event)

