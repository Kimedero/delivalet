extends Area3D
class_name DeliveryPackage

@export var rotation_speed: float = 2

@onready var mesh: Node3D = $Mesh

func _process(delta: float) -> void:
	mesh.rotation.y -= rotation_speed * delta


func _ready() -> void:
	body_entered.connect(on_body_entered)


func on_body_entered(body):
	if body is Vehicle:
		print("%s touched me!" % [body.name])
