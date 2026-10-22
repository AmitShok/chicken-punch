extends ProgressBar

var motion_enabled = true
var previous_ratio = -1.0
var trail_ratio = 1.0
var hold = 0.0

func _process(delta):
	var ratio = clampf(value / maxf(1, max_value), 0, 1)
	if previous_ratio < 0 or not motion_enabled:
		trail_ratio = ratio
		hold = 0.0
	elif ratio < previous_ratio:
		trail_ratio = maxf(trail_ratio, previous_ratio)
		hold = 0.18
	elif ratio > trail_ratio:
		trail_ratio = ratio
	if not get_tree().paused:
		hold = maxf(0, hold - delta)
		if hold <= 0:
			trail_ratio = lerpf(trail_ratio, ratio, 1.0 - exp(-12.0 * delta))
			if absf(trail_ratio - ratio) < 0.002: trail_ratio = ratio
	previous_ratio = ratio
	queue_redraw()

func _draw():
	if previous_ratio < 0 or trail_ratio <= previous_ratio: return
	var start = roundf(size.x * previous_ratio)
	var end = roundf(size.x * trail_ratio)
	draw_rect(Rect2(start, 1, maxf(0, end - start), maxf(1, size.y - 2)), Color("f5c957"))
