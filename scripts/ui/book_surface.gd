extends Control

const ROOT = "res://assets/ui/travel_book/Sprites/UI_TravelBook_"
var split = 0.0
var styles: Dictionary = {}

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw)

func tile(asset: String, rect: Rect2, edge: float):
	if not styles.has(asset):
		var created = StyleBoxTexture.new()
		created.texture = load(ROOT + asset + ".png")
		created.set_texture_margin_all(edge)
		styles[asset] = created
	var style = styles[asset]
	style.draw(get_canvas_item(), rect)

func _draw():
	tile("BookCover01a", Rect2(Vector2.ZERO, size), 12)
	var inner = Rect2(Vector2(12, 10), size - Vector2(24, 24))
	if split > 0:
		var seam = size.x * split
		tile("BookPageLeft01a", Rect2(inner.position, Vector2(seam - 16, inner.size.y)), 8)
		tile("BookPageRight01a", Rect2(Vector2(seam + 4, 10), Vector2(size.x - seam - 16, inner.size.y)), 8)
	else:
		tile("BookPageRight01a", inner, 8)
