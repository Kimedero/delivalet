@tool
extends VBoxContainer

@onready var mesh_start_spin_box: SpinBox = $PanelContainer/VBoxContainer/HBoxContainer/MeshStartSpinBox
@onready var mesh_end_spin_box: SpinBox = $PanelContainer/VBoxContainer/HBoxContainer/MeshEndSpinBox
@onready var lod_start_spin_box: SpinBox = $PanelContainer/VBoxContainer/HBoxContainer2/LODStartSpinBox
@onready var lod_end_spin_box: SpinBox = $PanelContainer/VBoxContainer/HBoxContainer2/LODEndSpinBox

@onready var mesh_visible_check_box: CheckBox = $PanelContainer/VBoxContainer/HBoxContainer/MeshVisibleCheckBox
@onready var lod_visible_check_box: CheckBox = $PanelContainer/VBoxContainer/HBoxContainer2/LODVisibleCheckBox

var mesh_visible: bool = true
var lod_mesh_visible: bool = true

@onready var setting_button: Button = $PanelContainer/VBoxContainer/SettingButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setting_button.pressed.connect(set_mesh_visibility_ranges)
	
	mesh_visible_check_box.toggled.connect(on_mesh_visible_check_box_toggled)


func set_mesh_visibility_ranges() -> void:
	var selected_nodes_array: Array = EditorInterface.get_selection().get_selected_nodes()
	for selected_node in selected_nodes_array:
		if selected_node is MeshInstance3D:
			if "LOD" in selected_node.name.to_upper():
				process_lod_mesh(selected_node)
				#print("Bloop 1! - %s" % [selected_node])
			else:
				process_mesh(selected_node)
				#print("Bloop 2! - %s" % [selected_node])
		if selected_node is StaticBody3D:
			var children_array: Array = selected_node.get_children()
			for kid in children_array:
				if kid is MeshInstance3D:
					if "LOD" in kid.name.to_upper():
						process_lod_mesh(kid)
						#print("Bloop 1! - %s" % [selected_node])
					else:
						process_mesh(kid)
						#print("Bloop 2! - %s" % [selected_node])
	if selected_nodes_array.is_empty():
		var root_node = EditorInterface.get_edited_scene_root()
		for child in root_node.get_children():
			if child is MeshInstance3D:
				if "LOD" in child.name.to_upper():
					process_lod_mesh(child)
					#print("Bloop 1! - %s" % [selected_node])
				else:
					process_mesh(child)


func process_lod_mesh(mesh_inst: MeshInstance3D) -> void:
	mesh_inst.visibility_range_begin = lod_start_spin_box.value
	mesh_inst.visibility_range_end = lod_end_spin_box.value
	mesh_inst.visible = lod_visible_check_box.button_pressed
	print("Processed LOD mesh: %s - Start: %s - End: %s" % [mesh_inst.name, mesh_inst.visibility_range_begin, mesh_inst.visibility_range_end])


func process_mesh(mesh_inst: MeshInstance3D) -> void:
	mesh_inst.visibility_range_begin = mesh_start_spin_box.value
	mesh_inst.visibility_range_end = mesh_end_spin_box.value
	mesh_inst.visible = mesh_visible_check_box.button_pressed
	print("Processed mesh: %s - Start: %s - End: %s" % [mesh_inst.name, mesh_inst.visibility_range_begin, mesh_inst.visibility_range_end])


func on_mesh_visible_check_box_toggled(toggled_on: bool) -> void:
	mesh_visible = toggled_on


func on_lod_mesh_visible_check_box_toggled(toggled_on: bool) -> void:
	lod_mesh_visible = toggled_on
