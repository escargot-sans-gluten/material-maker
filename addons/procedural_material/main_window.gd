extends Panel

var current_tab = -1

const MENU = [
	{ menu="File", command="new_material", description="New material" },
	{ menu="File", command="load_material", shortcut="Control+O", description="Load material" },
	{ menu="File" },
	{ menu="File", command="save_material", shortcut="Control+S", description="Save material" },
	{ menu="File", command="save_material_as", shortcut="Control+Shift+S", description="Save material as..." },
	{ menu="File", command="save_all_materials", description="Save all materials..." },
	{ menu="File" },
	{ menu="File", command="export_material", shortcut="Control+E", description="Export material" },
	{ menu="File" },
	{ menu="File", command="close_material", description="Close material" },
	{ menu="File", command="quit", shortcut="Control+Q", description="Quit" },
	{ menu="Tools", command="save_icons", description="Save icons for selected nodes" },
	{ menu="Tools", command="add_to_user_library", description="Add selected node to user library" },
	{ menu="Tools", command="save_user_library", description="Save user library" },
	{ menu="Help", command="about", description="About" }
]

func _ready():
	for m in $VBoxContainer/Menu.get_children():
		create_menu(m.get_popup(), m.name)

func create_menu(menu, menu_name):
	menu.connect("id_pressed", self, "_on_PopupMenu_id_pressed")
	for i in MENU.size():
		if MENU[i].menu != menu_name:
			continue
		if MENU[i].has("submenu"):
			var submenu = PopupMenu.new()
			create_menu(submenu, MENU[i].submenu)
			menu.add_child(submenu)
			menu.add_submenu_item(MENU[i].description, submenu.get_name())
		elif MENU[i].has("description"):
			var shortcut = 0
			if MENU[i].has("shortcut"):
				for s in MENU[i].shortcut.split("+"):
					if s == "Alt":
						shortcut |= KEY_MASK_ALT
					elif s == "Control":
						shortcut |= KEY_MASK_CTRL
					elif s == "Shift":
						shortcut |= KEY_MASK_SHIFT
					else:
						shortcut |= OS.find_scancode_from_string(s)
			menu.add_item(MENU[i].description, i, shortcut)
		else:
			menu.add_separator()
	return menu

func new_pane():
	var graph_edit = preload("res://addons/procedural_material/graph_edit.tscn").instance()
	$VBoxContainer/HBoxContainer/Projects.add_child(graph_edit)
	$VBoxContainer/HBoxContainer/Projects.current_tab = graph_edit.get_index()
	return graph_edit 

func new_material():
	var graph_edit = new_pane()
	graph_edit.update_tab_title()

func load_material():
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.ptex;Procedural textures file")
	dialog.connect("file_selected", self, "do_load_material")
	dialog.popup_centered()

func do_load_material(filename):
	var graph_edit = new_pane()
	graph_edit.do_load_file(filename)

func save_material():
	$VBoxContainer/HBoxContainer/Projects.get_current_tab_control().save_file()
	
func save_material_as():
	$VBoxContainer/HBoxContainer/Projects.get_current_tab_control().save_file_as()

func close_material():
	$VBoxContainer/HBoxContainer/Projects.get_current_tab_control().queue_free()

func save_icons():
	var graphedit = $VBoxContainer/HBoxContainer/Projects.get_current_tab_control()
	if graphedit != null and graphedit is GraphEdit:
		for n in graphedit.get_children():
			if n is GraphNode and n.selected:
				graphedit.export_texture(n, "res://addons/procedural_material/library/icons/"+n.name+".png", 64)

func add_to_user_library():
	var graphedit = $VBoxContainer/HBoxContainer/Projects.get_current_tab_control()
	if graphedit != null and graphedit is GraphEdit:
		for n in graphedit.get_children():
			if n is GraphNode and n.selected:
				var dialog = preload("res://addons/procedural_material/widgets/line_dialog.tscn").instance()
				add_child(dialog)
				dialog.connect("ok", self, "do_add_to_user_library", [n])
				dialog.popup_centered()
				break

func do_add_to_user_library(name, node):
	var data = node.serialize()
	var dir = Directory.new()
	dir.make_dir("user://library")
	dir.make_dir("user://library/user")
	data.erase("node_position")
	data.library = "user://library/user.json"
	data.icon = name.right(name.rfind("/")+1).to_lower()
	$VBoxContainer/HBoxContainer/VBoxContainer/Library.add_item(data, name)
	var graphedit = $VBoxContainer/HBoxContainer/Projects.get_current_tab_control()
	graphedit.export_texture(node, "user://library/user/"+data.icon+".png", 64)

func save_user_library():
	print("Saving user library")
	$VBoxContainer/HBoxContainer/VBoxContainer/Library.save_library("user://library/user.json")

func quit():
	get_tree().quit()
	
func _on_PopupMenu_id_pressed(id):
	var node_type = null
	if MENU[id].has("command"):
		call(MENU[id].command)

# Preview

func update_preview():
	var material_node = $VBoxContainer/HBoxContainer/Projects.get_current_tab_control().get_node("Material")
	if material_node != null:
		material_node.update_materials($VBoxContainer/HBoxContainer/VBoxContainer/Preview.get_materials())
	update_preview_2d()

func update_preview_2d(node = null):
	var graphedit = $VBoxContainer/HBoxContainer/Projects.get_current_tab_control()
	var preview = $VBoxContainer/HBoxContainer/VBoxContainer/Preview
	if node == null:
		for n in graphedit.get_children():
			if n is GraphNode and n.selected:
				node = n
				break
	if node != null:
		graphedit.setup_material(preview.get_2d_material(), node.get_textures(), node.generate_shader())

func _on_Projects_tab_changed(tab):
	if tab != current_tab:
		$VBoxContainer/HBoxContainer/Projects.get_current_tab_control().connect("graph_changed", self, "update_preview")
		$VBoxContainer/HBoxContainer/Projects.get_current_tab_control().connect("node_selected", self, "update_preview_2d")
		current_tab = tab
		update_preview()
