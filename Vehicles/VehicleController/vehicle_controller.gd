extends Node3D
class_name VehicleController

@onready var vehicle: Vehicle = get_parent()

var drive_input: float
var steer_input: float
var brake_input: float

## how many km/h above max_speed before force = 0
@export var speed_limiter_taper_zone: float = 2.0 

@onready var path_finder: PathFollow3D = $PathFinder

var new_path: Path3D

@onready var info_label_3d: Label3D = $infoLabel3D

func _ready() -> void:
	vehicle.vehicle_controller = self
	
	match vehicle.vehicle_control:
		Vehicle.VEHICLE_CONTROL.AUTO:
			#set_up_navigation()
			pass


func _physics_process(delta: float) -> void:
	match vehicle.vehicle_control:
		Vehicle.VEHICLE_CONTROL.AUTO:
			ai_process(delta)
		Vehicle.VEHICLE_CONTROL.MANUAL:
			manual_process(delta)
	
	info_label_3d.text = "%d KM/H\nAt Junction: %s\nOn Mission: %s" % [
		vehicle.current_speed_ms * 3.6, 
		vehicle.at_junction, 
		vehicle.on_mission,
		]


func _unhandled_input(_event: InputEvent) -> void:
	match vehicle.vehicle_control:
		Vehicle.VEHICLE_CONTROL.MANUAL:
			drive_input = Input.get_axis("back","forward")
			steer_input = Input.get_axis("turn_right","turn_left")
			brake_input = Input.get_action_strength("handbrake")


func ai_process(_delta: float):
	if vehicle.at_junction:
		if is_equal_approx(path_finder.progress_ratio, 1.0):
			switch_path(new_path)
	
	steer_input = ai_steer()
	drive_input = 1
	brake_input = 0
	
	speed_limiter_process(vehicle.max_speed)
	
	if vehicle.at_junction:
		speed_limiter_process(40)
	
	#vehicle.steering = clampf(deg_to_rad(vehicle.max_steer) * steer_input * 2.5, -1, 1)
	vehicle.steering = deg_to_rad(vehicle.max_steer) * steer_input
	vehicle.engine_force = vehicle.horse_power * drive_input
	vehicle.brake = vehicle.brake_power * brake_input
	


func manual_process(delta: float):
	vehicle.engine_force = drive_input * vehicle.horse_power
	vehicle.steering = lerp_angle(vehicle.steering, steer_input * deg_to_rad(vehicle.max_steer), vehicle.steer_speed * delta)
	vehicle.brake = lerpf(vehicle.brake, brake_input * vehicle.brake_power, vehicle.brake_speed * delta)


func ai_steer() -> float:
	path_finder.progress = vehicle.navigation_path.curve.get_closest_offset(vehicle.global_position) + 4 # progress_offset
	return direction_to_angle(path_finder.global_position)


func direction_to_angle(target_position: Vector3) -> float:
	# we get the direction we want to head towards
	#there's an opportunity to shift the target_position to the left when passing a slower vehicle here
	var _target_dir: Vector3 = vehicle.global_position.direction_to(target_position)
	var _cross: Vector3 = vehicle.global_transform.basis.z.cross(_target_dir)
	return vehicle.global_transform.basis.y.dot(_cross)


func set_up_navigation():
	vehicle.path_finder = path_finder
	
	assert(vehicle.navigation_path != null, "Vehicle path not set!")
	path_finder.rotation_mode = PathFollow3D.ROTATION_ORIENTED
	
	path_finder.name = "%s_path_finder" % [vehicle.name]
	
	if vehicle.navigation_path.has_node("loop"):
		path_finder.loop = true
	else:
		path_finder.loop = false
	
	switch_path(vehicle.navigation_path)


func switch_path(next_path: Path3D):
	path_finder.reparent(next_path)
	
	vehicle.navigation_path = next_path
	
	path_finder.progress = next_path.curve.get_closest_offset(vehicle.global_position)


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
