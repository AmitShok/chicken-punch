extends RefCounted

static var icon_cache: Dictionary = {}
static var save_path = "user://coop_save.cfg"
const MAX_RANK = 10
const MAX_ITEM_LEVEL = 10
const PACK = "res://assets/Ninja Adventure - Asset Pack/"

# Weapons, tomes, items and defenders live in res://resources/catalog/ as
# EquipmentDef / ItemDef / CharacterDef resources, listed in catalog.tres.
# The tables below are built from them in the original shapes, so existing
# code keeps working. Prefer equipment_def() / item_def() / character_def()
# in new code.
static var CATALOG = load("res://resources/catalog.tres")
# Key -> [name, description, art path, max rank]
static var UPGRADES: Dictionary = build_upgrades()
static var WEAPONS: Array = CATALOG.equipment.filter(func(d): return d.kind == 0).map(func(d): return d.key)
# Key -> [name, description, icon path, rarity]
static var ITEMS: Dictionary = build_items()
# Weapon key -> [evolution tome key, evolved name]
static var EVOLUTIONS: Dictionary = build_evolutions()
static var EVOLUTION_EFFECTS: Dictionary = build_evolution_effects()
static var STARTER_EQUIPMENT: Array = CATALOG.equipment.filter(func(d): return d.starter).map(func(d): return d.key)
static var STARTER_ITEMS: Array = CATALOG.items.filter(func(d): return d.starter).map(func(d): return d.key)
# Key -> [name, starting weapon, sprite sheet path ("" = original chicken), flavor]
static var CHARACTERS: Dictionary = build_characters()
# Explicit sheet geometry and facing; animal sheets do not share one layout.
static var CHARACTER_VISUALS: Dictionary = build_character_visuals()
static var CHARACTER_COSTS: Dictionary = build_character_field("unlock_gold")
static var CHARACTER_QUESTS: Dictionary = build_character_field("unlock_quest")

static func equipment_def(key: String) -> Resource:
	for def in CATALOG.equipment:
		if def.key == key: return def
	return null

static func item_def(key: String) -> Resource:
	for def in CATALOG.items:
		if def.key == key: return def
	return null

static func character_def(key: String) -> Resource:
	for def in CATALOG.characters:
		if def.key == key: return def
	return null

static func build_upgrades() -> Dictionary:
	var table = {}
	for def in CATALOG.equipment:
		table[def.key] = [def.display_name, def.description, def.art.resource_path, def.max_rank]
	return table

static func build_items() -> Dictionary:
	var table = {}
	for def in CATALOG.items:
		table[def.key] = [def.display_name, def.description, def.icon.resource_path, def.rarity]
	return table

static func build_evolutions() -> Dictionary:
	var table = {}
	for def in CATALOG.equipment:
		if def.evolution_tome != "": table[def.key] = [def.evolution_tome, def.evolution_name]
	return table

static func build_evolution_effects() -> Dictionary:
	var table = {}
	for def in CATALOG.equipment:
		if def.evolution_tome != "": table[def.key] = def.evolution_effect
	return table

static func build_characters() -> Dictionary:
	var table = {}
	for def in CATALOG.characters:
		table[def.key] = [def.display_name, def.starting_weapon, def.sprite_sheet.resource_path if def.sprite_sheet else "", def.flavor]
	return table

static func build_character_visuals() -> Dictionary:
	var table = {}
	for def in CATALOG.characters:
		table[def.key] = {"cell": def.cell, "faces_left": def.faces_left}
	return table

static func build_character_field(field: String) -> Dictionary:
	var table = {}
	for def in CATALOG.characters:
		table[def.key] = def.get(field)
	return table

static func character_icon(key: String) -> Texture2D:
	var path = CHARACTERS[key][2]
	var atlas = AtlasTexture.new()
	atlas.atlas = load(path if path != "" else "res://assets/ChickenPack/SpriteSheet/ChickenIdle-Sheet.png")
	atlas.region = Rect2(Vector2.ZERO, Vector2(CHARACTER_VISUALS[key].cell))
	return atlas

const WEAPON_SLOTS = 4
const TOME_SLOTS = 4
const RARITIES = ["COMMON", "RARE", "EPIC"]
const RARITY_COLORS = [Color("92713a"), Color("39754e"), Color("8b4a9b")]
# Treasure items are distinct from level-up tomes. Each stacks up to ten times.
const SYNERGIES = {
	"cold": ["Cold Conductor", "frost", "thunder", false, "Lightning deals 35% more damage to chilled targets and jumps 60% farther from them."],
	"steam": ["Steam Engine", "fire", "frost", false, "Fire hitting a chilled enemy consumes the slow and erupts into a steam blast. 3s cooldown per enemy."],
	"reaper": ["Reaper's Feast", "sickle", "blood_seed", true, "A returning sickle that hits enemies heals 1 HP per hit, up to 2, multiplied by Crimson Seed stacks."],
	"cluster": ["Cluster Nest", "shell", "powder", true, "Shell explosions release six piercing fragments, each dealing 20% of the shell's damage."],
	"wake": ["Iron Wake", "orbit", "bead", true, "Using your ability releases a protective blast for 12 damage per Iron Bead stack, scaled by damage bonuses."]
}
# Two evolved weapons, two maxed matching tomes, a three-stack item, two guardian kills, then a chest.
const ASCENSIONS = {
	"whiteout": ["Absolute Zero", "thunder", "frost", "crit", "duration", "lens", "Storm Call and Frost Quills deal triple damage and cast twice as fast. Lightning reaches 12 extra targets; ice volleys gain 6 shards."],
	"henpocalypse": ["Henpocalypse", "egg", "fire", "haste", "area", "powder", "Egg Barrage and Hot Foot deal triple damage and cast twice as fast. Volleys gain 8 eggs; egg explosions gain 80% radius."],
	"reaping": ["The Last Harvest", "sickle", "orbit", "magnet", "armor", "blood_seed", "Harvest Moon and Coop Guard deal triple damage. Four sickles launch in all directions twice as often; 8 extra blades orbit at double speed."]
}

# Music by phase of a run. Edit these to swap tracks; all come from the Ninja Adventure pack.
const MUSIC = {
	"menu": "33 - Calm Village.ogg",
	"meadow": "35 - Adventure.ogg",
	"orchard": "23 - Road.ogg",
	"pasture": "37 - Dark Forest.ogg",
	"mid": "17 - Fight.ogg",
	"late": "28 - Tension.ogg",
	"guardian": "34  - Fight.ogg",
	"final": "24 - Final Area.ogg",
	"victory": "19 - Ascension.ogg",
	"defeat": "29 - Lament.ogg"
}

static func music_stream(key: String) -> AudioStream:
	return load(PACK + "Audio/Musics/" + MUSIC[key])

static func ensure_audio_buses():
	for name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, name)

const LEVELS = {
	"meadow": {"name": "Coop Meadow", "description": "The original farm. Hedges, open grass and room to dodge.", "best": 0, "tint": Color("e6ebf0"), "pressure": 1.0},
	"orchard": {"name": "Amber Orchard", "description": "Tree-lined lanes. More bats, closer cover and faster waves.", "best": 180, "tint": Color("ffe2b5"), "pressure": 1.12},
	"pasture": {"name": "Moonlit Pasture", "description": "Rocky rings under a blue moon. Casters arrive earlier.", "best": 360, "tint": Color("b8d5ed"), "pressure": 1.24}
}
const DIFFICULTIES = [
	{"name": "I · Standard", "power": 1.0, "reward": 1.0, "description": "Normal enemy strength. 1x gold."},
	{"name": "II · Ferocious", "power": 1.35, "reward": 1.3, "description": "35% more enemy HP, stronger hits. 1.3x gold."},
	{"name": "III · Nightmare", "power": 1.8, "reward": 1.6, "description": "80% more enemy HP, stronger hits. 1.6x gold."}
]

static func equipment_owned(data: Dictionary, key: String, item: bool = false) -> bool:
	if item: return key in STARTER_ITEMS or key in data.get("item_unlocks", [])
	if key in STARTER_EQUIPMENT or key in data.get("equipment_unlocks", []): return true
	for character in data.get("unlocked", ["nugget"]):
		if CHARACTERS.has(character) and CHARACTERS[character][1] == key: return true
	return false

# Quests gate everything that is not a starter, as in Megabonk: finish the
# task, then buy access with gold. id -> [text, stat, target]. Progress is read
# from lifetime stats in the save, so quests can never fall out of sync.
const QUESTS = {
	"survive_3": ["Survive 3:00 in one run", "best_time", 180],
	"survive_5": ["Survive 5:00 in one run", "best_time", 300],
	"level_15": ["Reach level 15 in one run", "best_level", 15],
	"level_20": ["Reach level 20 in one run", "best_level", 20],
	"level_25": ["Reach level 25 in one run", "best_level", 25],
	"kills_500": ["Defeat 500 enemies in total", "kills", 500],
	"kills_1000": ["Defeat 1,000 enemies in total", "kills", 1000],
	"kills_2500": ["Defeat 2,500 enemies in total", "kills", 2500],
	"kills_5000": ["Defeat 5,000 enemies in total", "kills", 5000],
	"chests_10": ["Open 10 chests in total", "chests", 10],
	"chests_25": ["Open 25 chests in total", "chests", 25],
	"ability_50": ["Use your ability 50 times in one run", "best_dashes", 50],
	"max_rank": ["Raise any weapon to rank 10 in one run", "best_rank", 10],
	"guardian_1": ["Defeat a guardian", "best_guardians", 1],
	"guardian_2": ["Defeat two guardians in one run", "best_guardians", 2],
	"guardians_6": ["Defeat 6 guardians in total", "guardians", 6],
	"evolve": ["Evolve a weapon", "evolutions", 1],
	"evolve_fire": ["Evolve Hot Foot into Phoenix Trail", "evolved_fire", 1],
	"dash_100": ["Use your ability 100 times in one run", "best_dashes", 100],
	"low_hp_60": ["Spend 60 seconds below half health in one run", "best_low_hp", 60],
	"win": ["Win a run", "wins", 1],
	"crit_10": ["Raise Keen Eye to rank 10 in one run", "best_crit", 10],
	"wins_3": ["Win 3 runs", "wins", 3],
	"win_ferocious": ["Win a run on Ferocious or harder", "best_tier_won", 2]
}
# Completed-quest counts that each grant one more use per run of a build tool.
const MILESTONES = [[2, "reroll"], [4, "skip"], [5, "banish"], [8, "reroll"], [10, "banish"], [12, "skip"], [14, "reroll"], [16, "banish"]]
const BASE_TOOLS = {"reroll": 1, "skip": 0, "banish": 0}
const STAT_KEYS = ["best_time", "best_level", "best_guardians", "best_rank", "best_crit", "best_dashes", "best_low_hp", "best_tier_won", "kills", "chests", "guardians", "evolutions", "evolved_fire", "wins", "runs"]

static func stat(data: Dictionary, key: String) -> int:
	var value = int(data.get("stats", {}).get(key, 0))
	# Best time and wins also live at the top level of the save.
	if key == "best_time": value = maxi(value, int(data.get("best", 0)))
	if key == "wins": value = maxi(value, int(data.get("wins", 0)))
	return value

static func quest_done(data: Dictionary, id: String) -> bool:
	return id == "" or (QUESTS.has(id) and stat(data, QUESTS[id][1]) >= QUESTS[id][2])

static func quest_progress(data: Dictionary, id: String) -> String:
	if id == "": return ""
	var rule = QUESTS[id]
	var value = mini(stat(data, rule[1]), rule[2])
	if rule[1] == "best_time": return "%d:%02d / %d:%02d" % [value / 60, value % 60, rule[2] / 60, rule[2] % 60]
	return "%d / %d" % [value, rule[2]]

static func quests_completed(data: Dictionary) -> int:
	return QUESTS.keys().filter(func(id): return quest_done(data, id)).size()

static func tool_uses(data: Dictionary, tool: String) -> int:
	var done = quests_completed(data)
	return BASE_TOOLS[tool] + MILESTONES.filter(func(m): return m[1] == tool and done >= m[0]).size()

static func unlock_quest(key: String, item: bool = false) -> String:
	return item_def(key).unlock_quest if item else equipment_def(key).unlock_quest

static func unlock_cost(key: String, item: bool = false) -> int:
	return item_def(key).unlock_gold if item else equipment_def(key).unlock_gold

# Folds one finished run into lifetime stats and returns newly completed quests.
static func record_run(data: Dictionary, run: Dictionary) -> Array:
	var before = QUESTS.keys().filter(func(id): return quest_done(data, id))
	var stats: Dictionary = data.get("stats", {})
	for key in ["kills", "chests", "guardians", "evolutions", "evolved_fire", "wins", "runs"]:
		stats[key] = int(stats.get(key, 0)) + int(run.get(key, 0))
	for key in ["best_time", "best_level", "best_guardians", "best_rank", "best_crit", "best_dashes", "best_low_hp", "best_tier_won"]:
		stats[key] = maxi(int(stats.get(key, 0)), int(run.get(key, 0)))
	data.stats = stats
	data.best = stats.best_time
	return QUESTS.keys().filter(func(id): return quest_done(data, id) and not before.has(id))

# Developer shortcuts for the hidden F12 page (debug builds only). Each one
# edits the save the same way normal play would, then writes it.
static func dev_grant(data: Dictionary, action: String) -> void:
	match action:
		"quests":
			for id in QUESTS:
				data.stats[QUESTS[id][1]] = maxi(stat(data, QUESTS[id][1]), QUESTS[id][2])
			data.best = data.stats.best_time
			data.wins = maxi(data.wins, data.stats.wins)
		"next_quest":
			for id in QUESTS:
				if not quest_done(data, id):
					data.stats[QUESTS[id][1]] = QUESTS[id][2]
					data.best = maxi(data.best, data.stats.best_time)
					break
		"gold":
			data.gold += 1000
		"unlock_all":
			data.equipment_unlocks = UPGRADES.keys()
			data.item_unlocks = ITEMS.keys()
			data.unlocked = CHARACTERS.keys()
		"training":
			for key in CHARACTERS:
				data.training[key] = {"power": 5, "heart": 5, "weapon_slots": 4, "tome_slots": 4}
		"levels":
			data.best = maxi(data.best, 600)
			data.stats.best_time = data.best
			for level in LEVELS:
				data.level_clears[level] = DIFFICULTIES.size()
		"reset":
			var keep = {"muted": data.muted, "sfx_volume": data.sfx_volume, "music_volume": data.music_volume, "combat_feedback": data.combat_feedback}
			data.clear()
			write_save(keep)
			data.merge(read_save())
			return
	write_save(data)

static func purchase_access(data: Dictionary, key: String, item: bool = false) -> bool:
	if not (ITEMS if item else UPGRADES).has(key): return false
	if equipment_owned(data, key, item) or not quest_done(data, unlock_quest(key, item)) or data.gold < unlock_cost(key, item): return false
	data.gold -= unlock_cost(key, item)
	var field = "item_unlocks" if item else "equipment_unlocks"
	if not data.has(field): data[field] = []
	data[field].append(key)
	write_save(data)
	return true

static func level_available(data: Dictionary, key: String) -> bool:
	return LEVELS.has(key) and data.best >= LEVELS[key].best

static func difficulty_available(data: Dictionary, level: String, tier: int) -> bool:
	return tier >= 0 and tier < DIFFICULTIES.size() and (tier == 0 or int(data.get("level_clears", {}).get(level, 0)) >= tier)

static func training(data: Dictionary, character: String = "") -> Dictionary:
	return data.training[character if character != "" else data.character]

static func slot_limit(data: Dictionary, weapons: bool) -> int:
	return training(data)["weapon_slots" if weapons else "tome_slots"]

static func read_save() -> Dictionary:
	var config = ConfigFile.new()
	config.load(save_path)
	if OS.has_feature("web"):
		var stored = JavaScriptBridge.eval("(function(){try{return localStorage.getItem(" + JSON.stringify("chickenpunch:" + save_path) + ");}catch(e){return null;}})()")
		if stored is String:
			var browser_config = ConfigFile.new()
			if browser_config.parse(stored) == OK:
				config = browser_config
	var data = {"character": str(config.get_value("coop", "character", "nugget")), "gold": maxi(0, int(config.get_value("coop", "gold", config.get_value("coop", "coins", 0)))), "power": clampi(int(config.get_value("coop", "power", 0)), 0, 5), "heart": clampi(int(config.get_value("coop", "heart", 0)), 0, 5), "best": maxi(0, int(config.get_value("coop", "best", 0))), "wins": maxi(0, int(config.get_value("coop", "wins", 0))), "combat_feedback": bool(config.get_value("coop", "combat_feedback", true)), "muted": bool(config.get_value("coop", "muted", false)), "sfx_volume": clampf(float(config.get_value("coop", "sfx_volume", 0.8)), 0, 1), "music_volume": clampf(float(config.get_value("coop", "music_volume", 0.6)), 0, 1)}

	if not CHARACTERS.has(data.character): data.character = "nugget"
	var unlocked = config.get_value("coop", "unlocked", ["nugget", data.character])
	data.unlocked = ["nugget"]
	if unlocked is Array:
		for key in unlocked:
			if CHARACTERS.has(key) and not data.unlocked.has(key): data.unlocked.append(key)
	if not data.unlocked.has(data.character): data.character = "nugget"
	var tracks = config.get_value("coop", "training", {})
	data.training = {}
	for key in CHARACTERS:
		var track = tracks.get(key, {}) if tracks is Dictionary else {}
		if not track is Dictionary: track = {}
		data.training[key] = {"power": clampi(int(track.get("power", data.power)), 0, 5), "heart": clampi(int(track.get("heart", data.heart)), 0, 5), "weapon_slots": clampi(int(track.get("weapon_slots", 2)), 2, 4), "tome_slots": clampi(int(track.get("tome_slots", 2)), 2, 4)}
	for entry in [["equipment_unlocks", UPGRADES], ["item_unlocks", ITEMS]]:
		data[entry[0]] = []
		var owned = config.get_value("coop", entry[0], [])
		if owned is Array:
			for key in owned:
				if entry[1].has(key) and not data[entry[0]].has(key): data[entry[0]].append(key)
	# Lifetime stats drive quests. Older saves seed them from best time and wins.
	var stored_stats = config.get_value("coop", "stats", {})
	data.stats = {}
	for key in STAT_KEYS:
		data.stats[key] = maxi(0, int(stored_stats.get(key, 0))) if stored_stats is Dictionary else 0
	data.stats.best_time = maxi(data.stats.best_time, data.best)
	data.stats.wins = maxi(data.stats.wins, data.wins)
	data.best = data.stats.best_time
	var clears = config.get_value("coop", "level_clears", {"meadow": 1 if data.wins > 0 else 0})
	data.level_clears = {}
	for level in LEVELS:
		data.level_clears[level] = clampi(int(clears.get(level, 0)), 0, 3) if clears is Dictionary else 0
	return data

static func write_save(data: Dictionary) -> void:
	var config = ConfigFile.new()
	# Old saves called the permanent balance coins. Migrate it once to gold.
	for key in data:
		if key != "coins":
			config.set_value("coop", key, data[key])
	config.set_value("coop", "gold", maxi(0, int(data.get("gold", data.get("coins", 0)))))
	var error = config.save(save_path)
	if error != OK:
		push_warning("Could not save coop progression: " + str(error))
	if OS.has_feature("web"):
		# The web filesystem flushes asynchronously. Mirror the save synchronously
		# so refreshing immediately after a purchase or run cannot lose progress.
		var persisted = JavaScriptBridge.eval("(function(){try{localStorage.setItem(" + JSON.stringify("chickenpunch:" + save_path) + "," + JSON.stringify(config.encode_to_text()) + ");return true;}catch(e){return false;}})()")
		if persisted != true:
			push_warning("Browser storage is unavailable; progression may not survive a reload.")



static func icon(key: String, item: bool = false, evolved: bool = false) -> Texture2D:
	var cache_key = key + str(item) + str(evolved)
	if not icon_cache.has(cache_key): icon_cache[cache_key] = load_icon(key, item, evolved)
	return icon_cache[cache_key]


static func load_icon(key: String, item: bool = false, evolved: bool = false) -> Texture2D:
	if item: return item_def(key).icon
	var def = equipment_def(key)
	return def.evolved_icon if evolved and def.evolved_icon else def.icon
