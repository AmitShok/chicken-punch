extends Sprite2D
## Snapshot endpoints survive enemy death; animation never holds enemy references.
var age := 0.0
var delay := 0.0
func _init():
	texture = preload("res://assets/Coop/chain_lightning.png")
	hframes = 6
	centered = false
	offset = Vector2(0, -8)
	z_index = 4
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
func _ready():
	add_to_group("chain_arcs")
func configure(start: Vector2, finish: Vector2, size: float, evolved: bool, hop: int):
	position = start
	rotation = start.angle_to_point(finish)
	scale = Vector2(start.distance_to(finish) / 95.0, size * (1.5 if evolved else 1.0))
	delay = minf(hop * 0.025, 0.15)
	visible = delay == 0
	if evolved: modulate = Color(0.78, 0.9, 1.0)
func _process(delta: float):
	age += delta
	visible = age >= delay
	frame = clampi(int((age - delay) / 0.05), 0, 5)
	if age >= delay + 0.3: queue_free()
