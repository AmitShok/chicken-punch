extends Node
# Export this scene only in a disposable diagnostic build, never the release main scene.
var run: Node
var samples: Array[float] = []
var started = 0
var previous = 0
var report: Label
var done = false
var physics_samples: Array[float] = []
var process_samples: Array[float] = []
func _ready():
	var data = preload("res://scripts/survival/data.gd")
	data.save_path = "user://render_stress.cfg"
	data.write_save({"muted":true})
	run = load("res://scenes/world/world.tscn").instantiate()
	add_child(run)
	run.rng.seed = 74021
	run.elapsed = 570
	run.boss_stage = 3
	run.spawn_clock = 10000
	run.elite_clock = 10000
	run.treasure_clock = 10000
	run.player.invulnerability = 10000
	run.ranks = {"egg":10,"fire":10,"shell":10,"frost":10,"haste":10,"projectile_count":10,"duration":10,"projectile_size":10}
	run.evolved = {"egg":true,"fire":true,"shell":true,"frost":true}
	run.items = {"powder":3,"lens":3}
	run.ascension = "henpocalypse"
	for i in range(180):
		var e = run.spawn_enemy("caster" if i % 9 == 0 else "tank")
		e.position = run.player.position + Vector2.RIGHT.rotated(i * TAU / 180) * (80 + i % 7 * 20)
		e.max_hp = 1e12
		e.hp = 1e12
		e.scaling_clock = 10000
	for i in range(960): run.spawn_fire_patch(run.player.position + Vector2((i % 48)*12-282,(i / 48)*12-114))
	for h in run.hazards: h.life = 1000
	var layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	report = Label.new()
	report.position = Vector2(20,200)
	report.add_theme_font_size_override("font_size",24)
	report.add_theme_color_override("font_shadow_color",Color.BLACK)
	report.add_theme_constant_override("shadow_offset_x",2)
	report.add_theme_constant_override("shadow_offset_y",2)
	layer.add_child(report)
	started = Time.get_ticks_usec()
	previous = started
func _process(_delta):
	if done: return
	var now = Time.get_ticks_usec()
	var age = (now - started) / 1000000.0
	if age > 5:
		samples.append((now - previous) / 1000.0)
		physics_samples.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
		process_samples.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
	previous = now
	report.text = "Rendered stress test: %ds / 30s\n180 enemies; maxed 4-weapon build" % int(age)
	if age < 30: return
	done = true
	samples.sort()
	physics_samples.sort()
	process_samples.sort()
	print("CPU physics median=",physics_samples[physics_samples.size()/2], " process median=", process_samples[process_samples.size()/2], " draw calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var result = "RENDER STRESS: median %.2f ms / p95 %.2f ms\n%d frames; %d enemies; %d world nodes" % [samples[samples.size()/2],samples[int(samples.size()*0.95)],samples.size(),run.enemies.size(),run.get_child_count()]
	report.text = result
	print(result)
	get_tree().paused = true
	if not OS.has_feature("web"):
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://render-stress.png")
		get_tree().quit()
