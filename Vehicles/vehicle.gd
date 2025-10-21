extends VehicleBody3D
class_name Vehicle

var GAME_DATA = preload("res://Resources/game_data.tres")
var VEHICLE_DATA = preload("res://Vehicles/Resources/vehicle_data.tres")
var VEHICLE_PATHFINDING = preload("res://Vehicles/Resources/vehicle_pathfinding.tres")
var DELIVERY_PACKAGE_DATA = preload("res://DeliveryPackages/Resources/delivery_package_data.tres")

var MINI_MAP_STATS = preload("res://Minimap/Resources/mini_map_stats.tres")
var minimap_icon: String # = "teammate"

enum VEHICLE_CONTROL {AUTO, MANUAL}

@export var vehicle_control: VEHICLE_CONTROL

@export var delivery_vehicle: bool = true

var vehicle_controller: VehicleController

var navigation_path: Path3D = null
var path_finder: PathFollow3D = null ## the node that controls the vehicle's steering
var path_explorer: PathFollow3D = null

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

@export_category("Pathfinding")
signal vehicle_at_path_changer
var on_mission: bool = false
var at_junction: bool = false ## triggers a slow-down at junctions
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


func _ready() -> void:
	vehicle_at_path_changer.connect(on_vehicle_at_path_changer)
	
	## to keep track of delivery vehicles
	if delivery_vehicle:
		VEHICLE_DATA.current_delivery_vehicle_array.append(self)
	
	match delivery_team:
		DELIVERY_TEAM.KIMEDERO:
			minimap_icon = "teammate"
		DELIVERY_TEAM.NYARAIN:
			minimap_icon = "opponent"
	
	MINI_MAP_STATS.emit_signal("add_minimap_object", self)
	#MINI_MAP_STATS.minimap_objects.append(self)


func _physics_process(_delta: float) -> void:
	current_speed_ms = linear_velocity.length()
	
	#if delivery_vehicle:
		###3. Navigate to nearest package
		#if not on_mission: # and not target_reached:
			#navigate_to_nearest_package()
			#on_mission = true
	##
			####we figure out the delivery package path finding here
			###on_mission = true
			
	#if final_approach:
		#var nearest_point_on_path_to_target: Vector3 = navigation_path.curve.get_closest_point(current_delivery_package_position)
		#var distance_squared_to_target_position_on_path: float = GAME_DATA.flatten_vec3(global_position).distance_squared_to(GAME_DATA.flatten_vec3(nearest_point_on_path_to_target))
		#if distance_squared_to_target_position_on_path <= target_reached_distance:
			#target_reached = true
			#final_approach = false
			#print("Target reached!")
	

func on_vehicle_at_path_changer(current_path_changer: VehiclePathChanger, vehicle_entered: bool):
	if vehicle_entered:
		at_junction = true
		
		if on_mission:
			##sometimes when we try to activate a mission in maybe a tunnel wires
			##get crossed. So we set the vehicle on the nearest path and try to 
			##activate the mission at the nearest junction
			#if activate_mission_at_next_junction:
				#activate_mission_to(mission_target_position)
				#activate_mission_at_next_junction = false
			
			process_mission(current_path_changer)
			
			#final_approach_process(current_path_changer)
			pass
		else:
			process_roam(current_path_changer)
	else:
		at_junction = false


## to figure out which path to choose
func process_mission(_current_pathchanger: VehiclePathChanger):
	#if current_pathchanger in mission_path_changer_dict.keys():
		#var next_path: Path3D = mission_path_changer_dict[current_pathchanger]
		#vehicle_controller.new_path = next_path
	pass


func process_roam(current_path_changer: VehiclePathChanger):
	var linked_path_array_dup: Array = current_path_changer.linked_paths_array.duplicate()
	if navigation_path in linked_path_array_dup:
		#print("Nav path in linked path array dup!")
		linked_path_array_dup.erase(navigation_path)
	var new_path: Path3D = linked_path_array_dup.pick_random()
	vehicle_controller.new_path = new_path


func on_delivery_packaged_update(picked_delivery_package: DeliveryPackage, picked_vehicle: Vehicle):
	# we also update vehicle target positions here
	if picked_vehicle == self:
		print("%s picked %s!" % [picked_vehicle.name, picked_delivery_package.name])


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
	
	## paths array gives us an array of paths to follow from one path changer to another
	#print("Paths Array: %s" % [paths_array])
	## mission path cahnger dict gives us a dictionary of path changer with reference to what paths 
	## to choose when we hit those path changers
	#print("Path changer Dict: %s" % [mission_path_changer_dict])
#
	## checking for the start path road loop-back
	## we test if the navigation path has more than 1 entries
	##WE ALSO NEED TO FIGURE OUT HOW TO HANDLE A NEARBY TARGET AND PARK
	#var nearest_start_path: Path3D = two_nearest_start_paths_array[0]
	#var next_nearest_start_path: Path3D = two_nearest_start_paths_array[1]
	#var nearest_finish_path: Path3D = mission_target_two_nearest_paths_array[0]
	#var next_nearest_finish_path: Path3D = mission_target_two_nearest_paths_array[1]
	#if not generated_navigation_path_array.is_empty(): # size() > 1:
		### in  situation where the start path is also the end path or the next nearest end path
		#if nearest_start_path in mission_target_two_nearest_paths_array:
			#var vehicle_progress: float = nearest_start_path.curve.get_closest_offset(self.global_position)
			#if nearest_start_path == nearest_finish_path:
				## we need to check if we need to switch to next nearest path, if 
				## the target position is behind the vehicle
				#var target_nearest_finish_path_progress: float = nearest_finish_path.curve.get_closest_offset(current_delivery_package_position)
				#final_approach = true
				#if vehicle_progress > target_nearest_finish_path_progress:
					#vehicle_controller.switch_path(next_nearest_start_path)
				#else:
					#vehicle_controller.switch_path(nearest_start_path)
				#print("Nearest path is also the nearest finish path")
			#elif nearest_start_path == next_nearest_finish_path:
				#var target_next_nearest_finish_path_progress: float = next_nearest_finish_path.curve.get_closest_offset(current_delivery_package_position)
				#final_approach = true
				#if vehicle_progress > target_next_nearest_finish_path_progress:
					#vehicle_controller.switch_path(nearest_finish_path)
				#else:
					#vehicle_controller.switch_path(nearest_start_path)
				#print("Nearest path is also the next nearest finish path")
		### in a situation where we have to loop back on the same road we start 
		### on, the nearest path or the next nearest path will be in the path 
		### array, usually as the first entry in the paths array
		#elif (nearest_start_path in paths_array) or (next_nearest_start_path in paths_array):
			## it means we can skip going to the first path changer and just 
			## switch to the first path changer's path instead
			#var first_path_changer_path: Path3D = mission_path_changer_dict[path_changer_array[0]]
			#vehicle_controller.switch_path(first_path_changer_path)
		### in a situation where the nearest start path is in the linked path 
		### array of the first path changer which means the current path will not 
		### lead us to the first path changer we switch to the next nearest path
		#elif nearest_start_path in path_changer_array[0].linked_paths_array:
			#vehicle_controller.switch_path(next_nearest_start_path)
		##elif nearest_start_path not in path_changer_array[0].linked_paths_array:
			##vehicle_controller.switch_path(nearest_start_path)
			##print("Current path is not linked to the")
		### in a situation where the next nearest path is in the next path 
		### changer's linkes paths array it means that next nearest path cannot lead
		### us to the path changer and so we swith to the nearest path
		#elif next_nearest_start_path in path_changer_array[0].linked_paths_array:
			##SOLVED: BUG: the nearest path doesn't necessarily always lead to a path changer that will take 
			##us straight to the right paths. We need to test for that somehow..
			#vehicle_controller.switch_path(nearest_start_path)
		#else:
			##here we set a flag to activate mission at the next vehicle path changer encountered
			#print("Unique situation! Check logs!")
			#activate_mission_at_next_junction = true
			#vehicle_controller.switch_path(nearest_start_path)
	##elif generated_navigation_path_array.size() == 1:
		### this means we are either on the same path as the target, on the next
		###nearest path, or heading to the path changer will lead us to the target 
		##print("We are already on the target path or in the next nearest path")
	#else:
		#print("No mission path generated!")	
#
#
#func final_approach_process(current_path_changer: VehiclePathChanger):
	#var nearest_path_to_target: Path3D = mission_target_two_nearest_paths_array[0]
	#var next_nearest_path_to_target: Path3D = mission_target_two_nearest_paths_array[1]
	### in a situation where the current path we're on is one of either the 
	### nearest or next nearest paths we enter final approach mode
	#if navigation_path == nearest_path_to_target or navigation_path == next_nearest_path_to_target:
		#final_approach = true
	### in a situation where the nearest path to a target is linked to the 
	### current path changer we should switch to it to get to the target
	#elif (nearest_path_to_target in current_path_changer.linked_paths_array):
		##switch to the path
		#vehicle_controller.switch_path(nearest_path_to_target)
		#final_approach = true
	### in a situation where the next nearest path to a target is linked to the 
	### current path changer we should switch to it to get to the target
	#elif (next_nearest_path_to_target in current_path_changer.linked_paths_array):
		#vehicle_controller.switch_path(next_nearest_path_to_target)
		#final_approach = true
	#


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
			var near_path: Path3D
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
	
