extends Node3D

var GAME_DATA = preload("res://Resources/game_data.tres")
var VEHICLE_DATA = preload("res://Vehicles/Resources/vehicle_data.tres")
var VEHICLE_PATHFINDING = preload("res://Vehicles/Resources/vehicle_pathfinding.tres")
var DELIVERY_PACKAGE_DATA = preload("res://DeliveryPackages/Resources/delivery_package_data.tres")
var MINI_MAP_STATS = preload("res://Minimap/Resources/mini_map_stats.tres")

const CAMERA_RIG = preload("res://Camera/camera_rig.tscn")

@export var vehicles_spawn: Node3D

@export var vehicle_path_changers: Node3D
@export var vehicle_paths: Node3D

@export var navigation_path_holder: Node

## where delivery packages spawn
@export var delivery_package_spawn_node: Node

## where the player spawns
@export var player_spawn_node: Node3D
## where other vehicles spawn
@export var delivery_vehicles_spawn: Dictionary[Node3D, Vehicle.DELIVERY_TEAM]

## where the camera spawns
@export var camera_spawn_node: Node3D

@export var minimap_node: Minimap

@onready var info_label: Label = $infoLabel

func _ready() -> void:
	randomize()
	
	assert(vehicle_paths, "Vehicle paths not set at %s!" % [self])
	assert(vehicles_spawn, "Vehicles spawn not set at %s!" % [self])
	assert(vehicle_path_changers, "Vehicle path changers not set at %s!" % [self])
	assert(vehicle_paths, "Vehicle paths not set at %s!" % [self])
	assert(navigation_path_holder, "Navigation path holder not set at %s!" % [self])
	assert(delivery_package_spawn_node, "Delivery package spawn node not set at %s!" % [self])
	assert(player_spawn_node, "Player spawn node not set at %s!" % [self])
	assert(delivery_vehicles_spawn, "Delivery vehicles spawn not set at %s!" % [self])
	assert(camera_spawn_node, "Camera spawn node not set at %s!" % [self])
	assert(minimap_node, "Minimap node not set at %s!" % [self])
	
	VEHICLE_DATA.vehicle_spawn = vehicles_spawn
	
	VEHICLE_DATA.vehicle_traffic_paths_array = vehicle_paths.get_children()
	VEHICLE_PATHFINDING.vehicle_traffic_paths_array = vehicle_paths.get_children()
	
	VEHICLE_DATA.vehicle_path_changers_array = vehicle_path_changers.get_children()
	VEHICLE_PATHFINDING.vehicle_path_changers_array = vehicle_path_changers.get_children()
	
	if navigation_path_holder:
		VEHICLE_PATHFINDING.navigation_path_holder_node = navigation_path_holder
	
	DELIVERY_PACKAGE_DATA.delivery_package_spawn_node = delivery_package_spawn_node
	
	set_vehicle_path_changer_linked_paths()
	set_path_changers_neighbours()
	
	assert(not VEHICLE_PATHFINDING.vehicle_path_changers_array.is_empty(), "We do not have vehicle path changers set at %s!" % [self])
	VEHICLE_PATHFINDING.add_navigation_points()
	VEHICLE_PATHFINDING.connect_navigation_points()
	
	spawn_original_delivery_packages()
	
	spawn_delivery_vehicles()


func _process(_delta: float) -> void:
	info_label.text = "Packages: %s" % [DELIVERY_PACKAGE_DATA.delivery_packages_array.size()]


func set_vehicle_path_changer_linked_paths():
	for path_changer: VehiclePathChanger in vehicle_path_changers.get_children():
		for vehicle_path: Path3D in vehicle_paths.get_children():
			var path_start_pos: Vector3 = GAME_DATA.flatten_vec3(vehicle_path.curve.get_point_position(0))
			
			var path_changer_pos: Vector3 = GAME_DATA.flatten_vec3(path_changer.global_position)
			#print("%s: %s -> %s" % [path_changer.name, path_changer_pos, path_follow_pos])
			var nearest_point_on_path: Vector3 = GAME_DATA.flatten_vec3(vehicle_path.curve.get_closest_point(path_changer_pos))
			var distance_to_path: float = nearest_point_on_path.distance_squared_to(path_changer_pos)
			var distance_to_path_start_pos: float = path_start_pos.distance_squared_to(path_changer_pos)
			if distance_to_path <= pow(path_changer.get_area_radius(), 2) and distance_to_path_start_pos <= pow(path_changer.get_area_radius(), 2):
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
					if distance_to_vehicle_path_changer <= pow(vehicle_path_changer.get_area_radius(), 2):
						current_vehicle_path_changer.neighbour_path_changers_array.append(vehicle_path_changer)
					
		#print("%s -> Neighbours: %s" % [current_vehicle_path_changer.name, current_vehicle_path_changer.neighbour_path_changers_array])


func spawn_original_delivery_packages():
	for package in DELIVERY_PACKAGE_DATA.max_delivery_packages:
		spawn_delivery_package()


func spawn_delivery_package():
	var random_spawn_path: Path3D = vehicle_paths.get_children().pick_random()
	var random_ratio := randf_range(0.1, 0.9)
	
	var new_path_follow := PathFollow3D.new()
	random_spawn_path.add_child(new_path_follow)
	
	new_path_follow.progress_ratio = random_ratio
	var package_spawn_pos: Vector3 = random_spawn_path.curve.get_closest_point(new_path_follow.global_position)
	new_path_follow.queue_free()
	
	var new_package: DeliveryPackage = DELIVERY_PACKAGE_DATA.spawn_delivery_package(package_spawn_pos, random_spawn_path)
	
	new_package.package_picked.connect(on_delivery_packaged_picked)
	for vehicle: Vehicle in VEHICLE_DATA.current_delivery_vehicle_array:
		new_package.package_picked.connect(vehicle.on_delivery_packaged_update)
		##print("Vehiko: %s" % [vehicle])
	print("%s spawned on %s at %s at ratio: %.2f" % [new_package.name, random_spawn_path.name, package_spawn_pos, random_ratio])


func on_delivery_packaged_picked(_picked_delivery_package: DeliveryPackage, _picked_vehicle: Vehicle):
	if DELIVERY_PACKAGE_DATA.delivery_packages_array.size() < DELIVERY_PACKAGE_DATA.max_delivery_packages:
		spawn_delivery_package()


func spawn_vehicle(spawn_transform: Transform3D, spawn_path: Path3D, vehicle_type: Vehicle.VEHICLE_TYPE = Vehicle.VEHICLE_TYPE.DELIVERY, vehicle_team: Vehicle.DELIVERY_TEAM = Vehicle.DELIVERY_TEAM.KIMEDERO, vehicle_control: Vehicle.VEHICLE_CONTROL = Vehicle.VEHICLE_CONTROL.AUTO) -> Vehicle:
	var new_vehicle: Vehicle
	match vehicle_type:
		Vehicle.VEHICLE_TYPE.DELIVERY:
			new_vehicle = VEHICLE_DATA.delivery_team_dict[vehicle_team].instantiate()
			new_vehicle.delivery_team = vehicle_team
		Vehicle.VEHICLE_TYPE.TRAFFIC:
			pass
	
	new_vehicle.navigation_path = spawn_path
	new_vehicle.vehicle_control = vehicle_control
	vehicles_spawn.add_child(new_vehicle)
	new_vehicle.global_transform = spawn_transform
	
	#match vehicle_type:
		#Vehicle.VEHICLE_TYPE.DELIVERY:
			#match vehicle_team:
				#Vehicle.DELIVERY_TEAM.KIMEDERO:
					#new_vehicle.minimap_icon = "teammate"
				#Vehicle.DELIVERY_TEAM.NYARAIN:
					#new_vehicle.minimap_icon = "opponent"
			#MINI_MAP_STATS.emit_signal("add_minimap_object", new_vehicle)
	
	return new_vehicle


func spawn_player_vehicle(spawn_transform: Transform3D, spawn_path: Path3D):
	## remember to change the vehicle control for the player to manual
	var player_vehicle: Vehicle = spawn_vehicle(spawn_transform, spawn_path, Vehicle.VEHICLE_TYPE.DELIVERY, Vehicle.DELIVERY_TEAM.KIMEDERO, Vehicle.VEHICLE_CONTROL.AUTO)
	player_vehicle.name = "Player"
	
	var new_camera_rig: CameraRig = CAMERA_RIG.instantiate()
	camera_spawn_node.add_child(new_camera_rig)
	new_camera_rig.vehicle = player_vehicle
	
	if minimap_node:
		minimap_node.vehicle = player_vehicle


func spawn_delivery_vehicles():
	assert(player_spawn_node, "Player spawn node not set!")
	var player_transform: Transform3D = player_spawn_node.global_transform
	var nearest_path_to_player: Path3D = VEHICLE_PATHFINDING.get_two_nearest_paths(player_transform.origin)[0]
	spawn_player_vehicle(player_transform, nearest_path_to_player)
	
	for spawn_node in delivery_vehicles_spawn.keys():
		var vehicle_transform: Transform3D = spawn_node.global_transform
		var nearest_path: Path3D = VEHICLE_PATHFINDING.get_two_nearest_paths(vehicle_transform.origin)[0]
		match delivery_vehicles_spawn[spawn_node]:
			Vehicle.DELIVERY_TEAM.KIMEDERO:
				var new_kimedero_vehicle: Vehicle = spawn_vehicle(vehicle_transform, nearest_path, Vehicle.VEHICLE_TYPE.DELIVERY, Vehicle.DELIVERY_TEAM.KIMEDERO)
				new_kimedero_vehicle.name = "Kimedero_1"
			Vehicle.DELIVERY_TEAM.NYARAIN:
				var new_nyarain_vehicle: Vehicle = spawn_vehicle(vehicle_transform, nearest_path, Vehicle.VEHICLE_TYPE.DELIVERY, Vehicle.DELIVERY_TEAM.NYARAIN)
				new_nyarain_vehicle.name = "Nyarain_1"
