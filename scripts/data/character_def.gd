@tool
class_name CharacterDef
extends Resource
## A playable defender.

## Internal id used by saves. Never rename after release.
@export var key := ""
@export var display_name := ""
@export_multiline var flavor := ""
## Weapon key the defender starts each run with.
@export var starting_weapon := ""
## Animal sheet from the asset pack. Leave empty to use the original chicken.
@export var sprite_sheet: Texture2D
## Size of one frame in the sheet.
@export var cell := Vector2i(16, 16)
## Whether the sheet's art faces left.
@export var faces_left := false
@export var unlock_gold := 0
## Quest id from Data.QUESTS that must be complete before it can be bought.
@export var unlock_quest := ""
