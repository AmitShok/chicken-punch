# Adding content

Weapons, tomes, items and defenders are Godot resources in `resources/catalog/`. `resources/catalog.tres` lists them in order; that order sets shop lists and reward pools. Edit any of them in the Godot inspector.

| Type | Script | Folder |
| --- | --- | --- |
| Weapon or tome | `scripts/data/equipment_def.gd` (EquipmentDef) | `resources/catalog/equipment/` |
| Treasure item | `scripts/data/item_def.gd` (ItemDef) | `resources/catalog/items/` |
| Defender | `scripts/data/character_def.gd` (CharacterDef) | `resources/catalog/characters/` |

## What needs only data

- **Rename, reword, re-price or re-icon** anything: edit its `.tres`.
- **Change unlocks:** `starter`, `unlock_seconds` (best survival time) and `unlock_gold`.
- **Item rarity:** changes chest odds, card colour and slot colour.
- **Max rank** for a weapon or tome.
- **Evolution text and art:** `evolution_name`, `evolution_effect` and `evolved_icon`. The recipe itself is `evolution_tome`.
- **A new defender** that starts with an existing weapon: duplicate a defender `.tres`, set the sprite sheet, `cell` (frame size), `faces_left`, price and starting weapon, then add it to `catalog.tres`. No code needed.

## What still needs code

The `key` is how code finds behaviour, so a brand-new key needs its effect written:

- **New weapon:** its attack in `run.gd` (`attack_weapons`, `update_orbits`) or `arsenal.gd`, damage numbers in `base_upgrade_preview`, and the detail text in `inspection.gd`.
- **New tome:** the stat it changes, in the relevant `run.gd` helper (for example `power()` or `area_multiplier()`), plus a preview line in `base_upgrade_preview`.
- **New item:** its effect where items are read (`run.items.get("key")`).
- **Synergies and Ascensions** stay in `data.gd` because they are recipes for code behaviour.

## Checks

`tests/catalog_test.gd` validates the catalog: unique keys, names, icons, prices, valid rarities, evolution tomes that exist, defenders that start with real weapons, sheet sizes that are whole frames, and recipes that name real parts. Run it after any content edit:

```text
godot --headless --path . --script res://tests/catalog_test.gd
```

`Data` still exposes the original tables (`UPGRADES`, `ITEMS`, `CHARACTERS` and so on), built from the catalog, so older code works unchanged. New code should prefer `Data.equipment_def(key)`, `Data.item_def(key)` and `Data.character_def(key)`, which return typed resources.
