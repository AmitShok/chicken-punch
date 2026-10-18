extends Area2D


@export var damage = 5
@export var speed: float = 500.0
@export var knockback = 5

var direction: Vector2 = Vector2.ZERO
var level = 1


func _process(delta):
	# Move the egg in a straight line
	position += direction * speed * delta

# This function is called by the Attack script when the egg is created
func launch(target_direction: Vector2):
	direction = target_direction
	# Optional: make the egg face the direction it's flying
	rotation = direction.angle()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		# Add enemy damage logic here!
		if body.has_method("damage"):
			body.damage()
			body.knockback()
		queue_free()      # Destroy egg
