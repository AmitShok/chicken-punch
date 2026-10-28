extends Control
const UI = preload("res://scripts/survival/interface.gd")
const INK = Color("3e3029")
const RIM = Color("6b4a45")
var bearing = 0.0
var target_label = "No treasure"
var target_texture: Texture2D
var active = false
var distance = 0
var plate: StyleBox
func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	plate = UI.paper_style("Popup01a", 0)
func _draw():
	draw_style_box(plate, Rect2(50, 4, size.x - 50, size.y - 8))
	var center = Vector2(38, size.y / 2.0)
	# A chunky pixel dial: dark rim, parchment face, notches every quarter.
	draw_circle(center, 36, RIM)
	draw_circle(center, 32, Color("e6c491"))
	draw_circle(center, 28, Color("ffe7c2"))
	for i in range(8):
		var direction = Vector2.RIGHT.rotated(i * TAU / 8)
		var tip = (center + direction * 28).round()
		draw_rect(Rect2(tip - Vector2(2, 2), Vector2(4, 4)) if i % 2 == 0 else Rect2(tip - Vector2(1, 1), Vector2(2, 2)), RIM)
	var font = UI.pixel_font()
	draw_string(font, center + Vector2(-3, -15), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)
	if active:
		var forward = Vector2.RIGHT.rotated(bearing)
		var side = forward.orthogonal() * 5
		draw_colored_polygon(PackedVector2Array([center + forward * 24, center + side, center - side]), Color("c4483f"))
		draw_colored_polygon(PackedVector2Array([center - forward * 18, center + side, center - side]), Color("5d6f7a"))
		draw_rect(Rect2(center - Vector2(3, 3), Vector2(6, 6)), RIM)
		if target_texture: draw_texture_rect(target_texture, Rect2(86, 14, 24, 24), false)
	var text_x = 116 if active and target_texture else 86
	draw_string(font, Vector2(text_x, 32), target_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)
	if active: draw_string(font, Vector2(86, 58), str(distance) + "m away", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("6a634a"))
func track(pickup: Node, origin: Vector2):
	active = is_instance_valid(pickup)
	if active:
		var offset = pickup.global_position - origin
		bearing = offset.angle()
		distance = int(offset.length() / 16)
		target_label = {"chest":"Free chest" if pickup.chest_free else "Chest","magnet":"Magnet","heal":"Health","gold":"Coins","xp":"Experience"}.get(pickup.kind,"Pickup")
		var sprite = pickup.get_node("Sprite")
		var atlas = AtlasTexture.new()
		atlas.atlas = sprite.texture
		atlas.region = Rect2(0,0,sprite.texture.get_width()/sprite.hframes,sprite.texture.get_height())
		target_texture = atlas
	else:
		target_label = "No treasure"
		target_texture = null
	queue_redraw()
