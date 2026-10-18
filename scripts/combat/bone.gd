extends Area2D

@export var xp_value: int = 5
@export var magnet_range: float = 200.0  # How close you need to be
@export var speed: float = 0.0
@export var acceleration: float = 600.0

var player = null

func _ready():
	add_to_group("loot")
	# Find the player once at the start
	player = get_tree().get_first_node_in_group("player")

func _process(delta):
	if player == null:
		return # Stop if no player exists
		
	var distance = global_position.distance_to(player.global_position)
	
	# If player is within range, start flying toward them
	if distance < magnet_range:
		speed += acceleration * delta
		global_position = global_position.move_toward(player.global_position, speed * delta)

# Make sure this signal is connected to the Bone's own body_entered
func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("gain_xp"):
			body.gain_xp(xp_value)
		queue_free()
