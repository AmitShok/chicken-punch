extends SceneTree
# Validates the content catalog so a typo in a .tres file fails here, not mid-run.
const Data = preload("res://scripts/survival/data.gd")
var failures = 0
var checks = 0
func _initialize(): call_deferred("test")
func check(ok: bool, title: String):
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ") + title)
func unique(defs: Array, label: String):
	var keys = defs.map(func(d): return d.key)
	for key in keys:
		check(key != "" and keys.count(key) == 1, label + " key is set and unique: " + key)
func test():
	var catalog = Data.CATALOG
	check(catalog != null and catalog.equipment.size() > 0 and catalog.items.size() > 0 and catalog.characters.size() > 0, "Catalog loads with equipment, items and defenders")
	unique(catalog.equipment, "Equipment")
	unique(catalog.items, "Item")
	unique(catalog.characters, "Defender")
	for def in catalog.equipment:
		check(def.display_name != "" and def.description != "", def.key + " has a name and description")
		check(def.icon != null and def.art != null, def.key + " has art and an icon")
		check(def.max_rank >= 1 and def.max_rank <= Data.MAX_RANK, def.key + " max rank is within 1-10")
		check(def.starter or def.unlock_gold > 0, def.key + " is free or has a price")
		if def.evolution_tome != "":
			var tome = Data.equipment_def(def.evolution_tome)
			check(def.kind == 0 and tome != null and tome.kind == 1, def.key + " evolves from a weapon with a real tome")
			check(def.evolution_name != "" and def.evolved_icon != null, def.key + " evolution has a name and icon")
	for def in catalog.items:
		check(def.display_name != "" and def.icon != null, def.key + " item has a name and icon")
		check(def.rarity >= 0 and def.rarity < Data.RARITIES.size(), def.key + " item rarity is valid")
		check(def.starter or def.unlock_gold > 0, def.key + " item is free or has a price")
	for def in catalog.characters:
		var weapon = Data.equipment_def(def.starting_weapon)
		check(weapon != null and weapon.kind == 0, def.key + " starts with a real weapon")
		check(def.cell.x > 0 and def.cell.y > 0, def.key + " has a frame size")
		if def.sprite_sheet:
			check(def.sprite_sheet.get_width() % def.cell.x == 0, def.key + " sheet width is a whole number of frames")
	for ascension in Data.ASCENSIONS.values():
		check(Data.EVOLUTIONS.has(ascension[1]) and Data.EVOLUTIONS.has(ascension[2]), ascension[0] + " needs two evolvable weapons")
		check(Data.equipment_def(ascension[3]) != null and Data.equipment_def(ascension[4]) != null and Data.item_def(ascension[5]) != null, ascension[0] + " recipe names real tomes and an item")
	for synergy in Data.SYNERGIES.values():
		check(Data.equipment_def(synergy[1]) != null and (Data.item_def(synergy[2]) if synergy[3] else Data.equipment_def(synergy[2])) != null, synergy[0] + " names real parts")
	check(Data.WEAPONS.size() == catalog.equipment.filter(func(d): return d.kind == 0).size(), "Weapon list matches the catalog")
	print("CATALOG RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
