extends Node2D

var active = true
var run: Node
var direction = Vector2.RIGHT
var speed = 230.0
var speed_scale = 1.0
var hit_radius = 4.0
var damage = 10.0
var lifetime = 2.5
var pierce = 1
var hostile = false
var hit_ids: Dictionary = {}
var spin = false
var splash = 0.0
var source = "egg"
var slow_duration = 0.0
var slow_factor = 0.55
var returning_weapon = false
var returning = false
var return_hits = 0
var age = 0.0
var detonates = false
var destination = Vector2.ZERO
# Turn rate in radians per second toward the nearest enemy (Parrot Squadron).
var homing = 0.0

func _physics_process(delta):
	if not active: return
	lifetime -= delta
	age += delta
	if lifetime <= 0 or run.ended or (not returning_weapon and global_position.distance_squared_to(run.player.global_position) > 810000):
		if detonates and not run.ended:
			detonate()
		retire()
		return
	if returning_weapon and age >= 0.7:
		if not returning:
			returning = true
			hit_ids.clear()
		direction = global_position.direction_to(run.player.global_position)
		if global_position.distance_to(run.player.global_position) < 10:
			run.complete_sickle_return(return_hits)
			retire()
			return
	if homing > 0 and not hostile:
		var prey = null
		var best = 200.0 * 200.0
		for enemy in run.nearby_enemies(global_position, 200):
			if not is_instance_valid(enemy) or enemy.dead or hit_ids.has(enemy.get_instance_id()): continue
			var d = global_position.distance_squared_to(enemy.global_position)
			if d < best:
				best = d
				prey = enemy
		if prey:
			var wanted = global_position.direction_to(prey.global_position)
			direction = direction.rotated(clampf(direction.angle_to(wanted), -homing * delta, homing * delta))
			$Sprite.flip_h = direction.x < 0
	var start = global_position
	global_position += direction * speed * speed_scale * delta
	if returning and Geometry2D.get_closest_point_to_segment(run.player.global_position, start, global_position).distance_to(run.player.global_position) < 10:
		run.complete_sickle_return(return_hits)
		retire()
		return
	if spin:
		$Sprite.rotation += delta * 15
	if detonates and Geometry2D.get_closest_point_to_segment(destination, start, global_position).distance_to(destination) < 8:
		detonate()
		return
	if hostile:
		if Geometry2D.get_closest_point_to_segment(run.player.global_position, start, global_position).distance_to(run.player.global_position) < 9:
			run.player.take_damage(damage)
			retire()
	else:
		for enemy in run.enemies_in_rect(Rect2(start, Vector2.ZERO).expand(global_position).grow(hit_radius + 32)):
			if not is_instance_valid(enemy) or enemy.dead or hit_ids.has(enemy.get_instance_id()):
				continue
			var nearest = Geometry2D.get_closest_point_to_segment(enemy.global_position, start, global_position)
			if nearest.distance_to(enemy.global_position) < enemy.radius + hit_radius:
				if detonates:
					detonate()
					return
				hit_ids[enemy.get_instance_id()] = true
				if returning:
					return_hits += 1
				if slow_duration > 0:
					enemy.apply_slow(slow_duration, slow_factor)
				run.deal_damage(enemy, damage, direction, source)
				if splash > 0:
					run.blast(global_position, splash, damage * 0.6, true, source)
				pierce -= 1
				if pierce <= 0:
					retire()
					return

func detonate():
	run.play_sound("explosion")
	if source == "shell":
		run.shell_fragments(global_position, damage)
	run.blast(global_position, splash, damage, true, source)
	retire()

func retire():
	if not active: return
	active = false
	hide()
	set_physics_process(false)
	run.recycle_shot(self)

func reset_projectile():
	active = true
	show()
	set_physics_process(true)
	modulate = Color.WHITE
	direction = Vector2.RIGHT
	speed = 230.0
	speed_scale = 1.0
	hit_radius = 4.0
	damage = 10.0
	lifetime = 2.5
	pierce = 1
	hostile = false
	hit_ids.clear()
	spin = false
	splash = 0.0
	source = "egg"
	slow_duration = 0.0
	slow_factor = 0.55
	returning_weapon = false
	returning = false
	return_hits = 0
	age = 0.0
	detonates = false
	destination = Vector2.ZERO
	homing = 0.0
