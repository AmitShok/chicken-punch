extends RefCounted

static var icon_cache: Dictionary = {}
static var save_path = "user://coop_save.cfg"
const MAX_RANK = 10
const MAX_ITEM_LEVEL = 10
const PACK = "res://assets/Ninja Adventure - Asset Pack/"
# Name, starting weapon, sprite sheet (empty = original chicken), flavor.
const CHARACTERS = {
	"nugget": ["Nugget", "egg", "", "The original coop defender. A steady spread of eggs."],
	"pepper": ["Pepper", "fire", PACK + "Actor/Animals/Chicken/SpriteSheetBlack.png", "A hot-tempered hen. Leave burning trails for the horde."],
	"whisker": ["Whisker", "sickle", PACK + "Actor/Animals/Cat/SpriteSheet.png", "The barn's night watch. Catch enemies on the sickle's return."],
	"truffle": ["Truffle", "shell", PACK + "Actor/Animals/Pig/SpriteSheetPink.png", "A fearless farm pig. Break up crowds with explosive shells."],
	"clover": ["Clover", "orbit", PACK + "Actor/Animals/Cow/SpriteSheetWhiteSide.png", "The pasture protector. Orbiting blades guard close quarters."]
}

# Explicit sheet geometry and facing; animal sheets do not share one layout.
const CHARACTER_VISUALS = {
	"nugget": {"cell": Vector2i(20, 21), "faces_left": false},
	"pepper": {"cell": Vector2i(16, 16), "faces_left": false},
	"whisker": {"cell": Vector2i(16, 16), "faces_left": false},
	"truffle": {"cell": Vector2i(16, 16), "faces_left": true},
	"clover": {"cell": Vector2i(24, 16), "faces_left": true}
}

static func character_icon(key: String) -> Texture2D:
	var path = CHARACTERS[key][2]
	var atlas = AtlasTexture.new()
	atlas.atlas = load(path if path != "" else "res://assets/ChickenPack/SpriteSheet/ChickenIdle-Sheet.png")
	atlas.region = Rect2(Vector2.ZERO, Vector2(CHARACTER_VISUALS[key].cell))
	return atlas

const UPGRADES = {
	"projectile_speed": ["Tailwind", "+20% projectile travel speed and orbit rotation speed per rank.", PACK + "Items/Resource/feather.png", MAX_RANK],
	"projectile_count": ["Brood Burst", "Extra shots, blades and chain targets; denser fire trails. +1 / +2 / +3 by rarity.", PACK + "Items/Food/Seed3.png", MAX_RANK],
	"projectile_size": ["Giant Hatch", "+20% weapon size and hit radius per rank. Also enlarges explosions, fire and lightning reach.", PACK + "Items/Resource/BarMithril.png", MAX_RANK],
	"egg": ["Egg Barrage", "Another egg per volley; +4 damage.", "res://assets/sprites/egg_sprite.png", MAX_RANK],
	"shuriken": ["Razor Feathers", "Piercing fans of shuriken. More blades per rank.", PACK + "FX/Projectile/Shuriken.png", MAX_RANK],
	"fire": ["Hot Foot", "Leave burning ground behind you. More damage and duration. Overlapping flames do not stack.", PACK + "Items/Scroll/ScrollFire.png", MAX_RANK],
	"orbit": ["Coop Guard", "Orbiting blades protect your personal space.", PACK + "Items/Weapons/Sai/Sprite.png", MAX_RANK],
	"might": ["Fighting Spirit", "DAMAGE: +20% damage to every weapon per rank.", PACK + "Items/Weapons/Sword/Sprite.png", MAX_RANK],
	"haste": ["Quick Hatch", "RELOAD SPEED: 10% shorter attack cooldown per rank. Evolves Egg Barrage.", PACK + "Items/Object/Hourglass.png", MAX_RANK],
	"area": ["Wide Wings", "+18% area. Fire rank 10 + this tome + chest evolves Fire.", PACK + "Items/Object/Book.png", MAX_RANK],
	"speed": ["Fleet Feet", "+8% movement speed. Shuriken rank 10 + this tome + chest evolves Shuriken.", PACK + "Items/Food/Seed1.png", MAX_RANK],
	"armor": ["Iron Shell", "Reduce incoming damage by 1. Guard rank 10 + this tome + chest evolves Guard.", PACK + "Items/Potion/MilkPot.png", MAX_RANK],
	"magnet": ["Forager", "+30 pickup radius and +10% XP.", PACK + "Items/Object/Bag.png", MAX_RANK],
	"vitality": ["Big Heart", "+20 maximum health and heal 20.", PACK + "Items/Potion/Heart.png", MAX_RANK],
	"thunder": ["Storm Call", "Strikes one enemy at rank 1. Each rank adds damage; chaining starts at rank 2 with one extra target per rank.", PACK + "Items/Scroll/ScrollThunder.png", MAX_RANK],
	"frost": ["Frost Quills", "Piercing ice shards slow enemies by 45% for 2 seconds.", PACK + "Items/Scroll/ScrollIce.png", MAX_RANK],
	"sickle": ["Harvest Moon", "A spinning sickle returns to you, hitting again on its way back.", PACK + "Items/Tool/Sickle.png", MAX_RANK],
	"shell": ["Shell Shock", "Launch explosive shells at the nearest enemy.", PACK + "Items/Resource/Rock.png", MAX_RANK],
	"crit": ["Keen Eye", "+8% critical chance. Critical hits deal 2x damage; chance above 100% rolls 4x overcrits.", PACK + "Items/Resource/GemYellow.png", MAX_RANK],
	"duration": ["Long Summer", "Extends the duration of effects such as lingering fire and icy slows by 20% per rank.", PACK + "Items/Scroll/ScrollPlant.png", MAX_RANK],
	"regen": ["Second Wind", "Recover 0.4 health per second.", PACK + "Items/Potion/LifePot.png", MAX_RANK]
}
const WEAPONS = ["egg", "shuriken", "fire", "orbit", "thunder", "frost", "sickle", "shell"]
const WEAPON_SLOTS = 4
const TOME_SLOTS = 4
const RARITIES = ["COMMON", "RARE", "EPIC"]
const RARITY_COLORS = [Color("92713a"), Color("39754e"), Color("8b4a9b")]
# Treasure items are distinct from level-up tomes. Each stacks up to ten times.
const ITEMS = {
	"key": ["Coop Key", "Chance to open paid chests for free without raising prices: stacks / (stacks + 10).", PACK + "Items/Treasure/GoldKey.png", 0],
	"clover": ["Lucky Seed", "+6% rare-upgrade chance per stack; improves rare chest loot odds.", PACK + "Items/Food/Seed3.png", 0],
	"lens": ["Hawk Eye", "+8% critical chance per stack. Critical hits deal 2x damage; chance above 100% rolls 4x overcrits.", PACK + "Items/Resource/GemYellow.png", 1],
	"honey": ["Wild Honey", "Regenerate 0.3 health per second per stack.", PACK + "Items/Food/Honey.png", 0],
	"lunch": ["Packed Lunch", "Heal 12 health per stack whenever you open a chest.", PACK + "Items/Food/Onigiri.png", 0],
	"magnet_stone": ["Lodestone", "+25 pickup radius per stack.", PACK + "Items/Resource/BarMithril.png", 0],
	"powder": ["Blast Powder", "Every 8th kill explodes for 20 damage per stack.", PACK + "Items/Resource/Rock.png", 2],
	"blood_seed": ["Crimson Seed", "Every 15 kills, heal 3 health per stack.", PACK + "Items/Resource/GemRed.png", 1],
	"berserk": ["Red Feather", "+25% damage per stack while below half health.", PACK + "Items/Resource/feather.png", 1],
	"silk": ["Wind Charm", "Dash recharges 15% faster per stack.", PACK + "Items/Object/PanFlute.png", 1],
	"crown": ["Giant Slayer", "+20% damage to elites and guardians per stack.", PACK + "Items/Resource/BarGold.png", 2],
	"compass": ["Field Notes", "+12% experience per stack.", PACK + "Items/Other/Letter.png", 0],
	"bead": ["Iron Bead", "+1 armor per stack.", PACK + "Items/Resource/BarIron.png", 0]
}
const EVOLUTION_EFFECTS = {
	"egg": "Three extra eggs in every volley. Every hit now deals splash damage.",
	"shuriken": "Three additional piercing blades in every fan.",
	"fire": "Burning patches become 60% larger, covering more ground.",
	"orbit": "Two additional orbiting blades protect your chicken.",
	"thunder": "Lightning can jump to three additional enemies per cast.",
	"frost": "Two additional ice shards. Slow becomes 70% and lasts 3.5 seconds before tome bonuses.",
	"sickle": "Throw a second returning sickle in the opposite direction.",
	"shell": "Explosions gain 45% more radius before area bonuses."
}
const SYNERGIES = {
	"cold": ["Cold Conductor", "frost", "thunder", false, "Lightning deals 35% more damage to chilled targets and jumps 60% farther from them."],
	"steam": ["Steam Engine", "fire", "frost", false, "Fire hitting a chilled enemy consumes the slow and erupts into a steam blast. 3s cooldown per enemy."],
	"reaper": ["Reaper's Feast", "sickle", "blood_seed", true, "A returning sickle that hits enemies heals 1 HP per hit, up to 2, multiplied by Crimson Seed stacks."],
	"cluster": ["Cluster Nest", "shell", "powder", true, "Shell explosions release six piercing fragments, each dealing 20% of the shell's damage."],
	"wake": ["Iron Wake", "orbit", "bead", true, "Dashing releases a protective blast for 12 damage per Iron Bead stack, scaled by damage bonuses."]
}
# Two evolved weapons, two maxed matching tomes, a three-stack item, two guardian kills, then a chest.
const ASCENSIONS = {
	"whiteout": ["Absolute Zero", "thunder", "frost", "crit", "duration", "lens", "Storm Call and Frost Quills deal triple damage and cast twice as fast. Lightning reaches 12 extra targets; ice volleys gain 6 shards."],
	"henpocalypse": ["Henpocalypse", "egg", "fire", "haste", "area", "powder", "Egg Barrage and Hot Foot deal triple damage and cast twice as fast. Volleys gain 8 eggs; egg explosions gain 80% radius."],
	"reaping": ["The Last Harvest", "sickle", "orbit", "magnet", "armor", "blood_seed", "Harvest Moon and Coop Guard deal triple damage. Four sickles launch in all directions twice as often; 8 extra blades orbit at double speed."]
}

const EVOLUTIONS = {"egg": ["haste", "Golden Omelette"], "shuriken": ["speed", "Featherstorm"], "fire": ["area", "Phoenix Trail"], "orbit": ["armor", "Iron Roost"], "thunder": ["crit", "Thunderhead"], "frost": ["duration", "Deep Winter"], "sickle": ["magnet", "Reaping Season"], "shell": ["might", "Meteor Nest"]}

const CHARACTER_COSTS = {"nugget": 0, "pepper": 40, "whisker": 60, "truffle": 90, "clover": 120}
const CHARACTER_MILESTONES = {"nugget": 0, "pepper": 60, "whisker": 120, "truffle": 180, "clover": 300}


# Permanent access is separate from the levels earned inside each run.
const STARTER_EQUIPMENT = ["egg", "shuriken", "might", "haste", "vitality", "speed"]
const STARTER_ITEMS = ["honey", "lunch", "bead"]
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

static func unlock_requirement(key: String, item: bool = false) -> int:
	if item: return [60, 120, 240][ITEMS[key][3]]
	return 120 if key in WEAPONS else 60

static func unlock_cost(key: String, item: bool = false) -> int:
	if item: return [25, 40, 60][ITEMS[key][3]]
	return 60 if key in WEAPONS else 35

static func purchase_access(data: Dictionary, key: String, item: bool = false) -> bool:
	if not (ITEMS if item else UPGRADES).has(key): return false
	if equipment_owned(data, key, item) or data.best < unlock_requirement(key, item) or data.gold < unlock_cost(key, item): return false
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
	if not item:
		if evolved and key in WEAPONS: return load("res://assets/Coop/evo_" + key + ".png")
		if key not in WEAPONS: return load("res://assets/Coop/tome_" + key + ".png")
		if key in ["fire", "thunder", "frost", "shell"]: return load("res://assets/Coop/" + key + ".png")
	var source = ITEMS if item else UPGRADES
	var texture = load(source[key][2]) as Texture2D
	if key == "shuriken":
		var atlas = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(0, 0, 16, 16)
		return atlas
	return texture
