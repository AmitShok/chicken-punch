extends Node2D

var run: Node
var kind = "xp"
var value = 3
var pulled = false
var age = 0.0
var chest_free = false
var opened = false

func _process(delta):
	if run.ended or opened:
		return
	age += delta
	var distance = global_position.distance_to(run.player.global_position)
	if kind == "xp" or kind == "gold" or kind == "heal":
		if distance < run.pickup_radius():
			pulled = true
		if pulled:
			global_position = global_position.move_toward(run.player.global_position, (150 + age * 5) * delta)
	if kind == "chest":
		$Sprite.position.y = sin(age * 3) * 0.5
		return
	if distance < 14:
		run.collect(self)
		queue_free()
	$Sprite.position.y = sin(age * 3) * 1.5

