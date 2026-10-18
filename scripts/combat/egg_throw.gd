extends Node2D

# This creates the slot in the Inspector
@export var egg_scene: PackedScene 

func fire_at(target):
	# DEBUG: This will print to the console so we can see if it's empty
	if egg_scene == null:
		print("ERROR: ", name, " has no scene assigned in the Inspector!")
		return

	var egg = egg_scene.instantiate()
	
	# Add to root so the egg doesn't move when the chicken moves
	get_tree().root.add_child(egg)
	
	egg.global_position = global_position
	
	var direction = (target.global_position - global_position).normalized()
	
	# Make sure your Egg script has the 'launch' function!
	if egg.has_method("launch"):
		egg.launch(direction)
