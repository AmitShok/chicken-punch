extends SceneTree
const Data = preload("res://scripts/survival/data.gd")
func _initialize(): call_deferred("capture")
func shot(name: String):
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0]+"/"+name+".png")
func capture():
	Data.save_path="user://coop_menu_capture.cfg"
	Data.write_save({"gold":250,"best":180,"muted":true})
	var menu=load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene=menu
	await shot("organized-character-menu")
	menu.find_child("OpenOptions",true,false).pressed.emit()
	await shot("options-audio")
	var options=menu.find_child("OptionsTabs",true,false)
	options.current_tab=1
	await shot("options-controls")
	options.current_tab=2
	await shot("options-credits")
	menu.close_options()
	menu.select_character("whisker")
	await shot("locked-character-selected")
	menu.select_character("nugget")
	menu.find_child("OpenUpgrades",true,false).pressed.emit()
	await shot("organized-upgrades-menu")
	menu.find_child("Buy_power",true,false).pressed.emit()
	print("Purchase updates selected profile: ",Data.training(menu.save).power==1 and menu.save.gold==210 and menu.upgrades_open)
	menu.select_character("pepper")
	await shot("locked-character-upgrades")
	print("Locked character cannot buy: ",menu.find_child("Buy_power",true,false).disabled)
	var escape=InputEventKey.new()
	escape.keycode=KEY_ESCAPE
	escape.pressed=true
	menu._unhandled_key_input(escape)
	print("Escape returns to character menu: ",not menu.upgrades_open and menu.find_child("OpenUpgrades",true,false)!=null)
	quit()
