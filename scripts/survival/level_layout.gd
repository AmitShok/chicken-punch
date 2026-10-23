extends RefCounted
const NATURE = preload("res://assets/Ninja Adventure - Asset Pack/Backgrounds/Tilesets/TilesetNature.png")

static func apply(run: Node2D, level: String):
	if level == "meadow": return
	var ground: TileMapLayer = run.get_node("Ground layer")
	# Reuse the original map's most common, walkable ground tile.
	var counts = {}
	var cells = {}
	for cell in ground.get_used_cells():
		var tile = ground.get_cell_tile_data(cell)
		if tile == null or tile.get_collision_polygons_count(0) > 0: continue
		var key = str(ground.get_cell_source_id(cell)) + ":" + str(ground.get_cell_atlas_coords(cell))
		counts[key] = counts.get(key, 0) + 1
		cells[key] = cell
	var common = ""
	for key in counts:
		if common == "" or counts[key] > counts[common]: common = key
	if common == "": return
	var source = ground.get_cell_source_id(cells[common])
	var atlas = ground.get_cell_atlas_coords(cells[common])
	ground.clear()
	for child in ground.get_children():
		if child is TileMapLayer: child.clear()
	for y in range(-28, 43):
		for x in range(-37, 56): ground.set_cell(Vector2i(x,y), source, atlas)
	var scenery = Node2D.new()
	scenery.name = "LevelScenery"
	run.add_child(scenery)
	if level == "orchard":
		for y in range(-320, 601, 112):
			for x in range(-480, 801, 128):
				var pos = Vector2(x,y)
				if pos.distance_to(run.player.position) < 85: continue
				prop(scenery, pos, Rect2(0,0,32,32), 9)
	else:
		for ring in [180, 340, 500]:
			for i in range(18):
				# Gaps in each ring preserve routes between the clearings.
				if i % 6 < 2: continue
				var pos = Vector2(70,80) + Vector2.RIGHT.rotated(i * TAU / 18) * ring
				prop(scenery, pos, Rect2(240,224,32,32), 10)

static func prop(parent: Node2D, pos: Vector2, region: Rect2, radius: float):
	var body = StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var sprite = Sprite2D.new()
	var atlas = AtlasTexture.new()
	atlas.atlas = NATURE
	atlas.region = region
	sprite.texture = atlas
	sprite.position.y = -10
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.add_child(sprite)
	var collider = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = radius
	collider.shape = circle
	body.add_child(collider)
