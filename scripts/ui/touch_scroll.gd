extends Node
# Drag-to-scroll for every ScrollContainer on touchscreens, phone style:
# a finger can start on top of a button, the list follows it, and a flick
# keeps gliding after the finger lifts. Once a touch moves far enough to count
# as a scroll, the button under it is released without being pressed.
# Godot's own drag scrolling is switched off so the two never fight.

# How far (in game pixels) a finger travels before a tap becomes a scroll.
const DRAG_THRESHOLD = 10.0
# How quickly a flick slows down (higher stops sooner).
const FRICTION = 5.0
const MIN_SPEED = 20.0
const MAX_SPEED = 4000.0

var finger = -1
var start_position = Vector2.ZERO
var scroll: ScrollContainer = null
var dragging = false
# The finger moved sideways or off a list, so it is not a scroll.
var ignore = false
var anchor_y = 0.0
var anchor_scroll = 0.0
var velocity = 0.0
var last_y = 0.0
var last_time = 0
# The list that keeps gliding after a flick.
var glide: ScrollContainer = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(on_node_added)

func on_node_added(node: Node):
	if node is ScrollContainer:
		# Godot's own drag would scroll a second time when the touch begins on empty space.
		node.scroll_deadzone = 1000000

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			# A new finger stops a glide; only the first finger can scroll.
			glide = null
			if finger == -1:
				finger = event.index
				start_position = event.position
				dragging = false
				ignore = false
				scroll = null
		elif event.index == finger:
			finger = -1
			if dragging:
				get_viewport().set_input_as_handled()
				var idle = (Time.get_ticks_usec() - last_time) / 1000000.0
				if idle < 0.1 and abs(velocity) > MIN_SPEED and is_instance_valid(scroll):
					glide = scroll
			dragging = false
	elif event is InputEventScreenDrag and event.index == finger and not ignore:
		if not dragging:
			var moved = event.position - start_position
			if abs(moved.y) < DRAG_THRESHOLD or abs(moved.y) < abs(moved.x):
				return
			scroll = scroll_under_finger()
			if scroll == null:
				# Not over a list: leave this touch alone for good.
				ignore = true
				return
			dragging = true
			anchor_y = event.position.y
			anchor_scroll = scroll.scroll_vertical
			velocity = 0.0
			last_y = event.position.y
			last_time = Time.get_ticks_usec()
			release_pressed_button.call_deferred()
		if not is_instance_valid(scroll):
			dragging = false
			return
		scroll.scroll_vertical = int(round(anchor_scroll - (event.position.y - anchor_y)))
		var now = Time.get_ticks_usec()
		var dt = max((now - last_time) / 1000000.0, 0.001)
		var speed = clamp(-(event.position.y - last_y) / dt, -MAX_SPEED, MAX_SPEED)
		velocity = lerp(velocity, speed, 0.6)
		last_y = event.position.y
		last_time = now
		get_viewport().set_input_as_handled()
	elif event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION and dragging and not event.has_meta("touch_scroll"):
		# The mouse copies of a scrolling touch must not hover or press anything.
		get_viewport().set_input_as_handled()

func _process(delta):
	if glide == null:
		return
	if not is_instance_valid(glide) or not glide.is_visible_in_tree():
		glide = null
		return
	var before = glide.scroll_vertical
	glide.scroll_vertical = int(round(before + velocity * delta))
	velocity *= exp(-FRICTION * delta)
	# Stop at the ends of the list or once it has slowed right down.
	if abs(velocity) < MIN_SPEED or glide.scroll_vertical == before:
		glide = null

# The list the finger is on: the control under it, or any of its parents.
func scroll_under_finger() -> ScrollContainer:
	var node = get_viewport().gui_get_hovered_control()
	while node != null:
		if node is ScrollContainer and node.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			var bar = node.get_v_scroll_bar()
			if bar and bar.max_value > bar.page:
				return node
		node = node.get_parent() as Control
	return null

# The touch first landed as a press on a button; slide it off screen and lift it
# there so the button resets without firing. Buttons judge a release by where
# the pointer last moved, so the move has to come first.
func release_pressed_button():
	var away = InputEventMouseMotion.new()
	away.button_mask = MOUSE_BUTTON_MASK_LEFT
	away.position = Vector2(-10000, -10000)
	away.global_position = away.position
	away.device = InputEvent.DEVICE_ID_EMULATION
	away.set_meta("touch_scroll", true)
	get_viewport().push_input(away)
	var up = InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = Vector2(-10000, -10000)
	up.global_position = up.position
	up.device = InputEvent.DEVICE_ID_EMULATION
	up.set_meta("touch_scroll", true)
	get_viewport().push_input(up)
