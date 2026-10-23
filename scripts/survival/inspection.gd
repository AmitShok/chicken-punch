extends RefCounted
const Data = preload("res://scripts/survival/data.gd")

static func describe(run: Node, key: String, item: bool) -> String:
	var count = run.items.get(key, 0) if item else run.ranks.get(key, 0)
	var info = Data.ITEMS[key] if item else Data.UPGRADES[key]
	var text = ("ITEM  /  %d levels of 10" if item else "WEAPON  /  Rank %d of 10" if key in Data.WEAPONS else "TOME  /  Rank %d of 10") % count
	text += "\n\n" + info[1] + "\n\nCURRENT EFFECT\n"
	if item:
		text += item_effect(run, key, count)
	elif key in Data.WEAPONS:
		text += weapon_effect(run, key, count)
		text += "\nProjectile / orbit speed x%.2f. Weapon size / hit radius x%.2f." % [run.projectile_speed_multiplier(),run.weapon_size_multiplier()]
		text += "\nDamage shown includes current damage bonuses and Ascension, before critical hits, target bonuses, armor, or splash."
		text += "\n\nDAMAGE DEALT: %d" % run.damage_totals.get(key, 0)
		var recipe = Data.EVOLUTIONS[key]
		text += "\n\n" + ("EVOLVED: " if run.evolved.has(key) else "EVOLUTION: ") + recipe[1]
		text += "\n" + Data.EVOLUTION_EFFECTS[key]
		if not run.evolved.has(key):
			text += "\nNeeds this weapon rank 10 + %s rank 1 + chest.\nProgress: weapon %d/10, tome %d/1." % [Data.UPGRADES[recipe[0]][0], count, mini(1,run.ranks.get(recipe[0],0))]
	else:
		match key:
			"projectile_speed": text += "+%d%% projectile travel and orbit rotation speed. Instant lightning and stationary fire do not travel." % (count*20)
			"projectile_count": text += "+%d shots, sickles, orbit blades or lightning targets (Storm Call rank 2+). Hot Foot spacing is divided by (1 + bonus), creating a denser trail. Picks grant +1 / +2 / +3 by rarity, capped at +10 total." % count
			"projectile_size": text += "+%d%% sprite scale and hit radius. Also affects fire, explosion radii and lightning reach. Multiplies with Wide Wings for area effects." % (count*20)
			"might": text += "+%d%% damage to all weapons." % (count*20)
			"haste": text += "Weapon cooldowns multiplied by %.3f (%d%% shorter)." % [pow(0.9,count),roundi((1-pow(0.9,count))*100)]
			"area": text += "+%d%% area scale." % (count*18)
			"speed": text += "+%d%% movement speed." % (count*8)
			"armor": text += "Reduce each incoming hit by %d. Minimum hit damage is 1." % count
			"magnet": text += "+%d pickup radius and +%d%% XP." % [count*30,count*10]
			"vitality": text += "+%d maximum HP. Each rank heals 20 when taken." % (count*20)
			"regen": text += "Regenerate %.1f HP per second." % (count*0.4)
			"crit": text += "+%d percentage points critical chance. Total chance: %d%% (85%% cap)." % [count*8, roundi(run.critical_chance()*100)]
			"duration": text += "+%d%% effect duration. Lingering fire stays active longer and icy slows wear off later. Applies to Hot Foot / Phoenix Trail fire patches and Frost Quills / Deep Winter slows. Rank 10 triples their duration." % (count*20)
		for weapon in Data.EVOLUTIONS:
			if Data.EVOLUTIONS[weapon][0] == key:
				text += "\n\nEVOLUTION PARTNER\n" + Data.UPGRADES[weapon][0] + " rank 10 + this tome rank 1 + chest = " + Data.EVOLUTIONS[weapon][1]
	for id in Data.SYNERGIES:
		var rule = Data.SYNERGIES[id]
		if (item and rule[3] and rule[2] == key) or (not item and (rule[1] == key or (not rule[3] and rule[2] == key))):
			text += "\n\n" + ("ACTIVE SYNERGY: " if run.synergy_active(id) else "SYNERGY: ") + rule[0] + "\n" + Data.UPGRADES[rule[1]][0] + " + " + (Data.ITEMS[rule[2]][0] if rule[3] else Data.UPGRADES[rule[2]][0]) + "\n" + rule[4]
	for id in Data.ASCENSIONS:
		var rule = Data.ASCENSIONS[id]
		if (item and key == rule[5]) or (not item and key in [rule[1],rule[2],rule[3],rule[4]]):
			text += "\n\nASCENSION: " + rule[0] + "\n" + run.ascension_progress(id)
	return text

static func item_effect(run: Node, key: String, n: int) -> String:
	match key:
		"key": return "%.1f%% free-opening chance on paid chests. You must afford the displayed price first. A free opening does not raise the next price. Elite chests are always free." % (run.key_chance()*100)
		"clover": return "+%d percentage points rare-or-better upgrade chance. Rare and Epic chest-item draw weights increase by %d%% relative to Common." % [n*6,n*25]
		"lens": return "+%d percentage points critical chance. Total: %d%% (85%% cap); critical hits deal 2x damage." % [n*8,roundi(run.critical_chance()*100)]
		"honey": return "Regenerate %.1f HP per second." % (n*0.3)
		"lunch": return "Opening a chest heals %d HP, up to maximum health." % (n*12)
		"magnet_stone": return "+%d pickup radius." % (n*25)
		"powder": return "Every eighth kill explodes for %.1f damage with current damage bonuses. Next trigger in %d kills." % [20*n*run.power(),8-run.kills%8]
		"blood_seed": return "Every fifteenth kill heals %d HP. Next trigger in %d kills." % [3*n,15-run.kills%15]
		"berserk": return "+%d%% damage below 50%% HP. Currently %s." % [25*n,"ACTIVE" if run.player.hp < run.player.max_hp*0.5 else "inactive"]
		"silk": return "Dash cooldown multiplied by %.3f. Current cooldown: %.2fs." % [pow(0.85,n),run.dash_recharge()]
		"crown": return "+%d%% damage to elites and guardians." % (20*n)
		"compass": return "+%d%% XP." % (12*n)
		"bead": return "+%d armor. Total armor: %d." % [n,run.armor_value()]
	return ""

static func weapon_effect(run: Node, key: String, rank: int) -> String:
	var power = run.power() * run.ascension_damage(key)
	var cooldown = pow(0.9,run.ranks.get("haste",0)) * run.ascension_cooldown(key)
	var evolved = run.evolved.has(key)
	var extra = run.projectile_bonus()
	match key:
		"egg": return "%d eggs per volley. %.1f damage per hit. Volley every %.2fs.%s" % [rank+(3 if evolved else 0)+(8 if run.ascension=="henpocalypse" else 0)+extra,(10+rank*4)*power,0.85*cooldown," Splash deals 60% hit damage." if evolved else ""]
		"shuriken": return "%d blades per fan; %d pierce. %.1f damage per hit. Fan every %.2fs." % [rank+2+(3 if evolved else 0)+extra,rank+2,(10+rank*4)*power,1.6*cooldown]
		"fire": return "%.1f damage per tick (every 0.4s). Trail spacing %.1f pixels; stationary patch every %.2fs. Patches last %.2fs. Radius %.1f." % [(4+rank*3)*power,run.fire_spacing(),run.fire_spacing()/100.0,(2+rank*0.5)*run.duration_multiplier(),17*run.area_multiplier()*run.weapon_size_multiplier()*(1.6 if evolved else 1)]
		"orbit": return "%d orbiting blades. %.1f damage per contact check (every %.2fs)." % [1+int(rank/2)+(2 if evolved else 0)+(8 if run.ascension=="reaping" else 0)+extra,(5+rank*3)*power,0.22*pow(0.9,run.ranks.get("haste",0))]
		"thunder": return "%d targets per cast. %.1f damage per strike. Cast every %.2fs." % [run.storm_target_count(rank),(14+rank*6)*power,2*cooldown]
		"frost": return "%d shards; %d pierce. %.1f damage per hit. Cast every %.2fs. Slows by %d%% for %.2fs." % [1+int(rank/2)+(2 if evolved else 0)+(6 if run.ascension=="whiteout" else 0)+extra,2+rank,(9+rank*4)*power,1.35*cooldown,70 if evolved else 45,(3.5 if evolved else 2)*run.duration_multiplier()]
		"sickle": return "%d returning sickles. %.1f damage per hit. Cast every %.2fs. Can hit each enemy once outbound and once returning." % [(4 if run.ascension=="reaping" else 2 if evolved else 1)+extra,(14+rank*6)*power,1.8*cooldown]
		"shell": return "%d shells per volley. %.1f damage per explosion. Radius %.1f. Launch every %.2fs." % [1+extra,(22+rank*9)*power,(26+rank*3)*run.area_multiplier()*run.weapon_size_multiplier()*(1.45 if evolved else 1),2.3*cooldown]
	return ""
