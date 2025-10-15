@tool 
extends EditorScript

func _run() -> void:
	var sel_objs = EditorInterface.get_selection().get_selected_nodes()
	for sel_obj in sel_objs:
		for node_child in sel_obj.get_children():
			if node_child is Path3D:
				for node_kid in node_child.get_children():
					if node_kid is CSGPolygon3D:
						print(node_kid)
						node_kid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
						node_kid.visibility_range_end = 0 # 100
						node_kid.visibility_range_end_margin = 10
						node_kid.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
