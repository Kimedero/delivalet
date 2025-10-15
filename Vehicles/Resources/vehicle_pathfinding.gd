extends Resource

## The resource that hold the settings for vehicle path-finding

## the array that holds traffic paths
var vehicle_traffic_paths_array: Array

## the array that holds traffic path changers
var vehicle_path_changers_array: Array


## vehicle path-finding node
var a_star: AStar3D = AStar3D.new()

var path_changers_points_dict: Dictionary[VehiclePathChanger, Dictionary]
var point_to_area_dict: Dictionary

var navigation_path_holder_node: Node3D

func add_navigation_points():
	for vehicle_path_changer: VehiclePathChanger in vehicle_path_changers_array:
		add_navigation_point(vehicle_path_changer)


func add_navigation_point(vehicle_path_changer: VehiclePathChanger):
	var vehicle_path_changer_position: Vector3 = vehicle_path_changer.global_position
	var available_id: int = a_star.get_available_point_id()
	a_star.add_point(available_id, vehicle_path_changer_position)
	
	path_changers_points_dict[vehicle_path_changer]  = {
		"specific_point": 	vehicle_path_changer_position, 
		"id": 				available_id
		}


func connect_navigation_points():
	for vehicle_path_changer: VehiclePathChanger in path_changers_points_dict:
		for neighbour_path_changer: VehiclePathChanger in vehicle_path_changer.neighbour_path_changers_array:
			var current_id: int = path_changers_points_dict[vehicle_path_changer]["id"]
			var neighbour_id: int = path_changers_points_dict[neighbour_path_changer]["id"]
			if not a_star.are_points_connected(current_id, neighbour_id):
				a_star.connect_points(current_id, neighbour_id)
			
	query_area_node_from_point()


func query_area_node_from_point():
	# we want to scan through the points dictionary to find the specific points of the path and convert them back to references to pathChangers first
	for point in path_changers_points_dict:
		point_to_area_dict[path_changers_points_dict[point].specific_point] = point


func fetch_astar_navigation_path(start_pos: Vector3, end_pos: Vector3) -> Array:
	var start_position: int = a_star.get_closest_point(start_pos)
	var end_position: int = a_star.get_closest_point(end_pos)
	return a_star.get_point_path(start_position, end_position)


func generate_navigation_path_indicator(navigation_path_array: Array, start_pos: Vector3, end_pos: Vector3) -> Path3D:
	assert(navigation_path_holder_node, "Navigation path holder node not set!")
	var new_path := Path3D.new()
	new_path.curve = Curve3D.new()
	navigation_path_holder_node.add_child(new_path)
	
	new_path.curve.clear_points()
	new_path.curve.add_point(start_pos)
	for point: Vector3 in navigation_path_array:
		new_path.curve.add_point(point)
	new_path.curve.add_point(end_pos)
	
	var new_csg_polygon := CSGPolygon3D.new()
	new_path.add_child(new_csg_polygon)
	new_csg_polygon.global_position = Vector3.UP * 2
	new_csg_polygon.polygon = PackedVector2Array(
			[
				Vector2(-0.1, 0.0),
				Vector2(-0.1, 0.5),
				Vector2(0.1, 0.5),
				Vector2(0.1, 0.0),
			]
		)
	new_csg_polygon.mode = CSGPolygon3D.MODE_PATH
	new_csg_polygon.path_node = new_path.get_path()
	new_csg_polygon.name = "%s_CSGPolygon3D" % [new_path.name]
	
	var new_standard_material := StandardMaterial3D.new()
	new_standard_material.albedo_color = Color(randf(), randf(), randf(), 1.0)
	new_csg_polygon.material = new_standard_material
	
	return new_path


func generate_target_indicator(target_pos: Vector3) -> Node3D:
	var new_node := Node3D.new()
	navigation_path_holder_node.add_child(new_node)
	new_node.global_position = target_pos
	
	var new_mesh_instance := MeshInstance3D.new()
	new_node.add_child(new_mesh_instance)
	new_mesh_instance.position = Vector3.UP * 2
	
	var new_cylinder_mesh := CylinderMesh.new()
	new_cylinder_mesh.bottom_radius = 0
	new_cylinder_mesh.top_radius = 2
	new_cylinder_mesh.height = 4
	new_cylinder_mesh.rings = 0
	new_cylinder_mesh.radial_segments = 6
	new_mesh_instance.mesh = new_cylinder_mesh
	
	var new_standard_material := StandardMaterial3D.new()
	new_standard_material.albedo_color = Color.GREEN # Color(randf(), randf(), randf(), 1.0)
	new_cylinder_mesh.material = new_standard_material
	
	return new_node


func get_two_nearest_paths(current_position) -> Array:
	var distances_dict: Dictionary = {}
	for path: Path3D in vehicle_traffic_paths_array:
		var nearest_point_on_path: Vector3 = path.curve.get_closest_point(current_position)
		var distance_to_current_position: float = current_position.distance_squared_to(nearest_point_on_path)
		distances_dict[distance_to_current_position] = path
	var distances_array: Array = distances_dict.keys()
	distances_array.sort()
	return [distances_dict[distances_array[0]], distances_dict[distances_array[1]]]


func convert_navigation_path_points_to_pathchangers(navigation_path_array: Array) -> Array:
	var path_changers_array: Array = []
	for point: Vector3 in navigation_path_array:
		for path_changer: VehiclePathChanger in vehicle_path_changers_array:
			var distance_to_path_changer: float = point.distance_squared_to(path_changer.global_position)
			if distance_to_path_changer <= 1:
				path_changers_array.append(path_changer)
	return path_changers_array
	
