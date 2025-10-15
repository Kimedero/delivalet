extends VehicleBody3D
class_name Vehicle

var VEHICLE_PATHFINDING = load("res://Vehicles/Resources/vehicle_pathfinding.tres")

enum VEHICLE_CONTROL {AUTO, MANUAL}

@export var vehicle_control: VEHICLE_CONTROL

var vehicle_controller: VehicleController

var navigation_path: Path3D = null
var path_finder: PathFollow3D = null ## the node that controls the vehicle's steering
var path_explorer: PathFollow3D = null

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


func _ready() -> void:
	vehicle_at_path_changer.connect(on_vehicle_at_path_changer)


func _physics_process(_delta: float) -> void:
	current_speed_ms = linear_velocity.length()
	
	if not navigation_path:
		var two_nearest_paths_array: Array = VEHICLE_PATHFINDING.get_two_nearest_paths(self.global_position)
		navigation_path = two_nearest_paths_array[0]
		#print("Navigation path: %s" % [navigation_path])
		vehicle_controller.set_up_navigation()


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
			#
			#process_mission(current_path_changer)
			#
			#final_approach_process(current_path_changer)
			pass
		else:
			process_roam(current_path_changer)
	else:
		at_junction = false


func process_roam(current_path_changer: VehiclePathChanger):
	var linked_path_array_dup: Array = current_path_changer.linked_paths_array.duplicate()
	if navigation_path in linked_path_array_dup:
		#print("Nav path in linked path array dup!")
		linked_path_array_dup.erase(navigation_path)
	var new_path: Path3D = linked_path_array_dup.pick_random()
	vehicle_controller.new_path = new_path
