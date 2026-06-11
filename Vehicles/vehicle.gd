extends VehicleBody3D
class_name Vehicle

var GAME_DATA = preload("res://Resources/game_data.tres")
var VEHICLE_DATA = load("res://Vehicles/Resources/vehicle_data.tres")
var VEHICLE_PATHFINDING = preload("res://Vehicles/Resources/vehicle_pathfinding.tres")
var DELIVERY_PACKAGE_DATA = preload("res://DeliveryPackages/Resources/delivery_package_data.tres")

var MINI_MAP_STATS = preload("res://Minimap/Resources/mini_map_stats.tres")
var minimap_icon: String # = "teammate"

enum VEHICLE_CONTROL {AUTO, MANUAL}

@export var vehicle_control: VEHICLE_CONTROL

@export var delivery_vehicle: bool = true

var vehicle_controller: VehicleController

var current_path: Path3D = null
var navigator: PathFollow3D = null ## the node that controls the vehicle's steering
#var path_explorer: PathFollow3D = null

## vehicle types
enum VEHICLE_TYPE {
	DELIVERY, 
	TRAFFIC,
	}
enum DELIVERY_TEAM {
	KIMEDERO, 
	NYARAIN,
	}
var delivery_team: DELIVERY_TEAM

enum MissionMode {Stop, Roam, OnMission, Park}
@export var mission_mode: MissionMode = MissionMode.Roam

@export_category("Drive")
@export var horse_power: float = 1250

@export_category("Steering")
@export var max_steer: float = 36 # 45
@export var steer_speed: float = 25

@export_category("Brakes")
@export var brake_power: float = 40
@export var brake_speed: float = 40

var current_speed_ms: float
@export var max_speed: float = 80 # 100 # in km/h 

@export_category("Navigation")
## where to place the navigator in junctions
@export var vehicle_front: Marker3D
## the distance from the middle of the vehicle to the vehicle front
var vehicle_front_distance: float

@export_category("Pathfinding")
signal vehicle_at_path_changer
var on_mission: bool = false
#var at_junction: bool = false ## triggers a slow-down at junctions
## when we try to activate a mission but fail due to vehicle location
var activate_mission_at_next_junction: bool

var reversing: bool = false

## the position to the target delivery package
var current_delivery_package_position: Vector3
## when we pick a target
var target_reached: bool = false
 ## the distance at which to consider a delivery package picked
@export var target_reached_distance: float = 8
## when a target is picked, we calculate the nearest vehicle targets for each vehicle
var targets_updated: bool = false
## when we're at the final path to delivery package
var final_approach: bool

## NEW

## NEW


func _ready() -> void:
	#vehicle_at_path_changer.connect(on_vehicle_at_path_changer)
	
	## NEW
	assert(vehicle_front, "Vehicle front is not set at %s!" % [self])
	
	vehicle_front_distance = self.global_position.distance_to(self.vehicle_front.global_position)
	## NEW
	
	## to keep track of delivery vehicles
	if delivery_vehicle:
		VEHICLE_DATA.current_delivery_vehicle_array.append(self)
		
	match delivery_team:
		DELIVERY_TEAM.KIMEDERO:
			minimap_icon = "teammate"
		DELIVERY_TEAM.NYARAIN:
			minimap_icon = "opponent"
	
	MINI_MAP_STATS.emit_signal("add_minimap_object", self)


func _physics_process(_delta: float) -> void:
	current_speed_ms = linear_velocity.length()


#func on_vehicle_at_path_changer(current_path_changer: VehiclePathChanger, vehicle_entered: bool):
	#if vehicle_entered:
		#at_junction = true
		#
		#if on_mission:
			#process_mission(current_path_changer)
			#
			##final_approach_process(current_path_changer)
			#pass
		#else:
			#process_roam(current_path_changer)
	#else:
		#at_junction = false


func process_mission(_current_pathchanger: VehiclePathChanger):
	pass


func process_roam(current_path_changer: VehiclePathChanger):
	var linked_path_array_dup: Array = current_path_changer.linked_paths_array.duplicate()
	if current_path in linked_path_array_dup:
		#print("Nav path in linked path array dup!")
		linked_path_array_dup.erase(current_path)
	var new_path: Path3D = linked_path_array_dup.pick_random()
	vehicle_controller.new_path = new_path


func on_delivery_packaged_update(picked_delivery_package: DeliveryPackage, picked_vehicle: Vehicle):
	# we also update vehicle target positions here
	if picked_vehicle == self:
		print("%s picked %s!" % [picked_vehicle.name, picked_delivery_package.name])


# keeps track of each delivery package so as to avoid calculating these properties again
var delivery_package_properties_dict: Dictionary
func process_nearest_package():
	#var two_nearest_paths_to_vehicle: Array = VEHICLE_PATHFINDING.get_two_nearest_paths(self.global_position)
	for delivery_package: DeliveryPackage in DELIVERY_PACKAGE_DATA.delivery_packages_array:
		# we should first check that the package is legit
		if is_instance_valid(delivery_package):
			var two_nearest_paths_to_package: Array = VEHICLE_PATHFINDING.get_two_nearest_paths(delivery_package.global_position)
			delivery_package_properties_dict[delivery_package] = two_nearest_paths_to_package


func navigate_to_nearest_package():
	## we get the position of the nearest package
	current_delivery_package_position = get_nearest_delivery_package_position()
	## then we figure out which path takes us closest to target position
	var navigation_path_to_delivery_package_array: Array = VEHICLE_PATHFINDING.fetch_astar_navigation_path(self.global_position, current_delivery_package_position)
	print("%s's nearest delivery package position: %s -> Navigation Path: %s" % [self.name, current_delivery_package_position, navigation_path_to_delivery_package_array])
	process_generated_path(navigation_path_to_delivery_package_array, current_delivery_package_position)
	

func get_nearest_delivery_package_position() -> Vector3:
	#1. Search for nearest packages
	#2. Choose nearest package
	var package_distance_dict: Dictionary = {}
	# we calculate the navigation distance to the packages
	# but first, just the direct distances
	for package in DELIVERY_PACKAGE_DATA.delivery_packages_array:
		var dist_to_package: float = self.global_position.distance_squared_to(package.global_position)
		package_distance_dict[dist_to_package] = package
	var package_distance_array: Array = package_distance_dict.keys()
	package_distance_array.sort()
	return package_distance_dict[package_distance_array[0]].global_position
	

### A dictionary with a set of path changers leading from the vehicle's current position to a package
#var mission_path_changer_dict: Dictionary
#var mission_target_two_nearest_paths_array: Array
func process_generated_path(generated_navigation_path_array: Array, target_position: Vector3):
	var pathchanger_and_linked_path_dict: Array = generate_pathchanger_and_linked_path_dict(generated_navigation_path_array, target_position)
	print("PCLPD: %s" % [pathchanger_and_linked_path_dict])


func generate_pathchanger_and_linked_path_dict(generated_navigation_path_array: Array, target_position: Vector3) -> Array:
	## we generate a dictionary with pathchanger keys and linked path values
	## NOTE: if the navigation path array only has one entry, we will get an 
	## empty path changer dictionary, which means the package is in the nearest
	## or next nearest path from our position
	## An error would have occured if the navigation path array was empty
	
	## the two nearest paths to the vehicle
	var two_nearest_start_paths_array: Array = VEHICLE_PATHFINDING.get_two_nearest_paths(self.global_position)
	print("Two nearest paths to vehicle array: %s" % [two_nearest_start_paths_array])
	
	## the two nearest paths to the target position -> if we're on either of 
	## these paths we are in the final stretch 
	var two_nearest_paths_to_target_array: Array = VEHICLE_PATHFINDING.get_two_nearest_paths(target_position)
	print("Two nearest paths to target array: %s" % [two_nearest_paths_to_target_array])
	
	#print("Gen Nav Path Arr: %s -> %s" % [generated_navigation_path_array.size(), generated_navigation_path_array])
	## an array of the pathchangers to use from vehicle to target
	var path_changer_array: Array = VEHICLE_PATHFINDING.convert_navigation_path_points_to_pathchangers(generated_navigation_path_array)
	
	## a dictionary of pathchangers with the path to use to reach the next one
	var path_changer_dict: Dictionary = {}
	
	## array of paths in order from start to target
	var paths_array: Array = []
	
	for idx: int in generated_navigation_path_array.size():
		# we figure out what path connects each path changer to the next
		if idx + 1 < generated_navigation_path_array.size():
			var path_changer_a: VehiclePathChanger = path_changer_array[idx] 
			var path_changer_b: VehiclePathChanger = path_changer_array[idx + 1]
			## we want to check what path connects PathChangerA to PathChangerB
			var near_path: Path3D = null
			for linked_path: Path3D in path_changer_a.linked_paths_array:
				##print("Point Count: %s" % [linked_path.curve.get_point_count()])
				var linked_path_end_pos: Vector3 = GAME_DATA.flatten_vec3(linked_path.curve.get_point_position(linked_path.curve.point_count - 1))
				var dist_squared_to_path_changer_b: float = linked_path_end_pos.distance_squared_to(GAME_DATA.flatten_vec3(path_changer_b.global_position))
				if dist_squared_to_path_changer_b <= pow(path_changer_b.area_radius, 2):
					path_changer_dict[path_changer_a] = linked_path
					paths_array.append(linked_path)
					near_path = linked_path
			#print("PC A: %s > PC B: %s -> %s" % [path_changer_a.name, path_changer_b.name, near_path.name])
	return [path_changer_dict, paths_array, two_nearest_start_paths_array, two_nearest_paths_to_target_array]


## NEW


## NEW
