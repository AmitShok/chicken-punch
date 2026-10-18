extends Control
var bearing = 0.0
var target_label = "No pickups"
var target_texture: Texture2D
var active = false
var distance = 0
func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw():
	draw_style_box(preload("res://survival/interface.gd").box_style(Color("49352fe6"),Color("986040"),8),Rect2(64,2,144,74))
	var center = Vector2(38,38)
	draw_circle(center, 33, Color("49352f"))
	draw_circle(center, 30, Color("f4d892"))
	draw_circle(center, 25, Color("fff3cf"))
	for i in range(16):
		var direction = Vector2.RIGHT.rotated(i * TAU / 16)
		draw_line(center + direction * (22 if i % 4 == 0 else 26), center + direction * 29, Color("986040"), 2)
	var font = ThemeDB.fallback_font
	draw_string(font,Vector2(33,16),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("49352f"))
	if active:
		var forward = Vector2.RIGHT.rotated(bearing)
		var side = forward.orthogonal() * 5
		draw_colored_polygon(PackedVector2Array([center+forward*22,center+side,center-side]),Color("bc5545"))
		draw_colored_polygon(PackedVector2Array([center-forward*18,center+side,center-side]),Color("526a75"))
		draw_circle(center,3,Color("986040"))
		if target_texture: draw_texture_rect(target_texture,Rect2(80,8,24,24),false)
	draw_string(font,Vector2(80,49),target_label,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("fff3cf"))
	if active: draw_string(font,Vector2(80,68),str(distance)+"m",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("f4d892"))
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
		target_label = "No pickups"
		target_texture = null
	queue_redraw()
