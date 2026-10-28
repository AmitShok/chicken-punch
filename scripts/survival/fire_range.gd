extends Node2D
# A faint fire-coloured ring under each Hot Foot patch showing exactly where it
# burns. Drawn in the patch's local space, so it scales with the patch.

const RADIUS = 17.0
const FILL = Color(1.0, 0.55, 0.22, 0.10)
const EDGE = Color(1.0, 0.62, 0.26, 0.38)

func _ready():
	show_behind_parent = true
	# The flame sprite is drawn from its centre 6px above its base; centre the ring on the patch.
	position = Vector2.ZERO

func _draw():
	draw_circle(Vector2.ZERO, RADIUS, FILL)
	draw_arc(Vector2.ZERO, RADIUS - 0.5, 0, TAU, 32, EDGE, 1.0)
