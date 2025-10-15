extends Node3D

var GAME_DATA = load("res://Resources/game_data.tres")
var VEHICLE_DATA = load("res://Vehicles/Resources/vehicle_data.tres")
var VEHICLE_PATHFINDING = load("res://Vehicles/Resources/vehicle_pathfinding.tres")
var DELIVERY_PACKAGE_DATA = load("res://DeliveryPackages/Resources/delivery_package_data.tres")

@export var vehicles_spawn: Node3D

@export var vehicle_path_changers: Node3D
@export var vehicle_paths: Node3D

@export var navigation_path_holder: Node
@export var delivery_package_path_holder: Node


func _ready() -> void:
	randomize()
	
	VEHICLE_DATA.vehicle_spawn = vehicles_spawn
	
	assert(vehicle_paths, "Vehicle paths not set!")
	VEHICLE_DATA.vehicle_traffic_paths_array = vehicle_paths.get_children()
	VEHICLE_PATHFINDING.vehicle_traffic_paths_array = vehicle_paths.get_children()
	
	VEHICLE_DATA.vehicle_path_changers_array = vehicle_path_changers.get_children()
	VEHICLE_PATHFINDING.vehicle_path_changers_array = vehicle_path_changers.get_children()
	
	if navigation_path_holder:
		VEHICLE_PATHFINDING.navigation_path_holder_node = navigation_path_holder
	
	DELIVERY_PACKAGE_DATA.delivery_package_path = delivery_package_path_holder
	
	set_vehicle_path_changer_linked_paths()
	set_path_changers_neighbours()
	
	assert(not VEHICLE_PATHFINDING.vehicle_path_changers_array.is_empty(), "We do not have vehicle path changers set!")
	VEHICLE_PATHFINDING.add_navigation_points()
	VEHICLE_PATHFINDING.connect_navigation_points()
	
	spawn_delivery_package()
	spawn_delivery_package()
	spawn_delivery_package()
	spawn_delivery_package()
	spawn_delivery_package()


func set_vehicle_path_changer_linked_paths():
	for path_changer: VehiclePathChanger in vehicle_path_changers.get_children():
		for vehicle_path: Path3D in vehicle_paths.get_children():
			var path_start_pos: Vector3 = GAME_DATA.flatten_vec3(vehicle_path.curve.get_point_position(0))
			
			var path_changer_pos: Vector3 = GAME_DATA.flatten_vec3(path_changer.global_position)
			#print("%s: %s -> %s" % [path_changer.name, path_changer_pos, path_follow_pos])
			var nearest_point_on_path: Vector3 = GAME_DATA.flatten_vec3(vehicle_path.curve.get_closest_point(path_changer_pos))
			var distance_to_path: float = nearest_point_on_path.distance_squared_to(path_changer_pos)
			var distance_to_path_start_pos: float = path_start_pos.distance_squared_to(path_changer_pos)
			if distance_to_path <= pow(path_changer.area_radius, 2) and distance_to_path_start_pos <= pow(path_changer.area_radius, 2):
				path_changer.linked_paths_array.append(vehicle_path)
		#print("%s -> %s: %s" % [path_changer.name, path_changer.linked_paths_array.size(),path_changer.linked_paths_array])


func set_path_changers_neighbours():
	# this automatically calculates a path changer's neighbours by comparing 
	# how many linked paths they have in common. A neighbour must share 
	# at least two linked paths
	var vehicle_path_changers_array: Array = vehicle_path_changers.get_children()
	for current_vehicle_path_changer: VehiclePathChanger in vehicle_path_changers_array:
		current_vehicle_path_changer.neighbour_path_changers_array.clear()
		for vehicle_path_changer: VehiclePathChanger in vehicle_path_changers_array:
			if vehicle_path_changer != current_vehicle_path_changer:
				for linked_path: Path3D in current_vehicle_path_changer.linked_paths_array:
					#we approach the problem of calculating neighbours a bit different
					#each path only goes to one other path changer. So we check each path's 
					#nearest path changer when that path's path-follow's progress ratio is at 1.
					
					# or just check the nearest path changer to a path's highest polygon
					var path_end_pos: Vector3 = GAME_DATA.flatten_vec3(linked_path.curve.get_point_position(linked_path.curve.point_count - 1))
					var distance_to_vehicle_path_changer: float = path_end_pos.distance_squared_to(GAME_DATA.flatten_vec3(vehicle_path_changer.global_position))
					if distance_to_vehicle_path_changer <= pow(vehicle_path_changer.area_radius, 2):
						current_vehicle_path_changer.neighbour_path_changers_array.append(vehicle_path_changer)
					
		#print("%s -> Neighbours: %s" % [current_vehicle_path_changer.name, current_vehicle_path_changer.neighbour_path_changers_array])


func spawn_delivery_package():
	var random_spawn_path: Path3D = vehicle_paths.get_children().pick_random()
	#var package_spawn_pos: Vector3 = Array(random_spawn_path.curve.get_baked_points()).pick_random()
	#while random_spawn_path.curve.get_closest_offset(package_spawn_pos) / random_spawn_path.curve.get_closest_point(random_spawn_path.curve.point_count - 1) > :
	#var current_progress_ratio: float
	var random_ratio := randf_range(0.1, 0.9)
	
	var new_path_follow := PathFollow3D.new()
	random_spawn_path.add_child(new_path_follow)
	new_path_follow.progress_ratio = random_ratio
	var package_spawn_pos: Vector3 = random_spawn_path.curve.get_closest_point(new_path_follow.global_position)
	new_path_follow.queue_free()
	
	var new_package = DELIVERY_PACKAGE_DATA.spawn_delivery_package(package_spawn_pos)
	print("Package: %s -> Path: %s -> Ratio: %.2f -> Pos: %s" % [new_package.name, random_spawn_path.name, random_ratio, package_spawn_pos])
