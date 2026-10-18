extends CanvasLayer

@onready var xp_bar = $XPBar

func _ready():
	# Find the player and connect to their leveling data
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Set initial values
		update_xp_bar(player.current_xp, player.max_xp)

func update_xp_bar(current_value, max_value):
	xp_bar.max_value = max_value
	xp_bar.value = current_value
