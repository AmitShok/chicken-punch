extends Sprite2D
## The bottom of the sky bolt stays anchored to the struck enemy's hit position.
const SHEET = preload("res://assets/Coop/storm_strike.png")
const FRAME_ENDS = [0.045, 0.09, 0.145, 0.2, 0.27, 0.35]
var age := 0.0

func _init():
	texture = SHEET
	hframes = 6
	centered = false
	offset = Vector2(-16, -350)
	z_index = 4
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _ready():
	add_to_group("sky_strikes")

func configure(size: float, evolved: bool):
	# Width follows tome upgrades; height must always reach above the playfield.
	scale.x = size * (1.5 if evolved else 1.0)
	if evolved:
		modulate = Color(0.78, 0.9, 1.0)

func _process(delta: float):
	age += delta
	while frame < 5 and age >= FRAME_ENDS[frame]:
		frame += 1
	if age >= FRAME_ENDS[5]:
		queue_free()
