extends Area3D
class_name DeliveryPackage

var VEHICLE_DATA = load("res://Vehicles/Resources/vehicle_data.tres")
var DELIVERY_PACKAGE_DATA = load("res://DeliveryPackages/Resources/delivery_package_data.tres")

var MINI_MAP_STATS = preload("res://Minimap/Resources/mini_map_stats.tres")
var minimap_icon: String = "pickup"

@export var rotation_speed: float = 2

@onready var mesh: Node3D = $Mesh
signal package_picked

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	body_entered.connect(on_body_entered)
	
	MINI_MAP_STATS.emit_signal("add_minimap_object", self)


func _process(delta: float) -> void:
	mesh.rotation.y -= rotation_speed * delta


func on_body_entered(body):
	if body is Vehicle and body.delivery_vehicle:
		collision_shape_3d.set_deferred("disabled", true)
		
		## Erasing the package details in tracking arrays and dictionaries
		DELIVERY_PACKAGE_DATA.delivery_packages_array.erase(self)
		DELIVERY_PACKAGE_DATA.delivery_package_spawn_path_array.erase(DELIVERY_PACKAGE_DATA.delivery_packages_dict[self])
		DELIVERY_PACKAGE_DATA.delivery_packages_dict.erase(self)
		
		emit_signal("package_picked", self, body)
		MINI_MAP_STATS.emit_signal("remove_minimap_object", self)
		#print("%s picked %s!" % [body.name, self.name])
		
		var shrink_tween := create_tween()
		shrink_tween.tween_property(self, "position:y", 2, 0.25)
		shrink_tween.parallel().tween_property(mesh, "scale", Vector3.ZERO, 1)
		shrink_tween.set_ease(Tween.EASE_IN_OUT)
		shrink_tween.set_trans(Tween.TRANS_SINE)
		shrink_tween.finished.connect(queue_free)
