extends Control
# On-screen controls for phones, tablets and touchscreen PCs. Interface adds
# this only when touch_device() is true, so mouse-and-keyboard players never see it.
#
# Left side: a floating joystick that appears where your thumb lands and drives
# the same move actions as the keyboard. Right side: the defender's ability.
# Several fingers work at once (move and use the ability together).

const Data = preload("res://scripts/survival/data.gd")
const BASE_RADIUS = 56.0
const KNOB_RADIUS = 22.0
const BUTTON_RADIUS = 46.0
# Thumb zones in the 960x640 viewport. The top strip stays free for the build
# panel and the pause button.
const TOP_MARGIN = 110.0
const STICK_ZONE = 0.55
const PAPER = Color("ffe7c2")
const INK = Color("3e3029")
const RIM = Color("6b4a45")

var run: Node
var ui: CanvasLayer
var stick_finger = -1
var stick_origin = Vector2.ZERO
var stick_vector = Vector2.ZERO
var ability_finger = -1
var resting_origin = Vector2(130, 470)
var button_centre = Vector2(860, 430)

# True on phones and tablets (native or in a mobile browser) and on any device
# that reports a touchscreen.
static func touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(_delta):
	var playing = is_instance_valid(run) and not run.ended and not ui.modal_open and not get_tree().paused
	if not playing and (stick_finger != -1 or ability_finger != -1):
		release_all()
	visible = playing
	queue_redraw()

func _input(event):
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_down(event.index, event.position)
		else:
			touch_up(event.index)
	elif event is InputEventScreenDrag and event.index == stick_finger:
		steer(event.position)
		get_viewport().set_input_as_handled()

func touch_down(finger: int, pos: Vector2):
	if pos.distance_to(button_centre) <= BUTTON_RADIUS + 14 and ability_finger == -1:
		ability_finger = finger
		# Uses the ability directly: a faked key press can fall between physics steps.
		if run.player.ability_cooldown <= 0 and not run.player.is_dead:
			run.abilities.use()
		get_viewport().set_input_as_handled()
	elif stick_finger == -1 and pos.x < size.x * STICK_ZONE and pos.y > TOP_MARGIN and not over_tappable(pos):
		stick_finger = finger
		stick_origin = pos
		steer(pos)
		get_viewport().set_input_as_handled()

func touch_up(finger: int):
	if finger == stick_finger:
		stick_finger = -1
		stick_vector = Vector2.ZERO
		apply_stick()
	if finger == ability_finger:
		ability_finger = -1

# Leaves taps on the chest prompt to the prompt itself.
func over_tappable(pos: Vector2) -> bool:
	return is_instance_valid(ui.chest_plate) and ui.chest_plate.visible and ui.chest_plate.get_global_rect().grow(8).has_point(pos)

func steer(pos: Vector2):
	var offset = pos - stick_origin
	# Past the rim, the base follows the thumb so direction changes stay instant.
	if offset.length() > BASE_RADIUS:
		stick_origin = pos - offset.normalized() * BASE_RADIUS
		offset = pos - stick_origin
	stick_vector = offset / BASE_RADIUS
	if stick_vector.length() < 0.18:
		stick_vector = Vector2.ZERO
	apply_stick()

# Feeds the move actions with analogue strength, exactly like a keyboard or gamepad.
func apply_stick():
	for entry in [["right", stick_vector.x], ["left", -stick_vector.x], ["down", stick_vector.y], ["up", -stick_vector.y]]:
		if entry[1] > 0:
			Input.action_press(entry[0], minf(1.0, entry[1]))
		else:
			Input.action_release(entry[0])

func release_all():
	stick_finger = -1
	ability_finger = -1
	stick_vector = Vector2.ZERO
	apply_stick()

func _draw():
	# The HUD theme (inherited from the HUD root) carries the pixel font.
	var font = get_theme_default_font()
	# Joystick: shown faintly at rest so players know where to put a thumb.
	var active = stick_finger != -1
	var origin = stick_origin if active else resting_origin
	draw_circle(origin, BASE_RADIUS, Color(PAPER, 0.28 if active else 0.16))
	draw_arc(origin, BASE_RADIUS, 0, TAU, 40, Color(RIM, 0.75 if active else 0.4), 3.0)
	var knob = origin + stick_vector * BASE_RADIUS
	draw_circle(knob + Vector2(0, 3), KNOB_RADIUS, Color(RIM, 0.35))
	draw_circle(knob, KNOB_RADIUS, Color(PAPER, 0.92 if active else 0.5))
	draw_arc(knob, KNOB_RADIUS, 0, TAU, 28, Color(RIM, 0.9 if active else 0.5), 3.0)
	# Ability button with a cooldown sweep.
	var player = run.player
	var def = Data.character_def(player.character_key)
	var total = maxf(0.01, run.ability_recharge())
	var ready = player.ability_cooldown <= 0
	var pressed = ability_finger != -1
	var centre = button_centre + (Vector2(0, 3) if pressed else Vector2.ZERO)
	draw_circle(button_centre + Vector2(0, 4), BUTTON_RADIUS, Color(RIM, 0.45))
	draw_circle(centre, BUTTON_RADIUS, Color(PAPER, 0.92) if ready else Color("c9b28c", 0.85))
	if not ready:
		var left = clampf(player.ability_cooldown / total, 0.0, 1.0)
		draw_arc(centre, BUTTON_RADIUS - 7, -PI / 2, -PI / 2 + TAU * (1.0 - left), 40, Color("426344"), 6.0)
	draw_arc(centre, BUTTON_RADIUS, 0, TAU, 40, RIM, 3.0)
	var name_text = def.ability_name.to_upper() if def else "DASH"
	var words = name_text.split(" ")
	for i in range(words.size()):
		var line = words[i]
		var width = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string(font, centre + Vector2(-width / 2.0, 5 + (i - (words.size() - 1) / 2.0) * 16), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)
	if not ready:
		var secs = "%.1f" % player.ability_cooldown
		var width = font.get_string_size(secs, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string(font, centre + Vector2(-width / 2.0, BUTTON_RADIUS + 18), secs, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, PAPER)
