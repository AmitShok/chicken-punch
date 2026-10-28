extends CharacterBody2D

@export var fireWalk_scene: PackedScene
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var is_dead = false
var movement_speed = 100.0
var hp = 100.0
var max_hp = 100.0
var current_xp = 0
var max_xp = 12
var level = 1
var invulnerability = 0.0
var ability_cooldown = 0.0
# A lunge moves the player at a fixed speed, then calls its landing callback.
var lunge_time = 0.0
var lunge_speed = 360.0
var lunge_direction = Vector2.RIGHT
var lunge_landing: Callable = Callable()
# Procedural animation state: squash eases back to 1, steps drive bob and dust.
var squash = Vector2.ONE
var step_phase = 0.0
var anim_time = 0.0
var hurt_time = 0.0
var was_lunging = false
var dodge_shown = false
var foot_y = 0.0
var hit_material: ShaderMaterial
var facing = Vector2.RIGHT
var run: Node
var character_key = "nugget"
var native_faces_left = false
@onready var original_frames: SpriteFrames = $AnimatedSprite2D.sprite_frames

func _ready():
	collision_layer = 2
	collision_mask = 1
	$Timer.stop()
	$AttackManager.set_process(false)
	$HurtBox.monitoring = false
	$HurtBox.monitorable = false
	$Camera2D.scale = Vector2.ONE
	$Camera2D.zoom = Vector2(2, 2)
	animated_sprite_2d.remove_from_group("player")
	hit_material = ShaderMaterial.new()
	hit_material.shader = preload("res://assets/shaders/hit_flash.gdshader")
	animated_sprite_2d.material = hit_material

func _physics_process(delta):
	if is_dead:
		return
	invulnerability = maxf(0, invulnerability - delta)
	ability_cooldown = maxf(0, ability_cooldown - delta)
	var lunging = lunge_time > 0
	lunge_time = maxf(0, lunge_time - delta)
	if lunging and lunge_time <= 0 and lunge_landing.is_valid():
		var landing = lunge_landing
		lunge_landing = Callable()
		landing.call()
	var mov = Input.get_vector("left", "right", "up", "down")
	if mov.length() > 0.1:
		facing = mov
	if Input.is_action_just_pressed("dash") and ability_cooldown <= 0 and is_instance_valid(run):
		run.abilities.use()
	velocity = (lunge_direction * lunge_speed) if lunge_time > 0 else mov * movement_speed
	move_and_slide()
	if is_instance_valid(run):
		global_position = global_position.clamp(run.arena_bounds.position, run.arena_bounds.end)
		hp = minf(max_hp, hp + run.regeneration() * delta)
	update_character_animation()
	animate(delta)
	animated_sprite_2d.modulate.a = 0.45 if invulnerability > 0 and fmod(invulnerability, 0.15) < 0.075 else 1.0

func gain_xp(amount: int):
	if is_dead:
		return
	current_xp += amount
	while current_xp >= max_xp:
		current_xp -= max_xp
		level += 1
		max_xp = 12 + level * 6
		if is_instance_valid(run):
			run.pending_levels += 1

# Returns true when the hit landed, so attackers can trigger thorns.
func take_damage(amount: float) -> bool:
	if is_dead:
		return false
	if invulnerability > 0:
		# Passing through an enemy mid-dash shows a dodge once per dash.
		if lunge_time > 0 and not dodge_shown and is_instance_valid(run):
			dodge_shown = true
			run.floating_text(global_position, "Dodge!", Color("bfe8ff"))
		return false
	if is_instance_valid(run) and run.rng.randf() < run.dodge_chance():
		invulnerability = 0.4
		run.floating_text(global_position, "Dodge", Color("bfe8ff"))
		return false
	var armor = run.armor_value() if is_instance_valid(run) else 0
	hp = maxf(0, hp - maxf(1, amount - armor))
	invulnerability = 0.8
	hurt_time = 0.3
	squash = Vector2(0.8, 1.2)
	if is_instance_valid(run):
		run.play_sound("hit")
		run.feedback.kick(2.0)
		run.floating_text(global_position, "-" + str(int(maxf(1, amount - armor))), Color("ff8c87"))
	if hp <= 0:
		is_dead = true
		animated_sprite_2d.play("death")
		run.finish(false)
	return true

func _on_hurt_box_hurt(damage, _angle):
	take_damage(damage)

func _on_timer_timeout():
	pass

func _on_animated_sprite_2d_animation_finished():
	pass



func configure_character(key: String):
	var data = preload("res://scripts/survival/data.gd")
	character_key = key if data.CHARACTERS.has(key) else "nugget"
	var path = data.CHARACTERS[character_key][2]
	native_faces_left = data.CHARACTER_VISUALS[character_key].faces_left
	animated_sprite_2d.stop()
	animated_sprite_2d.position = Vector2.ZERO
	animated_sprite_2d.rotation = 0
	animated_sprite_2d.modulate = Color.WHITE
	if path == "":
		# The ChickenPack also has jump and damage sheets: used for the dash and hits.
		var frames: SpriteFrames = original_frames.duplicate()
		add_strip(frames, "jump", load("res://assets/ChickenPack/SpriteSheet/ChickenJumping-Sheet.png"), Vector2(20, 21), 18, false)
		# The pack walk is 4 frames; 10 fps gives a brisk stride at base speed.
		frames.set_animation_speed("Walk", 10)
		animated_sprite_2d.sprite_frames = frames
	else:
		var texture = load(path)
		var cell = Vector2(data.CHARACTER_VISUALS[character_key].cell)
		var frames = SpriteFrames.new()
		frames.remove_animation("default")
		for animation in ["idle", "Walk", "death"]:
			frames.add_animation(animation)
			frames.set_animation_speed(animation, 8 if character_key == "whisker" else 7)
			frames.set_animation_loop(animation, animation != "death")
			var sheet = load("res://assets/Characters/WhiskerWalk.png") if character_key == "whisker" and animation == "Walk" else texture
			var count = int(sheet.get_width() / cell.x) if animation == "Walk" else 1
			for i in range(count):
				var atlas = AtlasTexture.new()
				atlas.atlas = sheet
				atlas.region = Rect2(Vector2(i * cell.x, 0), cell)
				frames.add_frame(animation, atlas)
		animated_sprite_2d.sprite_frames = frames
	animated_sprite_2d.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	update_character_animation()

func update_character_animation():
	var walking = velocity.length() > 1
	var frames = animated_sprite_2d.sprite_frames
	if lunge_time > 0 and frames.has_animation("jump"):
		animated_sprite_2d.play("jump")
	elif hurt_time > 0 and frames.has_animation("takeDamage"):
		animated_sprite_2d.play("takeDamage")
	else:
		animated_sprite_2d.play("Walk" if walking else "idle")
	# Faster movement (Fleet Feet) quickens the stride.
	animated_sprite_2d.speed_scale = clampf(velocity.length() / 100.0, 0.8, 1.8) if animated_sprite_2d.animation == "Walk" else 1.0
	if absf(facing.x) > 0.1:
		animated_sprite_2d.flip_h = (facing.x < 0) != native_faces_left
	# Align the feet to the same ground point despite different source bounds.
	foot_y = (3.0 if walking else 5.0) if character_key == "whisker" else 0.0 if character_key == "nugget" else 2.0
	animated_sprite_2d.position.y = foot_y

func lunge(direction: Vector2, speed: float, time: float, landing: Callable = Callable()):
	lunge_direction = direction.normalized() if direction.length() > 0.01 else facing.normalized()
	lunge_speed = speed
	lunge_time = time
	lunge_landing = landing

static func add_strip(frames: SpriteFrames, animation: String, sheet: Texture2D, cell: Vector2, fps: float, loop: bool):
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, loop)
	for i in range(int(sheet.get_width() / cell.x)):
		var atlas = AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(Vector2(i * cell.x, 0), cell)
		frames.add_frame(animation, atlas)

# Visual-only motion layered on the sprite: walk bob with a squash on every
# footfall, a lean into movement, idle breathing, dash stretch, landing squash
# and a hit flash. Reduced motion (Options > Effects) turns it all off.
func animate(delta: float):
	var sprite = animated_sprite_2d
	hurt_time = maxf(0, hurt_time - delta)
	anim_time += delta
	var motion = not is_instance_valid(run) or run.save.get("combat_feedback", true)
	if hit_material:
		var flash = clampf(hurt_time / 0.12 - 1.5, 0.0, 1.0)
		hit_material.set_shader_parameter("flash_amount", flash)
	if not motion:
		sprite.scale = Vector2.ONE
		sprite.rotation = 0
		return
	var lunging = lunge_time > 0
	squash = squash.lerp(Vector2.ONE, minf(1, delta * 12))
	var shape = Vector2.ONE
	var bob = 0.0
	var lean = 0.0
	if lunging:
		# Stretch along the dash.
		shape = Vector2(1.22, 0.82) if absf(lunge_direction.x) >= absf(lunge_direction.y) else Vector2(0.84, 1.18)
		lean = lunge_direction.x * 0.22
	elif velocity.length() > 1:
		var previous = step_phase
		step_phase += delta * velocity.length() / 6.4
		bob = -absf(sin(step_phase)) * 1.5
		lean = clampf(velocity.x / maxf(movement_speed, 1.0), -1, 1) * 0.08
		# A footfall each time the bob returns to the ground.
		if floori(previous / PI) != floori(step_phase / PI):
			squash = Vector2(1.08, 0.92)
			if is_instance_valid(run): run.feedback.puff(global_position + Vector2(0, 7), -velocity.normalized() * 10, Color("e8d6a6"), 0.28, 0.25)
	else:
		step_phase = 0.0
		var breath = sin(anim_time * 3.0) * 0.025
		shape = Vector2(1.0 - breath * 0.5, 1.0 + breath)
	if was_lunging and not lunging:
		squash = Vector2(1.24, 0.78)
		dodge_shown = false
		if is_instance_valid(run): run.feedback.puff(global_position + Vector2(0, 6), Vector2.ZERO, Color("e8d6a6"), 0.5, 0.3)
	was_lunging = lunging
	sprite.scale = shape * squash
	sprite.rotation = lerp_angle(sprite.rotation, lean, minf(1, delta * 14))
	sprite.position.y = foot_y + bob
