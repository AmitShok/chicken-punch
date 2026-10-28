extends SceneTree
# Damage per second of each weapon alone, against a stationary crowd and a
# single guardian, at a given rank. A relative power ranking, not a win rate.
# Usage: godot --headless --path . --script res://tools/balance/weapon_bench.gd -- [rank] [tome:rank,...]
const Shot = preload("res://scripts/survival/projectile.gd")
const Data = preload("res://scripts/survival/data.gd")
const SECONDS = 12.0

func _initialize(): call_deferred("bench")

func bench():
	var args = OS.get_cmdline_user_args()
	var rank = int(args[0]) if args.size() > 0 else 10
	var tomes = {}
	if args.size() > 1:
		for part in args[1].split(","):
			tomes[part.split(":")[0]] = int(part.split(":")[1])
	Data.save_path = "user://weapon_bench.cfg"
	Data.write_save({"muted": true})
	for weapon in Data.WEAPONS:
		for target in ["crowd", "single"]:
			var run = load("res://scenes/world/world.tscn").instantiate()
			root.add_child(run)
			current_scene = run
			await process_frame
			run.set_physics_process(false)
			run.player.set_physics_process(false)
			run.player.invulnerability = 1.0e9
			run.rng.seed = 7
			run.spawn_clock = 1.0e9
			run.elite_clock = 1.0e9
			run.treasure_clock = 1.0e9
			run.elapsed = 1
			run.ranks = {weapon: rank}
			for key in tomes: run.ranks[key] = tomes[key]
			for enemy in run.enemies: enemy.queue_free()
			run.enemies.clear()
			var count = 60 if target == "crowd" else 1
			for i in range(count):
				var enemy = run.spawn_enemy("tank" if target == "crowd" else "boss", target == "single")
				enemy.position = run.player.position + (Vector2.RIGHT.rotated(i * 2.39996) * (40 + sqrt(i) * 22) if target == "crowd" else Vector2(70, 0))
				enemy.max_hp = 1.0e12
				enemy.hp = 1.0e12
				enemy.set_physics_process(false)
			# Fire trails need movement: walk a small circle for trail weapons.
			var ticks = int(SECONDS * 30)
			for tick in range(ticks):
				run.pending_levels = 0
				run.pending_treasures = 0
				if weapon == "fire":
					run.player.global_position = Vector2(cos(tick * 0.05), sin(tick * 0.05)) * 50
				run._physics_process(1.0 / 30)
				for child in run.get_children():
					if child is Shot and child.is_processing():
						child._physics_process(1.0 / 30)
					elif child is Shot:
						child.set_physics_process(false)
						child._physics_process(1.0 / 30)
				if tick % 4 == 0: await process_frame
			var total = 0.0
			for source in run.damage_totals: total += run.damage_totals[source]
			print("BENCH weapon=%s rank=%d target=%s dps=%.0f" % [weapon, rank, target, total / SECONDS])
			run.queue_free()
			await process_frame
	quit()
