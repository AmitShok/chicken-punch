@tool
class_name ItemDef
extends Resource
## A stackable treasure item found in chests.

enum Rarity { COMMON, RARE, EPIC }

## Internal id used by saves, code and recipes. Never rename after release.
@export var key := ""
@export var display_name := ""
@export_multiline var description := ""
@export var rarity := Rarity.COMMON
@export var icon: Texture2D

@export_group("Unlock")
@export var starter := false
## Quest id from Data.QUESTS that must be complete before it can be bought.
@export var unlock_quest := ""
@export var unlock_gold := 25
