extends Node2D

# Cosmetic state is isolated from combat RNG, timers and collision shapes.
var run: Node
var shake = 0.0
var phase = 0.0
var ghosts = 0
var dash_clock = 0.0

func enabled() -> bool:
	return run.save.get("combat_feedback", true)

func kick(strength: float):
	if enabled(): shake = minf(3.0, maxf(shake, strength))

func _process(delta):
	var camera = run.player.get_node("Camera2D")
	if not enabled() or run.ended:
		shake = 0
	phase += delta * 65
	shake = move_toward(shake, 0, delta * 14)
	camera.offset = Vector2(sin(phase), cos(phase * 1.3)) * shake
	dash_clock -= delta
	if enabled() and not run.ended and run.player.dash_time > 0 and dash_clock <= 0:
		dash_clock = 0.045
		echo(run.player.animated_sprite_2d, Vector2.ZERO, Color("ffe3a0"), 0.18)

func echo(source: AnimatedSprite2D, motion: Vector2, tint: Color, lifetime: float):
	if not enabled() or ghosts >= 24: return
	ghosts += 1
	var ghost = Sprite2D.new()
	ghost.texture = source.sprite_frames.get_frame_texture(source.animation, source.frame)
	ghost.scale = source.global_scale
	ghost.flip_h = source.flip_h
	ghost.modulate = tint
	ghost.z_index = 3
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(ghost)
	ghost.global_position = source.global_position
	var tween = create_tween().set_parallel(true)
	tween.tween_property(ghost, "position", ghost.position + motion, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "scale", ghost.scale * 0.45, lifetime)
	tween.tween_property(ghost, "modulate:a", 0.0, lifetime)
	tween.chain().tween_callback(func():
		ghosts -= 1
		ghost.queue_free())

func defeated(enemy: Node):
	echo(enemy.get_node("Sprite2D"), enemy.knockback_velocity.normalized() * 14 + Vector2(0, -8), Color("ffd9aa"), 0.24)
	if enemy.boss: kick(3.0)
