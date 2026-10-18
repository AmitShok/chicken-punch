extends Node2D

@export var shuriken_scene : PackedScene

func fire_at(target):
	# DEBUG: This will print to the console so we can see if it's empty
	if shuriken_scene == null:
		print("ERROR: ", name, " has no scene assigned in the Inspector!")
		return

	var shuriken = shuriken_scene.instantiate()
	
	get_tree().root.add_child(shuriken)
	
	shuriken.global_position = global_position
	
	var direction = (target.global_position - global_position).normalized()
	
	# Make sure your Egg script has the 'launch' function!
	if shuriken.has_method("launch"):
		shuriken.launch(direction)
