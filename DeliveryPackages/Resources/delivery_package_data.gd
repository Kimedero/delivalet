extends Resource

var delivery_package_spawn_node: Node3D

const DELIVERY_PACKAGE = preload("res://DeliveryPackages/delivery_package.tscn")

## maximum number of packages to be spawned
var max_delivery_packages: int = 8
## array of spawned packages. To be used for navigation
var delivery_packages_array: Array
var delivery_packages_dict: Dictionary
## keeps track of what path a package spawned at
var delivery_package_spawn_path_array: Array

func spawn_delivery_package(spawn_position: Vector3, spawn_path: Path3D) -> DeliveryPackage:
	var new_delivery_package := DELIVERY_PACKAGE.instantiate()
	delivery_package_spawn_node.add_child(new_delivery_package)
	new_delivery_package.global_position = spawn_position
	
	delivery_packages_array.append(new_delivery_package)
	## We store what path a package spawns at
	delivery_packages_dict[new_delivery_package] = {
		"path": spawn_path,
		}
	delivery_package_spawn_path_array.append(spawn_path)
	
	new_delivery_package.name = "DeliveryPackage"
	
	return new_delivery_package
