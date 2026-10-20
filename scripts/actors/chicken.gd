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
var dash_cooldown = 0.0
var dash_time = 0.0
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

func _physics_process(delta):
	if is_dead:
		return
	invulnerability = maxf(0, invulnerability - delta)
	dash_cooldown = maxf(0, dash_cooldown - delta)
	dash_time = maxf(0, dash_time - delta)
	var mov = Input.get_vector("left", "right", "up", "down")
	if mov.length() > 0.1:
		facing = mov
	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0:
		dash_time = 0.18
		dash_cooldown = run.dash_recharge() if is_instance_valid(run) else 3.0
		invulnerability = 0.3
		if is_instance_valid(run):
			run.on_dash()
	velocity = (facing * 360.0) if dash_time > 0 else mov * movement_speed
	move_and_slide()
	if is_instance_valid(run):
		global_position = global_position.clamp(run.arena_bounds.position, run.arena_bounds.end)
		hp = minf(max_hp, hp + run.regeneration() * delta)
	update_character_animation()
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

func take_damage(amount: float):
	if is_dead or invulnerability > 0:
		return
	var armor = run.armor_value() if is_instance_valid(run) else 0
	hp = maxf(0, hp - maxf(1, amount - armor))
	invulnerability = 0.8
	if is_instance_valid(run):
		run.play_sound("hit")
		run.feedback.kick(2.0)
		run.floating_text(global_position, "-" + str(int(maxf(1, amount - armor))), Color("ff8c87"))
	if hp <= 0:
		is_dead = true
		animated_sprite_2d.play("death")
		run.finish(false)

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
		animated_sprite_2d.sprite_frames = original_frames
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
	animated_sprite_2d.play("Walk" if walking else "idle")
	if absf(facing.x) > 0.1:
		animated_sprite_2d.flip_h = (facing.x < 0) != native_faces_left
	# Align the feet to the same ground point despite different source bounds.
	if character_key == "whisker":
		animated_sprite_2d.position.y = 3 if walking else 5
	elif character_key != "nugget":
		animated_sprite_2d.position.y = 2
