extends Control

const ROOT = "res://assets/ui/travel_book/Sprites/UI_TravelBook_"
const DERIVED = "res://assets/ui/travel_book/Derived/UI_TravelBook_"
# Book art is drawn at 2x so its pixels match the 2x world camera.
const PIXEL = 2
static var art_cache: Dictionary = {}
var split = 0.0
# When set, the spine follows this page column instead of the split fraction.
var left_page: Control
var gutter = 0.0
var styles: Dictionary = {}

# Like art(), at a custom pixel scale (the on/off switch reads better at 3x).
static func art_scaled(asset: String, factor: int) -> Texture2D:
	var key = asset + "@" + str(factor)
	if not art_cache.has(key):
		var image: Image = load(ROOT + asset + ".png").get_image()
		image.resize(image.get_width() * factor, image.get_height() * factor, Image.INTERPOLATE_NEAREST)
		art_cache[key] = ImageTexture.create_from_image(image)
	return art_cache[key]

static func art(asset: String) -> Texture2D:
	if not art_cache.has(asset):
		var path = ROOT + asset + ".png"
		if not ResourceLoader.exists(path):
			path = DERIVED + asset + ".png"
		var image: Image = load(path).get_image()
		image.resize(image.get_width() * PIXEL, image.get_height() * PIXEL, Image.INTERPOLATE_NEAREST)
		art_cache[asset] = ImageTexture.create_from_image(image)
	return art_cache[asset]

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw)

func tile(asset: String, rect: Rect2, edge: float):
	if not styles.has(asset):
		var created = StyleBoxTexture.new()
		created.texture = art(asset)
		created.set_texture_margin_all(edge * PIXEL)
		styles[asset] = created
	var style = styles[asset]
	style.draw(get_canvas_item(), rect)

func _draw():
	tile("BookCover01a", Rect2(Vector2.ZERO, size), 12)
	var inner = Rect2(Vector2(16, 14), size - Vector2(32, 30))
	var seam = 0.0
	if is_instance_valid(left_page):
		seam = (get_global_transform().affine_inverse() * left_page.get_global_rect().end).x + gutter / 2.0
	elif split > 0:
		seam = size.x * split
	if seam > 0:
		tile("BookPageLeft01a", Rect2(inner.position, Vector2(seam - inner.position.x, inner.size.y)), 8)
		tile("BookPageRight01a", Rect2(Vector2(seam, inner.position.y), Vector2(inner.end.x - seam, inner.size.y)), 8)
	else:
		tile("BookPageRight01a", inner, 8)
