extends Path2D
@onready var enemyTimer = $"../../EnemyTimer"
@onready var enemy_scene = $"."
@onready var spawn_path: Path2D = $Camera2D/spawner
@onready var path_follow: PathFollow2D = $Camera2D/spawner/PathFollow2D2

func _on_mob_timer_timeout():
	var enemy = enemy_scene.instantiate()

	# 2. Pick a random spot on the Path2D
	var enemy_spawn_location = spawn_path
	enemy_spawn_location.progress_ratio = randf() # Returns a value between 0.0 and 1.0

	# 3. Set the enemy's position to that random spot
	# Use global_position to ensure it matches the world coordinates
	enemy.global_position = enemy_spawn_location.global_position

	# 4. Add the enemy to the main scene (not as a child of the camera)
	# This prevents enemies from "moving" with the camera after they spawn
	get_parent().add_child(enemy)
