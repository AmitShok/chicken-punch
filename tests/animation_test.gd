extends SceneTree
const Data = preload("res://survival/data.gd")
var failures = 0
var checks = 0
func _initialize():
	call_deferred("test")
func check(value: bool, title: String):
	checks += 1
	if not value:
		failures += 1
	print(("PASS: " if value else "FAIL: ") + title)
func test():
	Data.save_path = "user://coop_animation_test.cfg"
	for key in Data.CHARACTERS:
		Data.write_save({"character": key, "muted": true})
		var run = load("res://world.tscn").instantiate()
		root.add_child(run)
		current_scene = run
		run.set_physics_process(false)
		var player = run.player
		var sprite = player.animated_sprite_2d
		var frames = sprite.sprite_frames
		var valid = true
		for animation in frames.get_animation_names():
			for i in frames.get_frame_count(animation):
				var atlas = frames.get_frame_texture(animation, i)
				valid = valid and Rect2(Vector2.ZERO, atlas.atlas.get_size()).encloses(atlas.region)
		check(valid, key + " frames stay within sheet boundaries")
		check(Data.character_icon(key).get_size() == Vector2(Data.CHARACTER_VISUALS[key].cell), key + " portrait uses complete frame")
		var start = player.position
		Input.action_press("right")
		var seen = {}
		for i in range(8):
			await create_timer(0.08).timeout
			seen[sprite.frame] = true
		check(player.position.x > start.x + 30 and sprite.animation == "Walk", key + " moves and plays Walk")
		check(seen.size() > 1, key + " walk animation actually advances")
		check(sprite.flip_h == Data.CHARACTER_VISUALS[key].faces_left, key + " faces right when moving right")
		Input.action_release("right")
		Input.action_press("left")
		start = player.position
		await create_timer(0.25).timeout
		check(player.position.x < start.x and sprite.flip_h != Data.CHARACTER_VISUALS[key].faces_left, key + " faces left when moving left")
		Input.action_release("left")
		await create_timer(0.1).timeout
		check(sprite.animation == "idle", key + " returns to idle after stopping")
		if key == "clover":
			check(frames.get_frame_texture("Walk", 1).region == Rect2(24,0,24,16), "Clover second frame is whole and correctly aligned")
		if key == "whisker":
			check(frames.get_frame_count("Walk") == 4, "Whisker uses four dedicated walk frames")
		run.queue_free()
		await process_frame
	print("ANIMATION RESULT: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
