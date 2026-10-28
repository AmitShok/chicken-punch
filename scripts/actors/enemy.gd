extends CharacterBody2D

@export var movement_speed = 28.0
@export var hp = 10.0
@export var bone_scene: PackedScene
@export var knockback_friction = 0.1
static var animation_cache: Dictionary = {}
var navigation_clock = 0.0
var separation_clock = 0.0
var separation_force = Vector2.ZERO
static var flash_materials: Array[ShaderMaterial] = []
var previous_flash = 0.0
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
var rest_scale = Vector2.ONE
var knockback_lock = 0.0
var last_impact_direction = Vector2.ZERO
var impact_lock = 0.0
var health_reveal = 0.0
var health_trail = 1.0
var health_trail_delay = 0.0
var hit_material: ShaderMaterial
var slow_time = 0.0
var steam_lock = 0.0
var roast_stacks = 0
var roast_time = 0.0
var slow_factor = 1.0
# Moldy Cheese poison, and which weapon landed the last hit (for kill rewards).
var poison_time = 0.0
var poison_dps = 0.0
var poison_clock = 0.0
var last_source = ""
# Monster sheets are 4x4: columns face down, left, up and right; rows are walk frames.
var directional = false

func _ready():
	collision_layer = 4
	collision_mask = 1
	$HurtBox.monitoring = false
	$HurtBox.monitorable = false
	$HitBox.monitoring = false
	$HitBox.monitorable = false
	$HitBox.collision_layer = 0
	$Sprite2D.scale = Vector2.ONE
	if flash_materials.is_empty():
		for step in range(5):
			var material = ShaderMaterial.new()
			material.shader = preload("res://assets/shaders/hit_flash.gdshader")
			material.set_shader_parameter("flash_amount", step / 4.0)
			flash_materials.append(material)
	hit_material = flash_materials[0]
	separation_clock = (get_instance_id() % 6) * 0.02
	$Sprite2D.material = hit_material

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
			movement_speed = 34
			hp = (1100 + run.elapsed * 4) * (2.0 if run.boss_stage == 3 else 1.35 if run.boss_stage == 2 else 1.0)
			damage = 30
			radius = 18
	if not animation_cache.has(path):
		animation_cache[path] = build_frames(load("res://assets/Ninja Adventure - Asset Pack/" + path), frame_size)
	$Sprite2D.sprite_frames = animation_cache[path]
	directional = $Sprite2D.sprite_frames.has_animation("down")
	$Sprite2D.play("down" if directional else "default")
	$Sprite2D.speed_scale = randf_range(0.85, 1.15)
	$Sprite2D.frame = randi() % $Sprite2D.sprite_frames.get_frame_count($Sprite2D.animation)
	hp *= run.difficulty * 1.25
	if elite and not boss:
		hp *= 5
		movement_speed *= 1.12
		$Sprite2D.scale = Vector2(1.5, 1.5)
		radius = 13
	rest_scale = $Sprite2D.scale
	# New enemies pop in instead of appearing at full size.
	if run.save.get("combat_feedback", true):
		$Sprite2D.scale = rest_scale * Vector2(0.3, 0.3)
		run.feedback.puff(global_position + Vector2(0, 4), Vector2.ZERO, Color("e8d6a6"), 0.5, 0.3)
	base_hp = hp
	base_damage = damage * sqrt(run.difficulty) * 1.15
	max_hp = hp
	update_scaling()

func update_scaling():
	var minutes = run.elapsed / 60.0
	var health_factor = 1.0 + minutes * 0.7 + minutes * minutes * 0.12
	var fraction = hp / max_hp
	max_hp = base_hp * health_factor
	hp = max_hp * fraction
	damage = base_damage * (1.0 + minutes * 0.22 + minutes * minutes * 0.015) * (1.0 + maxf(0, run.elapsed - 600) / 90.0)

func _physics_process(delta):
	if dead or not is_instance_valid(run) or run.ended:
		return
	scaling_clock -= delta
	if scaling_clock <= 0:
		scaling_clock = 1.0
		update_scaling()
	age += delta
	steam_lock = maxf(0, steam_lock - delta)
	roast_time = maxf(0, roast_time - delta)
	if roast_time <= 0: roast_stacks = 0
	slow_time = maxf(0, slow_time - delta)
	if poison_time > 0:
		poison_time -= delta
		poison_clock -= delta
		if poison_clock <= 0:
			poison_clock = 0.5
			run.deal_damage(self, poison_dps * 0.5, Vector2.ZERO, "poison")
			if dead: return
	update_feedback(delta)
	$Sprite2D.modulate = Color("9be5ff") if slow_time > 0 else Color("ffad75") if roast_stacks > 0 else Color("ffd879") if elite else Color.WHITE
	var player = run.player
	var offset = player.global_position - global_position
	var distance = offset.length()
	attack_clock -= delta
	if windup > 0:
		windup -= delta
		velocity = Vector2.ZERO
		if windup <= 0:
			if boss:
				var count = 16 if run.elapsed < 360 else 20
				for i in range(count):
					run.enemy_bullet(global_position, Vector2.RIGHT.rotated(i * TAU / count + age * 0.22), damage)
				for i in range(-1,2):
					run.enemy_bullet(global_position, (attack_target - global_position).normalized().rotated(i * 0.18), damage)
			else:
				var spread = 1 if run.elapsed >= 300 else 0
				for i in range(-spread, spread + 1):
					run.enemy_bullet(global_position, (attack_target - global_position).normalized().rotated(i * 0.2), damage)
	elif (kind == "caster" or boss) and attack_clock <= 0:
		windup = 0.8
		attack_target = player.global_position
		attack_clock = maxf(1.8, 2.8 - maxf(0,run.elapsed - 600) / 180) if boss else 2.6
	else:
		var dir = offset.normalized()
		if kind == "caster" and distance < 125:
			dir *= -0.4
		velocity = dir * movement_speed * (1.0 + minf(12, run.elapsed / 60) * 0.035) * (slow_factor if slow_time > 0 else 1.0)
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 500 * delta)
	separation_clock -= delta
	if separation_clock <= 0:
		separation_clock = 0.12
		separation_force = run.separation(self)
	velocity += knockback_velocity + separation_force
	navigation_clock -= delta
	if navigation_clock <= 0 and test_move(global_transform, velocity.normalized() * 8):
		navigation_clock = 0.12
		var tangent = velocity.rotated(PI / 2)
		if test_move(global_transform, tangent.normalized() * 8):
			tangent = -tangent
		velocity = tangent
	move_and_slide()
	face(velocity if velocity.length() > 4 else offset)
	if distance < radius + 7:
		if player.take_damage(damage * run.difficulty):
			run.on_player_struck(self)
	if distance > 700 and not boss and not elite:
		queue_free()
	if elite or boss or health_reveal > 0: queue_redraw()

func take_damage(amount: float, direction: Vector2 = Vector2.ZERO, knockback_interval: float = 0.16):
	if dead:
		return
	health_trail = maxf(health_trail, hp / max_hp)
	health_trail_delay = 0.18
	health_reveal = 1.6
	hp -= amount
	if not direction.is_zero_approx():
		last_impact_direction = direction.normalized()
		if knockback_lock <= 0:
			knockback_velocity = last_impact_direction * (25 if boss else 95)
			knockback_lock = knockback_interval
	if impact_lock <= 0:
		run.play_sound("impact")
		flash = 0.08
		if run.save.get("combat_feedback", true):
			$Sprite2D.scale = rest_scale * Vector2(1.16, 0.84)
		run.floating_text(global_position, str(int(amount)), Color("fff0c2"))
		run.feedback.impact(global_position, last_impact_direction)
		impact_lock = 0.10
	if hp <= 0:
		dead = true
		run.enemy_died(self)
		queue_free()

func _on_hurt_box_hurt(amount, angle):
	take_damage(amount, angle)

func _draw():
	if elite or boss:
		draw_arc(Vector2.ZERO, radius + 3, 0, TAU, 24, Color("ffd879"), 1)
	if elite or boss or (health_reveal > 0 and hp < max_hp):
		var width = 36.0 if elite or boss else 18.0
		var origin = Vector2(-width / 2, -radius - 8)
		draw_rect(Rect2(origin - Vector2.ONE, Vector2(width + 2, 4)), Color("32283e"))
		draw_rect(Rect2(origin, Vector2(width * health_trail, 2)), Color("f5c957"))
		draw_rect(Rect2(origin, Vector2(width * maxf(0, hp / max_hp), 2)), Color("ef797c"))
	if windup > 0:
		draw_arc(Vector2.ZERO, radius + 7 + windup * 12, 0, TAU, 24, Color("ff795e"), 2)

func apply_slow(duration: float, factor: float):
	if boss:
		duration = minf(duration, 2.0)
		factor = maxf(factor, 0.7)
	elif elite:
		factor = maxf(factor, 0.5)
	slow_time = maxf(slow_time, duration)
	slow_factor = factor if slow_time <= duration else minf(slow_factor, factor)

func update_feedback(delta: float):
	knockback_lock = maxf(0, knockback_lock - delta)
	impact_lock = maxf(0, impact_lock - delta)
	if health_reveal > 0 and health_reveal <= delta: queue_redraw()
	health_reveal = maxf(0, health_reveal - delta)
	health_trail_delay = maxf(0, health_trail_delay - delta)
	flash = maxf(0, flash - delta)
	var motion = run.save.get("combat_feedback", true)
	$Sprite2D.scale = $Sprite2D.scale.lerp(rest_scale, minf(1, delta * 22)) if motion else rest_scale
	animate_body(motion)
	if flash > 0 or previous_flash > 0:
		hit_material = flash_materials[clampi(roundi(flash / 0.035 * 4), 0, 4)]
		$Sprite2D.material = hit_material
	previous_flash = flash
	if not motion:
		health_trail = maxf(0, hp / max_hp)
	elif health_trail_delay <= 0:
		health_trail = move_toward(health_trail, maxf(0, hp / max_hp), delta * 2.5)

# Monster sheets (64x64) become four directional walk cycles; strips play in order.
static func build_frames(tex: Texture2D, frame_size: Vector2) -> SpriteFrames:
	var frames = SpriteFrames.new()
	var columns = int(tex.get_width() / frame_size.x)
	var rows = int(tex.get_height() / frame_size.y)
	if columns == 4 and rows == 4:
		frames.remove_animation("default")
		var directions = ["down", "left", "up", "right"]
		for column in range(4):
			frames.add_animation(directions[column])
			frames.set_animation_speed(directions[column], 7)
			for row in range(4):
				frames.add_frame(directions[column], atlas(tex, Rect2(Vector2(column, row) * frame_size, frame_size)))
	else:
		frames.set_animation_speed("default", 6)
		for i in range(columns):
			frames.add_frame("default", atlas(tex, Rect2(Vector2(i * frame_size.x, 0), frame_size)))
	return frames

static func atlas(tex: Texture2D, region: Rect2) -> AtlasTexture:
	var result = AtlasTexture.new()
	result.atlas = tex
	result.region = region
	return result

# Directional sheets pick a facing; single strips mirror horizontally.
func face(direction: Vector2):
	if not directional:
		$Sprite2D.flip_h = direction.x < 0
		return
	var wanted = ("right" if direction.x > 0 else "left") if absf(direction.x) > absf(direction.y) else ("down" if direction.y > 0 else "up")
	if $Sprite2D.animation != wanted:
		var frame = $Sprite2D.frame
		$Sprite2D.play(wanted)
		$Sprite2D.frame = frame

# Visual-only movement: dogs and guardians hop, bears waddle, bats flutter, lanterns float.
func animate_body(motion: bool):
	var sprite = $Sprite2D
	if not motion:
		sprite.position = Vector2.ZERO
		sprite.rotation = 0
		return
	match kind:
		"bat": sprite.position.y = sin(age * 11.0) * 1.5 - 2
		"caster": sprite.position.y = sin(age * 3.0) * 2.0 - 2
		"tank":
			sprite.rotation = sin(age * 7.0) * 0.07
			sprite.position.y = -absf(sin(age * 7.0)) * 0.8
		"boss": sprite.position.y = -absf(sin(age * 2.6)) * 4.0
		_: sprite.position.y = -absf(sin(age * 13.0)) * 2.0
