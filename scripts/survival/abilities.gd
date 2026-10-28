extends RefCounted
# Each defender's Space ability. Names, descriptions and cooldowns live in the
# defender's CharacterDef; the behaviour lives here, keyed by defender.

const Data = preload("res://scripts/survival/data.gd")
var run: Node

func _init(director: Node):
	run = director

func cooldown() -> float:
	var def = Data.character_def(run.player.character_key)
	return (def.ability_cooldown if def else 3.0) * pow(0.85, run.items.get("silk", 0))

# Scales ability damage with the run: player level and damage bonuses.
func strength(base: float, per_level: float) -> float:
	return (base + per_level * run.player.level) * run.power()

func use():
	var p = run.player
	p.ability_cooldown = cooldown()
	run.play_sound("dash")
	match p.character_key:
		"pepper":
			# Hot Wings: a ring of flame and a burst around you.
			run.blast(p.global_position, 60 * run.area_multiplier(), strength(25, 2), true, "hotwings")
			for i in range(8):
				run.spawn_fire_patch(p.global_position + Vector2.RIGHT.rotated(i * TAU / 8) * 40)
		"whisker":
			# Pounce: leap onto the nearest enemy and strike where you land.
			# Searches its own range: the weapons' cached target can be far away.
			var direction = p.facing
			var distance = 110.0
			var prey = null
			for enemy in run.nearby_enemies(p.global_position, 170):
				if not is_instance_valid(enemy) or enemy.dead: continue
				var d = p.global_position.distance_to(enemy.global_position)
				if d < minf(distance, 170):
					distance = d
					prey = enemy
					direction = p.global_position.direction_to(enemy.global_position)
			p.invulnerability = maxf(p.invulnerability, 0.4)
			# The strike centres on the prey if it is still alive, otherwise where the cat lands.
			p.lunge(direction, 520, clampf(distance / 520.0, 0.08, 0.3), func():
				var spot = prey.global_position if is_instance_valid(prey) and not prey.dead else p.global_position
				run.blast(spot, 40 * run.area_multiplier(), strength(30, 3), true, "pounce"))
		"truffle":
			# Ground Pound: a shockwave that stuns everything nearby.
			var radius = 75 * run.area_multiplier()
			for enemy in run.nearby_enemies(p.global_position, radius + 32):
				if is_instance_valid(enemy) and not enemy.dead and p.global_position.distance_to(enemy.global_position) < radius + enemy.radius:
					enemy.apply_slow(1.2, 0.05)
			run.blast(p.global_position, radius, strength(20, 2), true, "pound")
		"clover":
			# Hold the Line: a moment of invulnerability while your blades spin faster.
			p.invulnerability = maxf(p.invulnerability, 2.5)
			run.orbit_rush = 2.5
			run.effect(p.global_position, "FX/Magic/Circle/SpriteSheetWhite.png", Vector2i(32, 32), 0.4, 2.5)
		"frog":
			# Leap: hop clear of danger and splash mud where you land.
			p.invulnerability = maxf(p.invulnerability, 0.4)
			p.lunge(p.facing, 330, 0.35, func():
				var radius = 45 * run.area_multiplier()
				for enemy in run.nearby_enemies(p.global_position, radius + 32):
					if is_instance_valid(enemy) and not enemy.dead and p.global_position.distance_to(enemy.global_position) < radius + enemy.radius:
						enemy.apply_slow(2.0, 0.5)
				run.blast(p.global_position, radius, strength(22, 2), true, "leap"))
		"parrot":
			# Squawk: blast everything nearby away and stun it briefly.
			var radius = 95 * run.area_multiplier()
			for enemy in run.nearby_enemies(p.global_position, radius + 32):
				if is_instance_valid(enemy) and not enemy.dead and p.global_position.distance_to(enemy.global_position) < radius + enemy.radius:
					enemy.apply_slow(1.2, 0.05)
					enemy.knockback_velocity = p.global_position.direction_to(enemy.global_position) * (60 if enemy.boss else 260)
					run.deal_damage(enemy, strength(5, 0.5), Vector2.ZERO, "squawk")
			run.effect(p.global_position, "FX/Magic/Circle/SpriteSheetWhite.png", Vector2i(32, 32), 0.3, radius / 16.0)
		"donkey":
			# Buck Kick: a huge kick behind you.
			var behind = -p.facing.normalized()
			var reach = 70 * run.area_multiplier()
			for enemy in run.nearby_enemies(p.global_position, reach + 32):
				if not is_instance_valid(enemy) or enemy.dead: continue
				var offset = enemy.global_position - p.global_position
				if offset.length() < reach + enemy.radius and absf(behind.angle_to(offset)) < 0.8:
					enemy.knockback_velocity = behind * (80 if enemy.boss else 320)
					run.deal_damage(enemy, strength(40, 4), behind, "buck")
			run.effect(p.global_position + behind * 30, "FX/Elemental/Explosion/SpriteSheet.png", Vector2i(40, 40), 0.3, 1.2)
		_:
			# Flutter Dash: a quick burst with a moment of invulnerability.
			p.invulnerability = maxf(p.invulnerability, 0.3)
			p.lunge(p.facing, 360, 0.18)
	run.on_ability()
