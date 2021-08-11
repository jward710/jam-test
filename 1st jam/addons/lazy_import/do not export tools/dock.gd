tool
extends Node


onready var singleton = $"/root/lazy_import"
onready var plugin = $"/root/EditorNode".get_node("lazy_import")

# before scan
var directory
var dir_found = false
var search_filter = "."

# after scan
var image_extensions = ["jpg", "png", "jpeg", "tga", "bmp", "psd", "svg", "svgz", "webp", "dds", "exr"] # hdr
var image_found = false
var image_checked = false
var mesh_extensions = ["fbx", "gltf", "glb", "dae", "obj"]
var mesh_found = false
var mesh_checked = false
var material_extensions = [".material", "material.tres" , "material.res"]
var material_found = false
var material_checked = false

# cache
onready var boton_error = $Buttons/Error
onready var boton_toggle = $Buttons/ToogleAll
var toggleAll = true
onready var boton_scenes = $Buttons/Scenes
onready var material_filename = $MaterialName
onready var material_options = $Buttons/MaterialOptions
onready var boton_material = $Buttons/Material
onready var file_list = $"ScrollContainer/File List"

const ImageConfig = preload("templates/ImageConfig.tscn")
const MeshConfig = preload("templates/MeshConfig.tscn")
const MaterialConfig = preload("templates/MaterialConfig.tscn")
	
	
	
	
func _ready():
	self.name = plugin.PluginDockName
	# no hacer refresh aqui porque este archivo se carga aun no estando el plugin activado o cargado todavia
	pass

func refresh(from):
	# esperamos un frame para que el dato reciba la señal de actualizarse
	# esperamos antes de empezar para no partir en dos el proceso y se intercalen
	yield(get_tree(), "idle_frame")
	
	if file_list is VBoxContainer:
		
		# reset de variables
		directory = ""
		image_found = false
		mesh_found = false
		dir_found = false
		toggleAll = true
		
		# reset de hijos
		for n in file_list.get_children():
			file_list.remove_child(n)
			n.queue_free()
		
		# miramos que directorio hemos recibido
		directory = plugin.selected_path()

		# revisamos el directorio
		var dir = Directory.new()
		if dir.dir_exists(directory) && dir.open(directory) == OK:
			dir.open(directory)
			dir.list_dir_begin()

			var file = dir.get_next()
			while file != "":
				if not dir.current_is_dir() && file != "" && not file.begins_with(".") && search_filter in file.to_lower():
					if is_valid_image_extension(file):
						image_found = true
						# instanciamos checkbox
						var node = ImageConfig.instance()
						node.get_node("CheckBox").text = file
						node.get_node("CheckBox").pressed = false
						node.get_node("CheckBox").connect("pressed", self, "refresh_buttons")
						node.get_node("OptionButton").selected = guess_layer(file)
						file_list.add_child(node)
					
					if is_valid_mesh_extension(file):
						mesh_found = true
						# instanciamos checkbox
						var node = MeshConfig.instance()
						node.get_node("CheckBox").text = file
						node.get_node("CheckBox").pressed = false
						node.get_node("CheckBox").connect("pressed", self, "refresh_buttons")
						
						if dir.file_exists(file + ".tscn"):
							node.get_node("CheckBox").disabled = true
							node.get_node("ToolButton").visible = true
						else:
							node.get_node("CheckBox").disabled = false
							node.get_node("ToolButton").visible = false
							
						file_list.add_child(node)
						
					if is_valid_material_extension(file):
						material_found = true
						# instanciamos checkbox
						var node = MaterialConfig.instance()
						node.get_node("CheckBox").text = file
						node.get_node("CheckBox").pressed = false
						var button = node.get_node("Preview")
						button.text = file + "@|@" + directory + "/" + file
						button.connect("pressed", self, "_on_Preview_pressed", [button])
							
						file_list.add_child(node)
						
				file = dir.get_next()
			dir.list_dir_end()
			
			dir_found = true
	
		refresh_buttons()

func is_valid_image_extension(file_name):
	plugin.check_string(file_name)
	file_name = file_name.to_lower()
	for f in image_extensions:
		if file_name.ends_with("." + f):
			return true
	return false
	
func is_valid_mesh_extension(file_name):
	plugin.check_string(file_name)
	file_name = file_name.to_lower()
	for f in mesh_extensions:
		if file_name.ends_with("." + f):
			return true
	return false
	
func is_valid_material_extension(file_name):
	plugin.check_string(file_name)
	file_name = file_name.to_lower()
	for f in material_extensions:
		if file_name.ends_with(f):
			return true
	return false

func refresh_buttons():
	boton_error.visible = false
	boton_toggle.visible = false
	boton_scenes.visible = false
	material_options.visible = false
	boton_material.visible = false
	material_filename.visible = false
	
	if dir_found:
		if image_found || mesh_found:
			if toggleAll:
				boton_toggle.text = "All"
			else:
				boton_toggle.text = "Nothing"
			boton_toggle.visible = true
		else:
			boton_toggle.visible = false
			boton_error.text = "Nothing found in this Folder"
			boton_error.visible = true
			
		# check if files are checked
		image_checked = false
		mesh_checked = false
		for node in file_list.get_children():
			var N = node.get_node("CheckBox")
			if N is CheckBox && N.pressed == true:
				if is_valid_image_extension(N.text): image_checked = true
				if is_valid_mesh_extension(N.text): mesh_checked = true
		
		if image_checked && mesh_checked:
			boton_error.text = "Select Images OR Meshes"
			boton_error.visible = true
		elif image_checked:
			material_options.visible = true
			boton_material.visible = true
			material_filename.visible = true
		elif mesh_checked:
			boton_scenes.visible = true
		else:
			boton_scenes.visible = false
			material_options.visible = false
			boton_material.visible = false
	else:
		boton_error.text = "Select Folder in FileSystem"
		boton_error.visible = true


func load_template(file):
	plugin.check_string(file)
	
	var text = ""
	var f = File.new()
	f.open(file, File.READ)

	while not f.eof_reached():
		text += f.get_line()
	f.close()
	
	plugin.check_string(text)
	
	return text

func save_template(file_name, file_content):
	plugin.check_string(file_name)
	plugin.check_string(file_content)
	
	var file := File.new()
	file.open(file_name, file.WRITE)
	assert(file.is_open())
	file.store_string(file_content)
	file.close()
	
	plugin.notify("created a new file: " + file_name)

func remove_file_extensions(file_name):
	plugin.check_string(file_name)
	
	var filenameToLower = file_name.to_lower()
	for f in image_extensions:
		if filenameToLower.ends_with("." + f):
			var bs = file_name.length()
			var ext_len = f.length()
			file_name.erase(bs-ext_len-1,ext_len+1)
	for f in mesh_extensions:
		if filenameToLower.ends_with("." + f):
			var bs = file_name.length()
			var ext_len = f.length()
			file_name.erase(bs-ext_len-1,ext_len+1)
	return file_name


func guess_layer(file_name):
	plugin.check_string(file_name)
	var layer = 0
	file_name = file_name.to_lower()
	
	# Ambiguous and super reduced  names
	for f in ["color", "_diff_", "diffusion", "diffuse"]:
		if (f in file_name):
			layer = 1
	for f in ["specular"]:
		if (f in file_name):
			layer = 2
	for f in ["_rough_", "thickness"]: # thickness es otra forma de llamar al roughness?
		if (f in file_name):
			layer = 3
	for f in ["_n.", "_n_", "_nm_", "_nm.", "_nor_gl_"]: # normal map
		if (f in file_name):
			layer = 5
	for f in ["_ao_", "_ao."]: # ambient occlusion
		if (f in file_name):
			layer = 9
	for f in ["height"]: # ¿height seria lo contrario a depth?
		if (f in file_name):
			layer = 10
	for f in ["_ss_", "_ss."]: # subsurface scattering
		if (f in file_name):
			layer = 11
	for f in ["moads", "maods"]: # Multi Object Attribute-Driven Shading ¿decals?
		if (f in file_name):
			layer = 15
	
	# Not directly functional
	# inverted layers = need reimport
	for f in ["displacement"]:
		if (f in file_name):
			layer = 10
	
	# nombres concretos y facilmente reconocibles
	for f in ["albedo"]:
		if (f in file_name):
			layer = 1
	for f in ["metallic"]:
		if (f in file_name):
			layer = 2
	for f in ["roughness"]:
		if (f in file_name):
			layer = 3
	for f in ["emission"]:
		if (f in file_name):
			layer = 4
	for f in ["normal", "normal map"]:
		if (f in file_name):
			layer = 5
	for f in ["rim"]:
		if (f in file_name):
			layer = 6
	for f in ["clearcoat"]:
		if (f in file_name):
			layer = 7
	for f in ["anisotropy"]:
		if (f in file_name):
			layer = 8
	for f in ["ambient occlusion", "occlusion"]:
		if (f in file_name):
			layer = 9
	for f in ["depth"]:
		if (f in file_name):
			layer = 10
	for f in ["scattering", "subsurface", "_ss_", "_ss."]:
		if (f in file_name):
			layer = 11
	for f in ["transmission"]:
		if (f in file_name):
			layer = 12
	for f in ["refraction"]:
		if (f in file_name):
			layer = 13
	for f in ["detail", "maskmap", "mask"]:
		if (f in file_name):
			layer = 14
	for f in ["decal"]:
		if (f in file_name):
			layer = 15
	for f in ["opacity"]:
		if (f in file_name):
			layer = 16

	return layer


func try_to_fix_file(file_name):
	plugin.check_string(file_name)
	file_name = file_name.to_lower()

	for f in ["displacement"]:
		if (f in file_name):
			change_import_file(directory + file_name, "process/invert_color=false", "process/invert_color=true")
			
	for f in ["specular", "diffuse"]:
		if (f in file_name):
			plugin.notify("You need to convert the " + f + " map to PBR")
			
	for f in ["opacity", "glass"]:
		if (f in file_name):
			plugin.notify("You probably need to put the " + f + " map inside the Albedo Alpha channel")

func change_import_file(file_name, what, forwhat):
	plugin.check_string(file_name)
	plugin.check_string(what)
	plugin.check_string(forwhat)
	
	var file_content = load_template(file_name + ".import")
	file_content.replace(what, forwhat)
	save_template(file_name, file_content)


func create_material():
	# TODO ignore Unknown and Unable to process 
	
	var file_name = "_material.tres"
	if material_filename.text != "":
		file_name = material_filename.text + "_material.tres"
	
	var file_content = load_template("res://addons/Lazy_Import/templates/spatialmaterial.header.tres.txt") + "\n\n"
	var step1 = load_template("res://addons/Lazy_Import/templates/spatialmaterial.step1.tres.txt") + "\n\n"
	
	# listado de archivos
	var file_id = 1
	for node in file_list.get_children():
		var N = node.get_node("CheckBox")
		if N is CheckBox && N.pressed == true:
			try_to_fix_file(N.text)
			file_content += step1.replace("%%FILE%%", directory + N.text).replace("%%ID%%", file_id) + "\n"
			file_id += 1
	
	file_content += load_template("res://addons/Lazy_Import/templates/spatialmaterial.step2.tres.txt") + "\n\n"
	
	match material_options.text:
		"High Quality":
			file_content += ""
		"Transparent":
			file_content += "flags_transparent = true\n"
		"Low End":
			file_content += "flags_vertex_lighting = true\n"
		"Interface":
			file_content += "flags_no_depth_test = true\nflags_fixed_size = true\nflags_do_not_receive_shadows = true\nflags_disable_ambient_light = true\nparams_specular_mode = 4\nparams_billboard_mode = 1\nparams_billboard_keep_scale = true\n"
		"Hair":
			file_content += "params_diffuse_mode = 2\n"
		"Cloth":
			file_content += "params_diffuse_mode = 3\n"
		"Toon":
			file_content += "params_diffuse_mode = 4\nparams_specular_mode = 3\n"
		"Foliage":
			file_content += "flags_no_depth_test = true\nparams_depth_draw_mode = 3\n"
		"Billboard":
			file_content += "flags_no_depth_test = true\nparams_depth_draw_mode = 3\nparams_billboard_mode = 1\n"
		"Particles":
			file_content += "flags_no_depth_test = true\nparams_billboard_mode = 3\nparticles_anim_h_frames = 1\nparticles_anim_v_frames = 1\nparticles_anim_loop = false\n"
		"Sprite":
			file_content += "flags_no_depth_test = true\nflags_fixed_size = true\nflags_do_not_receive_shadows = true\nparams_specular_mode = 4\nparams_use_alpha_scissor = true\nparams_alpha_scissor_threshold = 0.98\n"
		"Meat":
			file_content += ""
		"Light":
			file_content += "flags_transparent = true\nparams_blend_mode = 1\n"
	
	file_id = 1
	for node in file_list.get_children():
		var N = node.get_node("CheckBox")
		if N is CheckBox && N.pressed == true:
			var O = node.get_node("OptionButton")
			
			match O.text:
				"Unknown": # Albedo, Metallic y Rougness parecen ser obligatorios
					pass
				"Albedo":
					file_content += "albedo_texture = ExtResource( " + str(file_id) + " )\n"
				"Metallic":
					file_content += "metallic_texture = ExtResource( " + str(file_id) + " )\nmetallic = 1.0\nroughness = 0.5\n"
				"Rougness":
					file_content += "roughness_texture = ExtResource( " + str(file_id) + " )\n"
				"Emission":
					file_content += "emission_enabled = true\nemission = Color( 0, 0, 0, 1 )\nemission_energy = 1.0\nemission_operator = 0\nemission_on_uv2 = false\nemission_texture = ExtResource( " + str(file_id) + " )\n"
				"Normal Map":
					file_content += "normal_enabled = true\nnormal_scale = 1.0\nnormal_texture = ExtResource( " + str(file_id) + " )\n"
				"Rim":
					file_content += "rim_enabled = true\nrim = 1.0\nrim_tint = 0.5\nrim_texture = ExtResource( " + str(file_id) + " )\n"
				"Clearcoat":
					file_content += "clearcoat_enabled = true\nclearcoat = 1.0\nclearcoat_gloss = 0.5\nclearcoat_texture = ExtResource( " + str(file_id) + " )\n"
				"Anisotropy":
					file_content += "anisotropy_enabled = true\nanisotropy = 0.0\nanisotropy_flowmap = ExtResource( " + str(file_id) + " )\n"
				"Ambient Occlusion":
					file_content += "ao_enabled = true\nao_light_affect = 0.0\nao_texture = ExtResource( " + str(file_id) + " )\nao_on_uv2 = false\nao_texture_channel = 0\n"
				"Depth":
					file_content += "depth_enabled = true\ndepth_scale = 0.001\ndepth_deep_parallax = false\ndepth_flip_tangent = false\ndepth_flip_binormal = false\ndepth_texture = ExtResource( " + str(file_id) + " )\n"
				"Subsurface Scattering":
					file_content += "params_diffuse_mode = 2\nsubsurf_scatter_enabled = true\nsubsurf_scatter_strength = 0.0\nsubsurf_scatter_texture = ExtResource( " + str(file_id) + " )\n"
				"Transmission":
					file_content += "transmission_enabled = true\ntransmission = Color( 0, 0, 0, 1 )\ntransmission_texture = ExtResource( " + str(file_id) + " )\n"
				"Refraction":
					file_content += "refraction_enabled = true\nrefraction_scale = 0.05\nrefraction_texture = ExtResource( " + str(file_id) + " )\nrefraction_texture_channel = 0\n"
				"Detail":
					file_content += "detail_enabled = true\ndetail_mask = ExtResource( " + str(file_id) + " )\ndetail_blend_mode = 0\ndetail_uv_layer = 0\n"
				"Decal":
					file_content += "flags_no_depth_test = true\n"
				"Need Conversion":
					pass
			
			file_id += 1

	var full_path = directory + "/" + file_name
	save_template(full_path, file_content)
	
	plugin.filesystem_refresh()
	plugin.material_preview(file_name, full_path)
	refresh("create_material")



# Signals

func _on_Scenes_pressed():
	var template = load_template("res://addons/Lazy_Import/templates/scene.tscn.txt")
	
	for node in file_list.get_children():
		var N = node.get_node("CheckBox")
		if N is CheckBox && N.pressed == true:
			var checkbox_file = N.text
			var checkbox_name = remove_file_extensions(checkbox_file)
			if plugin.check_string(checkbox_name):
				var file_name = directory + "/" + checkbox_file + ".tscn"
				var file_included = directory + "/" + checkbox_file
				var file_content = template.replace("%%FILE%%", file_included).replace("%%NAME%%", checkbox_name)
			
				save_template(file_name, file_content)
	
	plugin.filesystem_refresh()
	refresh("_on_Scenes_pressed")


func _on_Materials_pressed():
	create_material()


func _on_ToogleAll_pressed():
	for node in file_list.get_children():
		var N = node.get_node("CheckBox")
		if N is CheckBox && N.disabled == false:
			N.pressed = toggleAll
	
	toggleAll = !toggleAll
	
	refresh_buttons()


func _on_LineEdit_text_changed(new_text):
	if new_text != "":
		search_filter = new_text
	else:
		search_filter = "."
	refresh("_on_LineEdit_text_changed")


#func _on_MaterialName_text_changed(new_text):
#	pass # Replace with function body.

func _on_Preview_pressed(button):
	var data =  button.text
	data = data.split("@|@")
	plugin.notify("Opening preview with " + data[0])
	plugin.material_preview(data[0], data[1])
