extends Resource

var delivery_package_path: Node3D

const DELIVERY_PACKAGE = preload("res://DeliveryPackages/delivery_package.tscn")

var current_delivery_packages: Array

func spawn_delivery_package(spawn_position: Vector3) -> DeliveryPackage:
	var new_delivery_package := DELIVERY_PACKAGE.instantiate()
	delivery_package_path.add_child(new_delivery_package)
	new_delivery_package.global_position = spawn_position
	
	current_delivery_packages.append(new_delivery_package)
	new_delivery_package.name = "DeliveryPackage"
	
	return new_delivery_package
