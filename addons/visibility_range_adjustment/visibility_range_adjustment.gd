@tool
extends EditorPlugin

var dock: EditorDock

const VISIBILITY_RANGE_ADJUSTMENT_PANEL = preload("res://addons/visibility_range_adjustment/visibility_range_adjustment_panel.tscn")


func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	dock = EditorDock.new()
	dock.default_slot = EditorDock.DOCK_SLOT_RIGHT_BL
	
	dock.add_child(VISIBILITY_RANGE_ADJUSTMENT_PANEL.instantiate())
	
	add_dock(dock)


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_dock(dock)
	dock.queue_free()
