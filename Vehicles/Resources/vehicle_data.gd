extends Resource

const VAN_KIMEDERO = preload("res://Vehicles/van_kimedero.tscn")
const VAN_NYARAIN = preload("res://Vehicles/van_nyarain.tscn")

var vehicle_type: Vehicle
var delivery_team: Vehicle.DELIVERY_TEAM

var delivery_team_dict: Dictionary = {
	Vehicle.DELIVERY_TEAM.KIMEDERO: VAN_KIMEDERO,
	Vehicle.DELIVERY_TEAM.NYARAIN: VAN_NYARAIN,
}

var vehicle_scenes = [
	#LORRY_1, 
	#NISSAN_1, 
	#SEDAN_1, 
	#SMALL_CAR_1, 
	#FIAT_131, 
	#EVO_6, 
	#MATATU_1, 
	#MUSCLE_1,
	#SUV_1,
	#BUG_1,
	#HATCHBACK_1,
	#
	#CABBY,
	#CAVALCADE,
	#COGNOSCENTI,
	#COMET,
	#COQUETTE,
	#POLICE,
	#POLICE_2,
	#RANCHER,
	#TAXI,
	#TAXI_2,
	]

var vehicle_traffic_paths_array: Array
var vehicle_path_changers_array: Array

var vehicle_navigation_paths_array: Array
var vehicle_transition_paths_array: Array

# VEHICLE SPAWNING DATA
var vehicle_spawn: Node3D

## distance within which to spawn vehicles
var max_vehicle_spawn_distance: float = 160 # 125  # 64 # 250

## distance from which to despawn vehicles
var vehicle_despawn_distance: float = 200 # 160

@export var max_vehicles = 25 # 16 # 12 # 20 # 16 # 32
var current_vehicles: int = 0

var current_delivery_vehicle_array: Array

var current_vehicle: VehicleBody3D
var last_vehicle: VehicleBody3D

var generated_vehicles_dict: Dictionary

#var available_vehicles: Dictionary # Keeping track of a vehicle's various stats

# to signal to other nodes when a car is active
#signal vehicle_selected

func generate_random_vehicle() -> Vehicle:
	var random_vehicle: PackedScene = vehicle_scenes[randi() % vehicle_scenes.size()]
	return random_vehicle.instantiate()


func generate_random_numberplate() -> String:
	var rnd_numberplate: String = ""
	var letters = ["A", "B", "C", "D", "E", "F", "G", "H", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
	rnd_numberplate = "%s%s%s %s%s%s%s" % [
		"K", 
		letters[randi() % 5], 
		letters.pick_random(), 
		randi() % 10, randi() % 10,randi() % 10, 
		letters.pick_random()
		]
	return rnd_numberplate
