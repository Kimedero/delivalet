extends Node3D
class_name CameraRig

@export var vehicle: VehicleBody3D

@onready var spring_arm: SpringArm3D = $SpringArm
@onready var camera: Camera3D = $SpringArm/Camera

@export var camera_sensitivity: float = 0.2

@export var camera_height = 1.5 # 2 # .5

var direction := Vector3.FORWARD
@export_range(1, 10, 0.1) var smooth_speed := 2.5

var camera_reset_delta: float
var camera_reset_timeout: float = 3.0

func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pass


func _physics_process(delta):
	if not vehicle:
		return
	vehicle_process(delta)


func vehicle_process(delta: float):
	global_position = vehicle.global_position + Vector3.UP * camera_height # VEHICLE_DATA.current_vehicle.camera_node.global_position
	var current_velocity: Vector3 = vehicle.linear_velocity
	current_velocity.y = 0
	if current_velocity.length_squared() > 1:
		direction = lerp(direction, current_velocity.normalized(), smooth_speed * delta)
		# set the rotation of the camera pivot to the direction we are moving towards
		# problem is we have a velocity vector and a rotation (basis)
	global_transform.basis = get_rotation_from_direction(direction)
	
	# if the camera is off-axis
	reset_camera_rotation(delta)


func _input(_event):
	#var mouse_movement = event as InputEventMouseMotion
	#if mouse_movement:
		##if camera_attachment is Character:
			##camera_attachment.rotation_degrees.y -= mouse_movement.relative.x * camera_sensitivity
		##else:
		#spring_arm.rotation_degrees.y -= mouse_movement.relative.x * camera_sensitivity
		#spring_arm.rotation_degrees.x -= mouse_movement.relative.y * camera_sensitivity
		#spring_arm.rotation_degrees.x = clamp(spring_arm.rotation_degrees.x, -75, 45)
		#
		#camera_reset_delta = 0
	pass


func get_rotation_from_direction(look_direction : Vector3) -> Basis:
	# to reverse the camera you can negate the look_direction
	look_direction = look_direction.normalized()
	var x_axis = look_direction.cross(Vector3.UP)
	return Basis(x_axis, Vector3.UP, -look_direction)


func reset_camera_rotation(delta):
	if not is_zero_approx(spring_arm.rotation.y):
		camera_reset_delta += delta
	
	if camera_reset_delta >= camera_reset_timeout:
		spring_arm.rotation.y = lerp_angle(spring_arm.rotation.y, 0.0, 5 * delta)
		if is_zero_approx(spring_arm.rotation.y):
			camera_reset_delta = 0
