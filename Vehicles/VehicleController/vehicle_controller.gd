extends Node3D
class_name VehicleController

var VEHICLE_PATHFINDING = preload("res://Vehicles/Resources/vehicle_pathfinding.tres")

@onready var vehicle: Vehicle = get_parent()

var drive_input: float
var steer_input: float
var brake_input: float

## how many km/h above max_speed before force = 0
@export var speed_limiter_taper_zone: float = 2.0 

@onready var navigator: PathFollow3D = $PathFinder

var new_path: Path3D

@export_category("Target Reached")
@export var target_reached_max_stop: float = 8
var target_stop_delta: float

## NEW
@export var min_navigator_offset: float = 4

# the mode when the vehicle is on the transition path, about to join a connecting navigation path
var on_transition_path: bool = false

## the path to join next after going through a transition path
var next_navigation_path: Path3D
var transition_path: Path3D

var at_junction: bool = false ## triggers a slow-down at junctions

signal vehicle_at_junction(at_junction_bool: bool)
## NEW

@onready var info_label_3d: Label3D = $infoLabel3D

func _ready() -> void:
	vehicle.vehicle_controller = self
	
	## NEW
	vehicle_at_junction.connect(on_vehicle_at_junction)
	## NEW
	
	set_up_navigation()
	
	#match vehicle.vehicle_control:
		#Vehicle.VEHICLE_CONTROL.AUTO:
			#pass


func _physics_process(delta: float) -> void:
	match vehicle.vehicle_control:
		Vehicle.VEHICLE_CONTROL.AUTO:
			ai_process(delta)
		Vehicle.VEHICLE_CONTROL.MANUAL:
			manual_process(delta)
	
	info_label_3d.text = "%s\n%d KM/H\nOn Mission: %s\nTarget Reached: %s" % [
		vehicle.name,
		vehicle.current_speed_ms * 3.6, 
		#vehicle.at_junction, 
		vehicle.on_mission,
		vehicle.target_reached
		]


func _unhandled_input(_event: InputEvent) -> void:
	match vehicle.vehicle_control:
		Vehicle.VEHICLE_CONTROL.MANUAL:
			drive_input = Input.get_axis("back","forward")
			steer_input = Input.get_axis("turn_right","turn_left")
			brake_input = Input.get_action_strength("handbrake")


func ai_process(_delta: float):
	match vehicle.mission_mode:
		Vehicle.MissionMode.Roam:
			if on_transition_path:
				# when we are on a transition path we move the path follower to right in-front of the vehicle
				navigator.progress = vehicle.current_path.curve.get_closest_offset(vehicle.global_position) + vehicle.vehicle_front_distance
			else:
				# moving the navigating path follow forward with an offset
				navigator.progress = vehicle.current_path.curve.get_closest_offset(vehicle.global_position) + min_navigator_offset
			
			drive_input = 1.0
			steer_input = direction_to_angle(navigator.global_position)
			
			# what to when we get to the end of the path
			if is_zero_approx(1.0-navigator.progress_ratio):
				process_current_path_end(vehicle.current_path)
				
			vehicle.steering = clampf(deg_to_rad(vehicle.max_steer) * steer_input * 2.5, -1, 1)
			#vehicle.steering = deg_to_rad(vehicle.max_steer) * steer_input
			vehicle.engine_force = vehicle.horse_power * drive_input
			vehicle.brake = vehicle.brake_power * brake_input
			
		Vehicle.MissionMode.OnMission:
			if at_junction:
				if is_equal_approx(navigator.progress_ratio, 1.0):
					if not vehicle.on_mission: ## REMEMBER TO REMOVE THIS LINE
						switch_path(new_path)
			
			steer_input = ai_steer()
			drive_input = 1
			brake_input = 0
			
			speed_limiter_process(vehicle.max_speed)
			
			if at_junction:
				speed_limiter_process(40)
			
			#target_reached_process(delta)
			
			vehicle.steering = clampf(deg_to_rad(vehicle.max_steer) * steer_input * 2.5, -1, 1)
			#vehicle.steering = deg_to_rad(vehicle.max_steer) * steer_input
			vehicle.engine_force = vehicle.horse_power * drive_input
			vehicle.brake = vehicle.brake_power * brake_input


func manual_process(delta: float):
	vehicle.engine_force = drive_input * vehicle.horse_power
	vehicle.steering = lerp_angle(vehicle.steering, steer_input * deg_to_rad(vehicle.max_steer), vehicle.steer_speed * delta)
	vehicle.brake = lerpf(vehicle.brake, brake_input * vehicle.brake_power, vehicle.brake_speed * delta)


func ai_steer() -> float:
	navigator.progress = vehicle.navigation_path.curve.get_closest_offset(vehicle.global_position) + 4 # progress_offset
	return direction_to_angle(navigator.global_position)


func direction_to_angle(target_position: Vector3) -> float:
	# we get the direction we want to head towards
	#there's an opportunity to shift the target_position to the left when passing a slower vehicle here
	var _target_dir: Vector3 = vehicle.global_position.direction_to(target_position)
	var _cross: Vector3 = vehicle.global_transform.basis.z.cross(_target_dir)
	return vehicle.global_transform.basis.y.dot(_cross)


func set_up_navigation():
	vehicle.navigator = navigator
	
	assert(vehicle.current_path != null, "Vehicle path not set!")
	navigator.rotation_mode = PathFollow3D.ROTATION_ORIENTED
	
	navigator.name = "%s_navigator" % [vehicle.name]
	
	if vehicle.current_path.has_node("loop"):
		navigator.loop = true
	else:
		navigator.loop = false
	
	switch_path(vehicle.current_path)


func switch_path(next_path: Path3D):
	assert(next_path, "Next path not found!")
	navigator.reparent(next_path)
	
	vehicle.current_path = next_path
	
	navigator.progress = next_path.curve.get_closest_offset(vehicle.global_position)


func speed_limiter_process(target_speed: float):
	var current_speed: float = vehicle.current_speed_ms * 3.6
	var limit_factor: float = 1.0
	if current_speed >= target_speed:
		# How far past the cap are we?
		var speed_overshoot: float = current_speed - target_speed
		# Fade factor goes from 1 at max_speed → 0 at max_speed + taper_zone
		limit_factor = clamp(1.0 - (speed_overshoot / speed_limiter_taper_zone), 0.0, 1.0)
		#print("OS: %.1f -> %.1f" % [speed_overshoot, limit_factor])
		drive_input *= limit_factor
		brake_input = 1 - limit_factor


var last_target_position: Vector3
func target_reached_process(delta: float):
	if vehicle.target_reached:
		drive_input = 0
		brake_input = 1
		
		target_stop_delta += delta
		if target_stop_delta >= target_reached_max_stop:
			target_stop_delta = 0
			
			vehicle.target_reached = false
			vehicle.mission_vehicle = false
			
			# the mission path indicator is deleted
			if vehicle.mission_target_visualisation_path:
				vehicle.mission_target_visualisation_path.queue_free()
			
			# start another mission
			var mission_pos_dup: Array = vehicle.mission_positions_array.duplicate()
			if last_target_position in mission_pos_dup:
				mission_pos_dup.erase(last_target_position)
			var target_position: Vector3 = mission_pos_dup.pick_random()
			vehicle.activate_mission_to(target_position)
			last_target_position = target_position


## NEW
func process_current_path_end(current_path: Path3D) -> void:
	match vehicle.mission_mode:
		Vehicle.MissionMode.Roam:
			pick_random_navigation_path_at_junction(current_path)
		Vehicle.MissionMode.OnMission:
			#pick_specific_navigation_path_at_junction(current_path)
			pass


func pick_random_navigation_path_at_junction(curr_path: Path3D) -> void:
	# if vehicle is in a navigation path, when we get to the end of a path we 
	# should go switch to the on_transition_path mode
	if curr_path in VEHICLE_PATHFINDING.vehicle_navigation_paths_array:
		on_transition_path = true
		
		## an array of navigation paths connected to the current navigation path 
		## the vehicle is on, from which we can pick the next navigation path
		var connected_paths_array: Array = VEHICLE_PATHFINDING.connected_navigation_paths_dict[curr_path]
		
		# to avoid pesky U-turns
		if connected_paths_array.size() > 1:
			## the nearest navigation path to the current path we're on
			var twin_navigation_path: Path3D = VEHICLE_PATHFINDING.full_twin_navigation_paths_dict[curr_path]
			if twin_navigation_path in connected_paths_array:
				# we erase the nearest path to the current one we're on from the 
				# list of paths to choose from
				connected_paths_array.erase(twin_navigation_path)
		
		## random navigation path for vehicle to switch to 
		var random_next_navigation_path: Path3D = connected_paths_array.pick_random()
		
		# getting the transition path that connects the current navigation path 
		# to the random navigation path we have picked
		var connected_path_dict: Dictionary = VEHICLE_PATHFINDING.transition_paths_dict[curr_path]
		#print("Connected path dict: %s" % [connected_path_dict.size()])
		transition_path = connected_path_dict[random_next_navigation_path]
		#print("Transition path: %s" % [transition_path])
		
		next_navigation_path = random_next_navigation_path
	else:
		on_transition_path = false
	
	transfer_navigator_to_next_path(transition_path, next_navigation_path)


func transfer_navigator_to_next_path(incoming_transition_path: Path3D, next_main_path: Path3D) -> void:
	if on_transition_path:
		vehicle_at_junction.emit(true)
		
		vehicle.current_path = incoming_transition_path
	else:
		vehicle_at_junction.emit(false)
		
		vehicle.current_path = next_main_path
	navigator.reparent(vehicle.current_path)
	navigator.progress_ratio = 0


func on_vehicle_at_junction(at_junction_bool: bool) -> void:
	at_junction = at_junction_bool


## NEW
