extends Area3D
class_name DeliveryPackage

@export var rotation_speed: float = 2

@onready var mesh: Node3D = $Mesh

func _process(delta: float) -> void:
	mesh.rotation.y -= rotation_speed * delta
