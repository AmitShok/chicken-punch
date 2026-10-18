extends Area2D

@export_enum("Cooldown","HitOnce","DisableHitBox") var HurtBoxType = 0

@onready var collision = $CollisionShape2D
@onready var disableTimer = $DisableTimer

signal hurt(damage, angle)



func _on_area_entered(area):
	var damage = area.get("damage")
	if damage == null: return
	if area.is_in_group("attacks"): 
		if not area.get("damage") == null:
			match HurtBoxType:
				0: #Cooldown
					collision.call_deferred("set","disabled",true)
					disableTimer.start()
				1: #HitOnce
					pass
				2: #DisableHitBox
					if area.has_method("tempdisable"):
						area.tempdisable()
						
			var attack_angle = Vector2.ZERO
			if "direction" in area:
				attack_angle = area.direction
			else:
				attack_angle = (global_position - area.global_position).normalized() 
			
			emit_signal("hurt", damage , attack_angle)

func _on_timer_timeout():
	collision.call_deferred("set","disabled",false)

