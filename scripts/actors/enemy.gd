extends CharacterBody2D

@export var movement_speed = 28.0
@export var hp = 10.0
@export var bone_scene: PackedScene
@export var knockback_friction = 0.1
var run: Node
var kind = "dog"
var elite = false
var boss = false
var final_guardian = false
var dead = false
var max_hp = 10.0
var damage = 10.0
var base_hp = 10.0
var base_damage = 10.0
var scaling_clock = 0.0
var radius = 9.0
var knockback_velocity = Vector2.ZERO
var age = 0.0
var attack_clock = 2.0
var windup = 0.0
var attack_target = Vector2.ZERO
var flash = 0.0
var slow_time = 0.0
var steam_lock = 0.0
var slow_factor = 1.0

func _ready():
	collision_layer = 4
	collision_mask = 1
	$HurtBox.monitoring = false
	$HurtBox.monitorable = false
	$HitBox.monitoring = false
	$HitBox.monitorable = false
	$HitBox.collision_layer = 0
	$Sprite2D.scale = Vector2.ONE

func configure(director: Node, type: String, champion: bool = false):
	run = director
	kind = type
	elite = champion
	var path = "Actor/Animals/Dog/SpriteSheet.png"
	var frame_size = Vector2(16, 16)
	match kind:
		"bat":
			path = "Actor/Monsters/BlueBat/SpriteSheet.png"
			movement_speed = 58
			hp = 9
		"tank":
			path = "Actor/Monsters/Bear/SpriteSheet.png"
			movement_speed = 22
			hp = 60
			damage = 16
		"caster":
			path = "Actor/Monsters/LanternRed/SpriteSheet.png"
			movement_speed = 24
			hp = 25
		"boss":
			path = "Actor/Boss/GiantSlime/Idle.png"
			frame_size = Vector2(62, 52)
			boss = true
			final_guardian = run.boss_stage == 3
			movement_speed = 22
			hp = 600 + run.elapsed * 3
			damage = 24
			radius = 18
	var tex = load("res://assets/Ninja Adventure - Asset Pack/" + path)
	var frames = SpriteFrames.new()
	for i in range(mini(2, int(tex.get_width() / frame_size.x))):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(Vector2(i * frame_size.x, 0), frame_size)
		frames.add_frame("default", atlas)
	$Sprite2D.sprite_frames = frames
	$Sprite2D.play("default")
	hp *= run.difficulty
	if elite and not boss:
		hp *= 5
		movement_speed *= 1.12
		$Sprite2D.scale = Vector2(1.5, 1.5)
		radius = 13
	base_hp = hp
	base_damage = damage * sqrt(run.difficulty)
	max_hp = hp
	update_scaling()

func update_scaling():
	var minutes = run.elapsed / 60.0
	var health_factor = 1.0 + minutes * 0.42 + minutes * minutes * 0.045
	var fraction = hp / max_hp
	max_hp = base_hp * health_factor
	hp = max_hp * fraction
	damage = base_damage * (1.0 + minutes * 0.12)

func _physics_process(delta):
	if dead or not is_instance_valid(run) or run.ended:
		return
	scaling_clock -= delta
	if scaling_clock <= 0:
		scaling_clock = 1.0
		update_scaling()
	age += delta
	steam_lock = maxf(0, steam_lock - delta)
	slow_time = maxf(0, slow_time - delta)
	flash = maxf(0, flash - delta)
	$Sprite2D.modulate = Color(3, 3, 3) if flash > 0 else (Color("9be5ff") if slow_time > 0 else Color("ffd879") if elite else Color.WHITE)
	var player = run.player
	var offset = player.global_position - global_position
	var distance = offset.length()
	attack_clock -= delta
	if windup > 0:
		windup -= delta
		velocity = Vector2.ZERO
		if windup <= 0:
			if boss:
				for i in range(12):
					run.enemy_bullet(global_position, Vector2.RIGHT.rotated(i * TAU / 12.0), damage)
			else:
				run.enemy_bullet(global_position, (attack_target - global_position).normalized(), damage)
	elif (kind == "caster" or boss) and attack_clock <= 0:
		windup = 0.8
		attack_target = player.global_position
		attack_clock = 3.5 if boss else 3.0
	else:
		var dir = offset.normalized()
		if kind == "caster" and distance < 125:
			dir *= -0.4
		velocity = dir * movement_speed * (slow_factor if slow_time > 0 else 1.0)
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 500 * delta)
	velocity += knockback_velocity + run.separation(self)
	if test_move(global_transform, velocity.normalized() * 8):
		var tangent = velocity.rotated(PI / 2)
		if test_move(global_transform, tangent.normalized() * 8):
			tangent = -tangent
		velocity = tangent
	move_and_slide()
	$Sprite2D.flip_h = offset.x < 0
	if distance < radius + 7:
		player.take_damage(damage * run.difficulty)
	if distance > 700 and not boss and not elite:
		queue_free()
	queue_redraw()

func take_damage(amount: float, direction: Vector2 = Vector2.ZERO):
	if dead:
		return
	hp -= amount
	flash = 0.08
	knockback_velocity = direction * (25 if boss else 95)
	run.floating_text(global_position, str(int(amount)), Color("fff0c2"))
	if hp <= 0:
		dead = true
		run.enemy_died(self)
		queue_free()

func _on_hurt_box_hurt(amount, angle):
	take_damage(amount, angle)

func _draw():
	if elite or boss:
		draw_arc(Vector2.ZERO, radius + 3, 0, TAU, 24, Color("ffd879"), 1)
		draw_rect(Rect2(-18, -radius - 10, 36, 3), Color("32283e"))
		draw_rect(Rect2(-18, -radius - 10, 36 * maxf(0, hp / max_hp), 3), Color("ef797c"))
	if windup > 0:
		draw_arc(Vector2.ZERO, radius + 7 + windup * 12, 0, TAU, 24, Color("ff795e"), 2)

func apply_slow(duration: float, factor: float):
	slow_time = maxf(slow_time, duration)
	slow_factor = factor if slow_time <= duration else minf(slow_factor, factor)
