extends Node2D

# Cosmetic state is isolated from combat RNG, timers and collision shapes.
var run: Node
var shake = 0.0
var phase = 0.0
var ghosts = 0
var dash_clock = 0.0
const SMOKE = preload("res://assets/Ninja Adventure - Asset Pack/FX/Smoke/Smoke/SpriteSheet.png")
var particles: Array = []
var launch_clocks: Dictionary = {}

func enabled() -> bool:
	return run.save.get("combat_feedback", true)

func kick(strength: float):
	if enabled(): shake = minf(3.0, maxf(shake, strength))

func _process(delta):
	update_particles(delta)
	for key in launch_clocks.keys():
		launch_clocks[key] -= delta
		if launch_clocks[key] <= 0: launch_clocks.erase(key)
	var camera = run.player.get_node("Camera2D")
	if not enabled() or run.ended:
		shake = 0
	phase += delta * 65
	shake = move_toward(shake, 0, delta * 14)
	camera.offset = Vector2(sin(phase), cos(phase * 1.3)) * shake
	dash_clock -= delta
	if enabled() and not run.ended and run.player.dash_time > 0 and dash_clock <= 0:
		dash_clock = 0.045
		echo(run.player.animated_sprite_2d, run.player.velocity * 0.025, Color("ffe3a0"), 0.18)
		puff(run.player.global_position, run.player.velocity * 0.12, Color("e4d7ab"), 0.34, 0.22)

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
	echo(enemy.get_node("Sprite2D"), enemy.last_impact_direction * 14 + Vector2(0, -8), Color("ffd9aa"), 0.24)
	if enemy.boss: kick(3.0)

func launch(pos: Vector2, direction: Vector2, source: String):
	# One cue per player volley; hostile cues retain a separate reserved budget.
	var key = source + str(Vector2i(pos / 8)) if source == "hostile" else source
	if launch_clocks.get(key, 0.0) > 0: return
	launch_clocks[key] = 0.07 if source == "hostile" else 0.10
	var colors = {"egg": Color("fff1cc"), "frost": Color("a5e7ff"), "shell": Color("ffbd78"), "sickle": Color("c6ddac"), "hostile": Color("ff836c")}
	puff(pos - direction * 3, -direction * 28, colors.get(source, Color("e8d6a6")), 0.42, 0.22, source == "hostile")

func impact(pos: Vector2, direction: Vector2):
	puff(pos, direction * 55, Color("ffe5aa"), 0.48, 0.24)

func puff(pos: Vector2, velocity: Vector2, tint: Color, size: float, lifetime: float, priority: bool = false):
	if not enabled() or particles.size() >= (48 if priority else 36): return
	var sprite = Sprite2D.new()
	sprite.texture = SMOKE
	sprite.hframes = 6
	sprite.scale = Vector2.ONE * size
	sprite.modulate = tint
	sprite.modulate.a = 0.65
	sprite.z_index = 0
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	sprite.global_position = pos.round()
	particles.append({"sprite": sprite, "pos": pos, "velocity": velocity, "age": 0.0, "life": lifetime})

func update_particles(delta: float):
	for i in range(particles.size() - 1, -1, -1):
		var particle = particles[i]
		particle.age += delta
		if particle.age >= particle.life or not enabled() or run.ended:
			particle.sprite.queue_free()
			particles.remove_at(i)
			continue
		particle.pos += particle.velocity * delta
		particle.velocity = particle.velocity.move_toward(Vector2.ZERO, 100 * delta)
		particle.sprite.global_position = particle.pos.round()
		particle.sprite.frame = mini(5, int(particle.age / particle.life * 6))
		particle.sprite.modulate.a = 0.65 * (1.0 - particle.age / particle.life)
