extends SceneTree
const Data = preload("res://scripts/survival/data.gd")
func _initialize():
	call_deferred("capture")
func label_at(text: String, pos: Vector2, size: int):
	var label = Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	root.add_child(label)
func capture():
	var background = ColorRect.new()
	background.color = Color("151c2b")
	background.size = Vector2(960,640)
	root.add_child(background)
	label_at("CHARACTER ANIMATION CHECK", Vector2(30,20), 26)
	var columns = [210,330,450,570,690,830]
	var titles = ["Idle", "Walk 1", "Walk 2", "Walk 3", "Walk 4", "Facing left"]
	for i in range(6):
		label_at(titles[i], Vector2(columns[i]-35,70), 16)
	var row = 0
	for key in Data.CHARACTERS:
		var player = load("res://scenes/actors/chicken.tscn").instantiate()
		root.add_child(player)
		player.set_physics_process(false)
		player.get_node("Camera2D").enabled = false
		player.configure_character(key)
		player.hide()
		label_at(Data.CHARACTERS[key][0],Vector2(30,125+row*95),20)
		for i in range(6):
			player.velocity = Vector2.ZERO if i == 0 else Vector2.RIGHT * 100
			player.facing = Vector2.LEFT if i == 5 else Vector2.RIGHT
			player.update_character_animation()
			var source = player.animated_sprite_2d
			var sprite = Sprite2D.new()
			var count = source.sprite_frames.get_frame_count(source.animation)
			sprite.texture = source.sprite_frames.get_frame_texture(source.animation, maxi(0,i-1) % count)
			sprite.flip_h = source.flip_h
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.scale = Vector2(3,3)
			sprite.position = Vector2(columns[i],135+row*95)+source.position*3
			root.add_child(sprite)
		player.queue_free()
		row += 1
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0]+"/character-animation-check.png")
	quit()
