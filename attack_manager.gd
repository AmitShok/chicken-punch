extends Node2D

@export var fire_rate: float = 1.0
var timer: float = 0.0

func _process(delta):
	timer += delta
	if timer >= fire_rate:
		timer = 0
		execute_all_attacks()

func execute_all_attacks():
	var target = find_nearest_enemy()
	if target == null:
		return

	for child in get_children():
		# This line checks: "Do you have the fire_at function?"
		if child.has_method("fire_at"):
			child.fire_at(target)
		else:
			print("Skipping child: ", child.name, " because it has no fire_at script!")

func find_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_enemy = null
	var shortest_distance = INF # 'INF' means infinity

	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < shortest_distance:
			shortest_distance = distance
			nearest_enemy = enemy
	
	return nearest_enemy
