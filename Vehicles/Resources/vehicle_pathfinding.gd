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

# NEW
# NAVIGATION PATHS
## where vehicle travel
var vehicle_navigation_paths_array: Array

## a dictionary that holds the coordinates for every path's start and end as Vector3s
var navigation_paths_ends_dict: Dictionary

## a dictionary that holds all navigation paths connected to each navigation path
var connected_navigation_paths_dict: Dictionary
## a dictionary that holds all navigation paths connected to each navigation path and their closest distance to each other
var connected_navigation_paths_distances_dict: Dictionary

## how near a navigation path should be, to be considered as a viable connected path ->
## be careful that this number isn't too big as if it is, we can find bugs where 
## the vehicle doesn't know what path to pick next at junctions that are near each other
@export_range(0, 50, 5) var max_connected_navigation_path_distance: int = 25
## how near a navigation path's start and end should be, to be considered as a viable twin navigation path
@export_range(0, 20, 2)	var max_twin_distance: int = 15 # 10

## a dictionary that holds the nearest navigation path to half the navigation paths, for a-star path-finding
var twin_navigation_paths_dict: Dictionary
## a dictionary that holds the nearest navigation path to each navigation path
var full_twin_navigation_paths_dict: Dictionary

# TRANSITION PATHS
## where vehicle transition to the next path
var vehicle_transition_paths_array: Array
## a dictionary that holds the coordinates for every transition path's start and end as Vector3s
var transition_paths_ends_dict: Dictionary

## a dictionary that holds what paths and what transition paths go to what other paths 
var transition_paths_dict: Dictionary

## how near a transition path's start or end should be to a navigation path be considered connected to it
@export_range(0, 5) var max_transition_path_to_navigation_path_distance = 2


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


# NEW
func process_navigation_paths() -> void:
	# storing where paths start and end points are, as a dictionary
	for path: Path3D in vehicle_navigation_paths_array:
		var path_start_position: Vector3 = path.curve.get_point_position(0)
		var path_end_position: Vector3 = path.curve.get_point_position(path.curve.point_count - 1)
		navigation_paths_ends_dict[path] = {
			"start_pos": path_start_position, 
			"end_pos": path_end_position }
	
	# we go through all path extremities and check how close one path's end is to the start of another path
	for path: Path3D in navigation_paths_ends_dict:
		## an array that holds all connected paths to a particular path
		var nearest_paths_array: Array = []
		## a dictionary that holds all connected paths to a particular path and the closest distance to each
		var nearest_paths_dict: Dictionary = {}
		for other_path: Path3D in navigation_paths_ends_dict:
			if path != other_path:
				var curr_path_end_pos: Vector3 = navigation_paths_ends_dict[path].end_pos
				var other_path_start_pos: Vector3 = navigation_paths_ends_dict[other_path].start_pos
				var closest_distance_to_other_path_start: float = curr_path_end_pos.distance_squared_to(other_path_start_pos)
				if closest_distance_to_other_path_start <= pow(max_connected_navigation_path_distance, 2.0):
					nearest_paths_array.append(other_path)
					nearest_paths_dict[other_path] = closest_distance_to_other_path_start
					#print("%s - %s - %s" % [path.name, other_path.name, path_distance])
		connected_navigation_paths_dict[path] = nearest_paths_array
		connected_navigation_paths_distances_dict[path] = nearest_paths_dict
	
	print_debug("Connected Paths processed: %s - %s" % [connected_navigation_paths_dict.size(), connected_navigation_paths_distances_dict.size()])


## This function is to roughly find and store paths that go the exact opposite way from each other
func process_twin_navigation_paths() -> void:
	## an array to stop us from finding twins for already found paths
	var found_twin_navigation_paths_array: Array = []
	for path: Path3D in connected_navigation_paths_dict:
		var path_start_position: Vector3 = path.curve.get_point_position(0)
		var path_end_position: Vector3 = path.curve.get_point_position(path.curve.point_count-1)
		
		## a pre-calculated array of the other paths connected to this path
		var connected_navigation_paths_array: Array = connected_navigation_paths_dict[path]
		for connected_path: Path3D in connected_navigation_paths_array:
			var connected_path_start_position: Vector3 = connected_path.curve.get_point_position(0)
			var connected_path_end_position: Vector3 = connected_path.curve.get_point_position(connected_path.curve.point_count-1)
			
			var first_connected_path_distance: float = path_start_position.distance_squared_to(connected_path_end_position)
			var second_connected_path_distance: float = path_end_position.distance_squared_to(connected_path_start_position)
			
			# we measure if the start sand ends of each path come within a minimum distance and if 
			# so we can conclude these two paths are twins 
			if (first_connected_path_distance <= pow(max_twin_distance, 2)) and (second_connected_path_distance<= pow(max_twin_distance, 2)) and (path not in found_twin_navigation_paths_array):
				found_twin_navigation_paths_array.append(connected_path)
				twin_navigation_paths_dict[path] = connected_path
				
				## to make sure we can find all paths twins
				full_twin_navigation_paths_dict[path] = connected_path
				full_twin_navigation_paths_dict[connected_path] = path
				
	print_debug("Twin Paths processed: %s - %s" % [twin_navigation_paths_dict.size(), full_twin_navigation_paths_dict.size()])


func process_transition_paths() -> void:
	# storing where paths start and end points are, as a dictionary
	for trans_path: Path3D in vehicle_transition_paths_array:
		var path_start_position: Vector3 = trans_path.curve.get_point_position(0)
		var path_end_position: Vector3 = trans_path.curve.get_point_position(trans_path.curve.point_count - 1)
		transition_paths_ends_dict[trans_path] = {
			"start_pos": path_start_position, 
			"end_pos": path_end_position }
			
	for path: Path3D in connected_navigation_paths_dict.keys():
		var path_end_pos: Vector3 = navigation_paths_ends_dict[path].end_pos
		
		## a dictionary that holds what transition path each connected navigation path connects to
		var connected_path_transition_path_dict: Dictionary = {}
		for connected_path: Path3D in connected_navigation_paths_dict[path]:
			var connected_path_start_pos: Vector3 = navigation_paths_ends_dict[connected_path].start_pos
			
			# we scan through all transition paths and compare the distances between them and the 
			# start and end of connected navigation paths
			for trans_path: Path3D in transition_paths_ends_dict.keys():
				var trans_path_start_pos: Vector3 = transition_paths_ends_dict[trans_path].start_pos
				var trans_path_end_pos: Vector3 = transition_paths_ends_dict[trans_path].end_pos
				
				var path_end_to_trans_path_start_distance: float = path_end_pos.distance_squared_to(trans_path_start_pos)
				var trans_path_end_to_connected_path_start_distance: float = connected_path_start_pos.distance_squared_to(trans_path_end_pos)
				if (path_end_to_trans_path_start_distance <= pow(max_transition_path_to_navigation_path_distance, 2)) and (trans_path_end_to_connected_path_start_distance <= pow(max_transition_path_to_navigation_path_distance, 2)):
					connected_path_transition_path_dict[connected_path] = trans_path
					
		transition_paths_dict[path] = connected_path_transition_path_dict
		
	print_debug("Transition paths dict size: %s - %s" % [transition_paths_dict.size(), transition_paths_dict.keys().size()])


func a_star_process() -> void:
	## a dictionary that stores the starts and ends of navigation paths' ids for 
	# connecting later by a-star
	var a_star_path_extreme_points_dict: Dictionary
	# we need to keep track of path starts and end points ids in order to later 
	# query them to connect them easily
	
	## for a start or end point in a path which is connected with other paths, we 
	# don't want to create extra point ids for a-star so we can store them here instead
	#var connected_paths_id_dict: Dictionary = {}
	# we go through all the twin paths and link each point on the path
	for path: Path3D in twin_navigation_paths_dict.keys():
		# a dictionary to store the ids for the path's ends
		var path_start_and_end_dict: Dictionary = {}
		
		var path_points_pos_array: Array = []
		for idx: int in path.curve.point_count:
			var path_point_pos: Vector3 = path.curve.get_point_position(idx)
			path_points_pos_array.append(path_point_pos)
			
		## getting the start and end of each path's position quickly
		var path_start_point: Vector3 = path_points_pos_array[0]
		var path_end_point: Vector3 = path_points_pos_array[path_points_pos_array.size()-1]
		
		var next_start_available_point: int = a_star.get_available_point_id()
		a_star.add_point(next_start_available_point, path_start_point)
		
		var next_end_available_point: int = a_star.get_available_point_id()
		a_star.add_point(next_end_available_point, path_end_point)
		
		path_points_pos_array.erase(path_end_point)
		path_points_pos_array.erase(path_start_point)
		
		# where the path has more than two points we find a way to connect the points in order
		if path_points_pos_array.is_empty():
			# this means that we are only working with two path points
			if not a_star.are_points_connected(next_start_available_point, next_end_available_point):
				a_star.connect_points(next_start_available_point, next_end_available_point)
				#a_star.set_point_weight_scale(next_start_available_point, 2)
				#a_star.set_point_weight_scale(next_end_available_point, 2)
				
				## Debug Ting
				#if debug_on:
					#spawn_csg_debug_path([path_start_point, path_end_point])
		else:
			# this means that we are working with more than two path points
			#var debug_csg_path_array: Array = []
			
			## an array to store point ids temporarily, for paths with more than two points, for a-star connection
			var points_ids_array: Array = []
			for arr_idx: int in path_points_pos_array.size():
				var next_available_point_id: int = a_star.get_available_point_id()
				var current_pos: Vector3 = path_points_pos_array[arr_idx]
				a_star.add_point(next_available_point_id, current_pos)
				points_ids_array.append(next_available_point_id)
				
				## Debug Ting
				#if debug_on:
					#debug_csg_path_array.append(current_pos)
				
			# we place the start and end point ids at the correct position on the points_id_array
			points_ids_array.push_front(next_start_available_point)
			points_ids_array.push_back(next_end_available_point)
			
			## Debug Ting
			#if debug_on:
				#debug_csg_path_array.push_back(path_end_point)
				#debug_csg_path_array.push_front(path_start_point)
			
			# now we connect point ids in order
			for point_idx: int in (points_ids_array.size()-1):
				var curr_point_id: int = points_ids_array[point_idx]
				var next_point_id: int = points_ids_array[point_idx + 1]
				if not a_star.are_points_connected(curr_point_id, next_point_id):
					a_star.connect_points(curr_point_id, next_point_id)
					
					## Debug Ting
					#if debug_on:
						#spawn_csg_debug_path(debug_csg_path_array)
					
		path_start_and_end_dict["start"] = 	{"pos":path_start_point, 	"point_id":next_start_available_point}
		path_start_and_end_dict["end"] = 	{"pos":path_end_point,		"point_id":next_end_available_point}
		
		a_star_path_extreme_points_dict[path] = path_start_and_end_dict
		
	for path: Path3D in a_star_path_extreme_points_dict:
		var path_end_pos: Vector3 = a_star_path_extreme_points_dict[path].end.pos
		var path_start_pos: Vector3 = a_star_path_extreme_points_dict[path].start.pos
		
		var path_end_point_id: int = a_star_path_extreme_points_dict[path].end.point_id
		var path_start_point_id: int = a_star_path_extreme_points_dict[path].start.point_id
		for other_path: Path3D in a_star_path_extreme_points_dict:
			if path != other_path:
				var other_path_start_pos: Vector3 = a_star_path_extreme_points_dict[other_path].start.pos
				var other_path_end_pos: Vector3 = a_star_path_extreme_points_dict[other_path].end.pos
				
				# path end and other path start
				var distance_between_path_end_and_other_path_start: float = path_end_pos.distance_squared_to(other_path_start_pos)
				if (distance_between_path_end_and_other_path_start < pow(max_connected_navigation_path_distance, 2)):
					var other_path_start_point_id: int = a_star_path_extreme_points_dict[other_path].start.point_id
					#print("Path: %s - Other Path: %s - Point ID: %s -Other Path Point ID: %s" % [path.name, other_path.name, path_end_point_id, other_path_start_point_id])
					if not a_star.are_points_connected(path_end_point_id, other_path_start_point_id):
						a_star.connect_points(path_end_point_id, other_path_start_point_id)
						##print("%s and %s connected!" % [path.name, connected_path.name])
						
						## Debug ting!
						#if debug_on:
							#spawn_csg_debug_path([path_end_pos, other_path_start_pos], Color.BLACK) # Color(randf(),randf(),randf())) # Color.BLACK)
				
				# path end and other path end
				var distance_between_path_end_and_other_path_end: float = path_end_pos.distance_squared_to(other_path_end_pos)
				if (distance_between_path_end_and_other_path_end < pow(max_connected_navigation_path_distance, 2)):
					var other_path_end_point_id: int = a_star_path_extreme_points_dict[other_path].end.point_id
					#print("Path: %s - Other Path: %s - Point ID: %s -Other Path Point ID: %s" % [path.name, other_path.name, path_end_point_id, other_path_end_point_id])
					if not a_star.are_points_connected(path_end_point_id, other_path_end_point_id):
						a_star.connect_points(path_end_point_id, other_path_end_point_id)
						##print("%s and %s connected!" % [path.name, connected_path.name])
						
						## Debug ting!
						#if debug_on:
							#spawn_csg_debug_path([path_end_pos, other_path_end_pos], Color.BLACK) # Color(randf(),randf(),randf())) # Color.BLACK)
				
				# path start and other path end
				var distance_between_path_start_and_other_path_end: float = path_start_pos.distance_squared_to(other_path_end_pos)
				if (distance_between_path_start_and_other_path_end < pow(max_connected_navigation_path_distance, 2)):
					var other_path_end_point_id: int = a_star_path_extreme_points_dict[other_path].end.point_id
					#print("Path: %s - Other Path: %s - Point ID: %s -Other Path Point ID: %s" % [path.name, other_path.name, path_end_point_id, other_path_end_point_id])
					if not a_star.are_points_connected(path_start_point_id, other_path_end_point_id):
						a_star.connect_points(path_start_point_id, other_path_end_point_id)
						##print("%s and %s connected!" % [path.name, connected_path.name])
						
						## Debug ting!
						#if debug_on:
							#spawn_csg_debug_path([path_start_pos, other_path_end_pos], Color.BLACK) # Color(randf(),randf(),randf())) # Color.BLACK)
				
				# path start and other path start
				var distance_between_path_start_and_other_path_start: float = path_start_pos.distance_squared_to(other_path_start_pos)
				if (distance_between_path_start_and_other_path_start < pow(max_connected_navigation_path_distance, 2)):
					var other_path_start_point_id: int = a_star_path_extreme_points_dict[other_path].start.point_id
					#print("Path: %s - Other Path: %s - Point ID: %s -Other Path Point ID: %s" % [path.name, other_path.name, path_end_point_id, other_path_end_point_id])
					if not a_star.are_points_connected(path_start_point_id, other_path_start_point_id):
						a_star.connect_points(path_start_point_id, other_path_start_point_id)
						##print("%s and %s connected!" % [path.name, connected_path.name])
						
						## Debug ting!
						#if debug_on:
							#spawn_csg_debug_path([path_start_pos, other_path_start_pos], Color.BLACK) # Color(randf(),randf(),randf())) # Color.BLACK)
	
	print_debug("AStar connection completed!")
