extends Node2D

# This creates a slot in the Inspector where you can DRAG the node
@export var spawn_location: PathFollow2D 
@export var enemy_scene: PackedScene 

func _on_mob_timer_timeout():
	if not spawn_location or not enemy_scene:
		print("Error: Drag both the 'SpawnLocation' and 'EnemyScene' into the Inspector!")
		return

	# Pick random spot on the path
	spawn_location.progress_ratio = randf()

	# Create and spawn the enemy
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.global_position = spawn_location.global_position
