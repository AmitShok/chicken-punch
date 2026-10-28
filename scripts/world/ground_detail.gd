extends Node2D
# Purely visual ground decoration: grass tufts, flowers, bushes, twigs and small
# vegetable patches scattered over the field tiles. Nothing here collides, so
# movement and spawning are unchanged. Everything draws in one canvas item.

const TILES = "res://assets/Ninja Adventure - Asset Pack/Backgrounds/Tilesets/"
const NATURE = preload(TILES + "TilesetNature.png")
const DETAIL = preload(TILES + "TilesetFloorDetail.png")
const FLOOR = preload(TILES + "TilesetFloor.png")
const FIELD_SOURCE = 0
const CELL = 16

# Source rectangles, picked from labelled grids of the pack's tilesets.
const TUFTS = [[DETAIL, Rect2(0, 32, 16, 16)], [DETAIL, Rect2(16, 32, 16, 16)], [DETAIL, Rect2(32, 32, 16, 16)], [DETAIL, Rect2(48, 32, 16, 16)], [DETAIL, Rect2(64, 32, 16, 16)], [DETAIL, Rect2(80, 32, 16, 16)], [DETAIL, Rect2(96, 32, 16, 16)], [DETAIL, Rect2(112, 32, 16, 16)]]
const BUSHES = [[NATURE, Rect2(0, 160, 16, 16)], [NATURE, Rect2(16, 160, 16, 16)], [NATURE, Rect2(32, 160, 16, 16)], [NATURE, Rect2(48, 160, 16, 16)], [NATURE, Rect2(64, 160, 16, 16)], [NATURE, Rect2(96, 160, 16, 16)], [NATURE, Rect2(128, 160, 16, 16)], [NATURE, Rect2(64, 176, 16, 16)], [NATURE, Rect2(80, 176, 16, 16)], [NATURE, Rect2(144, 176, 16, 16)]]
const FLOWERS = [[NATURE, Rect2(0, 176, 16, 16)], [NATURE, Rect2(16, 176, 16, 16)], [NATURE, Rect2(32, 176, 16, 16)]]
const LITTER = [[DETAIL, Rect2(0, 0, 16, 16)], [DETAIL, Rect2(16, 0, 16, 16)], [DETAIL, Rect2(48, 0, 16, 16)], [DETAIL, Rect2(64, 0, 16, 16)], [DETAIL, Rect2(80, 0, 16, 16)], [DETAIL, Rect2(96, 0, 16, 16)], [DETAIL, Rect2(112, 0, 16, 16)], [NATURE, Rect2(192, 176, 16, 16)]]
const PATCH = [FLOOR, Rect2(0, 112, 48, 48)]
const CROPS = [[DETAIL, Rect2(176, 0, 16, 16)], [DETAIL, Rect2(192, 0, 16, 16)]]

var pieces: Array = []

static func decorate(ground: TileMapLayer, avoid: Array, seed_text: String) -> Node2D:
	var detail = new()
	detail.name = "GroundDetail"
	detail.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# As the ground's child it draws above the tiles and below every actor.
	ground.add_child(detail)
	detail.build(ground, avoid, seed_text)
	return detail

func build(ground: TileMapLayer, avoid: Array, seed_text: String):
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(seed_text)
	var overlay: Array[TileMapLayer] = []
	for child in ground.get_children():
		if child is TileMapLayer: overlay.append(child)
	var kinds: Dictionary = {}
	for cell in ground.get_used_cells():
		if ground.get_cell_source_id(cell) != FIELD_SOURCE: continue
		if overlay.any(func(layer): return layer.get_cell_source_id(cell) != -1): continue
		var centre = ground.map_to_local(cell)
		if avoid.any(func(spot): return centre.distance_to(spot) < 40): continue
		kinds[cell] = ground_kind(ground, cell)
	var cells = kinds.keys()
	cells.sort()
	for cell in cells:
		var kind = kinds[cell]
		var centre = ground.map_to_local(cell)
		# Cells where the ground changes get extra cover to soften the stepped edges.
		var edge = false
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if ground.get_cell_atlas_coords(cell + step) != ground.get_cell_atlas_coords(cell):
				edge = true
		var roll = rng.randf()
		var jitter = Vector2(rng.randf_range(-6, 6), rng.randf_range(-6, 6))
		if kind == "grass":
			if edge and roll < 0.55:
				add(BUSHES if rng.randf() < 0.45 else TUFTS, centre + jitter, rng)
			elif roll < 0.08:
				add(TUFTS, centre + jitter, rng)
			elif roll < 0.10:
				add(FLOWERS, centre + jitter, rng)
			elif roll < 0.11:
				add(BUSHES, centre + jitter, rng)
		elif kind == "sand":
			if edge and roll < 0.35:
				add(TUFTS, centre + jitter, rng)
			elif roll < 0.06:
				add(LITTER, centre + jitter, rng)
	place_gardens(kinds, ground, rng)
	pieces.sort_custom(func(a, b): return depth(a) < depth(b))
	queue_redraw()

# A few tilled vegetable patches with pumpkins and carrots, on open grass only.
func place_gardens(kinds: Dictionary, ground: TileMapLayer, rng: RandomNumberGenerator):
	var open: Array = kinds.keys().filter(func(cell):
		for y in range(-2, 3):
			for x in range(-2, 3):
				if kinds.get(cell + Vector2i(x, y), "") != "grass": return false
		return true)
	var planted: Array = []
	for attempt in range(60):
		if planted.size() >= 4 or open.is_empty(): break
		var cell = open[rng.randi_range(0, open.size() - 1)]
		var centre = ground.map_to_local(cell)
		if planted.any(func(spot): return spot.distance_to(centre) < 260): continue
		planted.append(centre)
		# Clear scattered cover from the patch, then lay soil and crops.
		pieces = pieces.filter(func(piece): return piece[2].distance_to(centre) > 30)
		# Soil sorts ahead of its crops so the back row stays visible.
		pieces.append([PATCH[0], PATCH[1], centre, centre.y - 40])
		# Crops sit in a tidy 2x2 bed; one spot is sometimes left fallow.
		var crop = CROPS[rng.randi_range(0, CROPS.size() - 1)]
		for spot in [Vector2(-10, -9), Vector2(10, -9), Vector2(-10, 9), Vector2(10, 9)]:
			if rng.randf() < 0.2: continue
			pieces.append([crop[0], crop[1], centre + spot])

func add(options: Array, pos: Vector2, rng: RandomNumberGenerator):
	var choice = options[rng.randi_range(0, options.size() - 1)]
	pieces.append([choice[0], choice[1], pos.round()])

static var kind_cache: Dictionary = {}

# Classifies a field tile by its average colour: green grass, orange sand.
static func ground_kind(ground: TileMapLayer, cell: Vector2i) -> String:
	var atlas = ground.get_cell_atlas_coords(cell)
	if kind_cache.has(atlas): return kind_cache[atlas]
	var source: TileSetAtlasSource = ground.tile_set.get_source(FIELD_SOURCE)
	var region = source.get_tile_texture_region(atlas)
	var image = source.texture.get_image()
	var total = Color(0, 0, 0, 0)
	for y in range(region.position.y, region.end.y, 2):
		for x in range(region.position.x, region.end.x, 2):
			total += image.get_pixel(x, y)
	var kind = "grass" if total.g >= total.r else "sand"
	kind_cache[atlas] = kind
	return kind

func _draw():
	for piece in pieces:
		var region: Rect2 = piece[1]
		draw_texture_rect_region(piece[0], Rect2(piece[2] - region.size / 2.0, region.size), region)

static func depth(piece: Array) -> float:
	return piece[3] if piece.size() > 3 else piece[2].y
