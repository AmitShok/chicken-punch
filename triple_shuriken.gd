extends Area2D

@export var damage = 5
@export var speed: float = 1000 


var direction: Vector2 = Vector2.ZERO
var level = 1

func _process(delta):
	position += direction * speed * delta 

func launch(target_direction: Vector2):
	direction = target_direction
	rotation = direction.angle()
	
func _on_body_entered(body):
	if body.is_in_group("enemies"):
		# Add enemy damage logic here!
		if body.has_method("damage"):
			body.damage()
			body.knockback()
		queue_free()      # Destroy egg
