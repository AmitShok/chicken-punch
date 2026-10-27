extends SceneTree
# Fixed-position damage comparison, not a human win-rate or survival estimate.
const Shot = preload("res://scripts/survival/projectile.gd")
const Data = preload("res://scripts/survival/data.gd")
func _initialize(): call_deferred("test")
func test():
	Data.save_path = "user://build_comparison.cfg"
	Data.write_save({"muted":true})
	for full in [false,true]:
		var run = load("res://scenes/world/world.tscn").instantiate()
		root.add_child(run)
		current_scene = run
		run.set_physics_process(false)
		run.player.set_physics_process(false)
		run.player.invulnerability = 10000
		run.rng.seed = 9043
		run.elapsed = 600
		run.boss_stage = 3
		run.spawn_clock = 10000
		run.elite_clock = 10000
		run.treasure_clock = 10000
		run.ranks = {"egg":10,"orbit":10,"might":10,"haste":10}
		run.items = {"powder":3,"honey":3,"bead":3}
		run.evolved = {"egg":true}
		if full:
			run.ranks = {"egg":10,"fire":10,"shell":10,"frost":10,"haste":10,"area":10,"duration":10,"projectile_count":10}
			run.evolved = {"egg":true,"fire":true,"frost":true}
			run.ascension = "henpocalypse"
		var boss = run.spawn_enemy("boss",true)
		boss.final_guardian = false
		boss.position = run.player.position + Vector2(60,0)
		boss.set_physics_process(false)
		var initial = boss.hp
		if full: run.spawn_fire_patch(boss.position)
		var killed_at = -1.0
		for tick in range(1800):
			run.pending_levels = 0
			run.pending_treasures = 0
			run._physics_process(1.0/60)
			for child in run.get_children():
				if child is Shot:
					child.set_physics_process(false)
					child._physics_process(1.0/60)
			await process_frame
			if not is_instance_valid(boss):
				killed_at = (tick+1)/60.0
				break
		var remaining = boss.hp if is_instance_valid(boss) else 0
		print("BUILD COMPARISON full=",full," damage=",initial-remaining," / ",initial," killed_at=",killed_at," seconds (30s limit)")
		run.queue_free()
		await process_frame
	quit()
