extends Area2D
 
@export var damage = 15

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		if body.has_method("damage"):
			body.damage()
			


func _on_timer_timeout() -> void:
	queue_free()
