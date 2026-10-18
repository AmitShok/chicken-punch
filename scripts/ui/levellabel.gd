extends Label

var player = null

func _ready():
	player = get_tree().get_first_node_in_group("player")
func _process(_delta):
	text = "Level: " + str(player.level)
