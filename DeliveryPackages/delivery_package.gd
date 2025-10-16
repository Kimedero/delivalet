extends Area3D
class_name DeliveryPackage

var VEHICLE_DATA = load("res://Vehicles/Resources/vehicle_data.tres")
var DELIVERY_PACKAGE_DATA = load("res://DeliveryPackages/Resources/delivery_package_data.tres")

@export var rotation_speed: float = 2

@onready var mesh: Node3D = $Mesh
signal package_picked
#signal package_delivered

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	body_entered.connect(on_body_entered)


func _process(delta: float) -> void:
	mesh.rotation.y -= rotation_speed * delta


func on_body_entered(body):
	if body is Vehicle and body.delivery_vehicle:
		collision_shape_3d.set_deferred("disabled", true)
		
		emit_signal("package_picked", self, body)
		
		#print("%s picked %s!" % [body.name, self.name])
		DELIVERY_PACKAGE_DATA.current_delivery_packages_array.erase(self)
		
		var shrink_tween := create_tween()
		shrink_tween.tween_property(mesh, "scale", Vector3.ZERO, 1)
		shrink_tween.set_ease(Tween.EASE_IN_OUT)
		shrink_tween.set_trans(Tween.TRANS_SPRING)
		shrink_tween.finished.connect(queue_free)
