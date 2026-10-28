@tool
class_name GameCatalog
extends Resource
## The ordered list of everything the game offers. To add content, create a
## new EquipmentDef / ItemDef / CharacterDef resource and append it here.
## Order sets the order of shop lists and reward pools.

@export var equipment: Array[EquipmentDef] = []
@export var items: Array[ItemDef] = []
@export var characters: Array[CharacterDef] = []
