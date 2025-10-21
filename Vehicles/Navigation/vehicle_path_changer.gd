@tool
extends Area3D
class_name VehiclePathChanger

var linked_paths_array: Array[Path3D]
var neighbour_path_changers_array: Array[VehiclePathChanger]

@export var area_radius: float = 16: set = set_area_radius, get = get_area_radius

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	body_entered.connect(on_body_entered)
	body_exited.connect(on_body_exited)


func on_body_entered(body):
	if body is Vehicle:
		body.emit_signal("vehicle_at_path_changer", self, true)


func on_body_exited(body):
	if body is Vehicle:
		body.emit_signal("vehicle_at_path_changer", self, false)


func set_area_radius(value):
	collision_shape_3d.shape.radius = value
	mesh_instance_3d.mesh.top_radius = value
	mesh_instance_3d.mesh.bottom_radius = value
	print("%s's new area radius: %s" % [name, value])


func get_area_radius() -> float:
	return area_radius
