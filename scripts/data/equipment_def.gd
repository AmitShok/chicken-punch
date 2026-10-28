@tool
class_name EquipmentDef
extends Resource
## A weapon or tome offered on level-up. Weapon behaviour still lives in
## run.gd / arsenal.gd, keyed by `key`; this file holds everything else.

enum Kind { WEAPON, TOME }

## Internal id used by saves, code and recipes. Never rename after release.
@export var key := ""
@export var display_name := ""
@export_multiline var description := ""
@export var kind := Kind.TOME
@export var max_rank := 10
## Source art from the asset pack (used for the shop list and checks).
@export var art: Texture2D
## Icon shown on cards, slots and the HUD.
@export var icon: Texture2D

@export_group("Unlock")
## Available from the first run without buying it.
@export var starter := false
## Quest id from Data.QUESTS that must be complete before it can be bought.
@export var unlock_quest := ""
@export var unlock_gold := 35

@export_group("Evolution")
## Tome key that, with this weapon at max rank and a chest, evolves it.
@export var evolution_tome := ""
@export var evolution_name := ""
@export_multiline var evolution_effect := ""
@export var evolved_icon: Texture2D
