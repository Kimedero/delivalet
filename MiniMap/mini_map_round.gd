extends MarginContainer
class_name Minimap

var MINI_MAP_STATS = preload("res://Minimap/Resources/mini_map_stats.tres")
var VEHICLE_DATA = preload("res://Vehicles/Resources/vehicle_data.tres")

@export var vehicle: Vehicle

@export var minimap_size: float = 160

@export var grid_margin: int = 10

@onready var grid_mask: TextureRect = $GridMask
@onready var grid_texture_rect: TextureRect = $GridMask/GridTextureRect

@onready var player_marker_sprite: Sprite2D = $GridMask/GridTextureRect/PlayerMarkerSprite
@onready var teammate_marker_sprite: Sprite2D = $GridMask/GridTextureRect/TeammateMarkerSprite
@onready var opponent_marker_sprite: Sprite2D = $GridMask/GridTextureRect/OpponentMarkerSprite
@onready var pickup_marker_sprite: Sprite2D = $GridMask/GridTextureRect/PickupMarkerSprite

@onready var line_mask: TextureRect = $LineMask
@onready var player_path_line: Line2D = $LineMask/PlayerPathLine

@onready var icons_dict: Dictionary = {
	"player": player_marker_sprite, 
	"teammate": teammate_marker_sprite, 
	"opponent": opponent_marker_sprite, 
	"pickup": pickup_marker_sprite, 
	}

var object_markers_dict: Dictionary
var marker_count: int

@export var map_zoom: float = 0.4: set = set_map_zoom
var grid_scale: Vector2
# how fast the minimap rotates along with the vehicle
@export var rotation_speed = 2.5

var road_lines_drawn: bool
# keeps track of which road lines are co-related to which paths on the map 
var path_to_road_lines_dict: Dictionary

func _ready() -> void:
	MINI_MAP_STATS.add_minimap_object.connect(add_minimap_object)
	MINI_MAP_STATS.remove_minimap_object.connect(remove_minimap_object)
	
	gui_input.connect(on_gui_input)
	
	initialise_elements()
	
	grid_scale = grid_texture_rect.size / (get_viewport_rect().size * map_zoom)
	
	for object in MINI_MAP_STATS.minimap_objects:
		add_minimap_object(object)


func _process(delta: float) -> void:
	if not vehicle:
		return
	
	if not road_lines_drawn:
		draw_road_lines()
		road_lines_drawn = true
	
	#player_marker_sprite.rotation = -vehicle.rotation.y + PI
	player_marker_sprite.rotation = lerp_angle(player_marker_sprite.rotation, -vehicle.rotation.y + PI, rotation_speed * delta)
	
	# grid mask rotation
	grid_mask.pivot_offset = grid_mask.size * 0.5
	grid_mask.rotation_degrees = -player_marker_sprite.rotation_degrees
	
	# line mask rotation
	line_mask.pivot_offset = line_mask.size * 0.5
	line_mask.rotation_degrees = -player_marker_sprite.rotation_degrees
	
	## target line
	#player_path_line.clear_points()
	#for path_point: Vector3 in vehicle.target_path:
		#var point_pos: Vector2 = (vec3_to_vec2(path_point) - vec3_to_vec2(vehicle.global_transform.origin)) \
		#* grid_scale + grid_texture_rect.size * 0.5
		#point_pos.x = clamp(point_pos.x, 0, grid_texture_rect.size.x)
		#point_pos.y = clamp(point_pos.y, 0, grid_texture_rect.size.y)
		#player_path_line.add_point(point_pos)
	
	# marker placement
	var grid_mid_point: Vector2 = player_marker_sprite.position
	var grid_radius: float = minimap_size * 0.5
	for object: Node3D in object_markers_dict:
		var marker_pos: Vector2 = (vec3_to_vec2(object.global_position) - \
		vec3_to_vec2(vehicle.global_position)) * grid_scale + grid_texture_rect.size * 0.5
		
		# we determine the middle point of the grid and anything a bigger distance 
		# from the radius is put at the radius and shrunk/smallisized
		if marker_pos.distance_squared_to(grid_mid_point) < pow(grid_radius, 2):
			object_markers_dict[object].scale = Vector2.ONE
			object_markers_dict[object].self_modulate.a = 1.0
		else:
			object_markers_dict[object].scale = Vector2.ONE * 0.5
			object_markers_dict[object].self_modulate.a = 0.64 # 0.25
			
			var angle: float = player_marker_sprite.position.angle_to_point(marker_pos)
			var point_on_circle: Vector2 = player_marker_sprite.position + Vector2(grid_radius * cos(angle), grid_radius * sin(angle))
			marker_pos = point_on_circle
		object_markers_dict[object].position = marker_pos
		
		# for a square grid
		#if grid_texture_rect.get_rect().has_point(marker_pos + grid_texture_rect.position):
			#markers_dict[marker].scale = Vector2.ONE
		#else:
			#markers_dict[marker].scale = Vector2.ONE * 0.5
		#marker_pos.x = clamp(marker_pos.x, 0, grid_texture_rect.size.x)
		#marker_pos.y = clamp(marker_pos.y, 0, grid_texture_rect.size.y)
		
	update_road_lines()


func initialise_elements():
	# Main Control
	#set_deferred("layout_mode", 1)
	set_deferred("anchors_preset", Control.PRESET_BOTTOM_LEFT)
	
	custom_minimum_size = Vector2.ONE * (minimap_size + grid_margin * 2) 
	#size = Vector2.ONE * (minimap_size + grid_margin * 2)
	set_deferred("size", Vector2.ONE * (minimap_size + grid_margin * 2)) 
	
	# Grid Margin Container
	#grid_margin_container.set_deferred("layout_mode", 1)
	#grid_margin_container.set_deferred("anchors_preset", Control.PRESET_BOTTOM_LEFT)
	
	#grid_margin_container.custom_minimum_size = Vector2.ONE * (minimap_size + grid_margin * 2) 
	#grid_margin_container.size = Vector2.ONE * (minimap_size + grid_margin * 2)
	#grid_margin_container.set_deferred("size", Vector2.ONE * (minimap_size + grid_margin * 2)) 
	
	set("theme_override_constants/margin_left", grid_margin)
	set("theme_override_constants/margin_top", grid_margin)
	set("theme_override_constants/margin_right", grid_margin)
	set("theme_override_constants/margin_bottom", grid_margin)
	
	# Grid Texture
	grid_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grid_texture_rect.stretch_mode = TextureRect.STRETCH_TILE
	
	grid_texture_rect.custom_minimum_size = Vector2.ONE * minimap_size
	grid_texture_rect.size = Vector2.ONE * minimap_size
	
	# Sprites
	player_marker_sprite.position = Vector2.ONE * minimap_size * 0.5


func add_minimap_object(minimap_object: Node3D):
	#print("MOBJ: %s -> %s" % [minimap_object, vehicle])
	if minimap_object.minimap_icon and icons_dict[minimap_object.minimap_icon]: # and vehicle != minimap_object:
		var new_marker: Sprite2D = icons_dict[minimap_object.minimap_icon].duplicate()
		new_marker.name = "%s_marker_%s" % [minimap_object.name.to_lower(), marker_count]
		marker_count += 1
		new_marker.show()
		
		object_markers_dict[minimap_object] = new_marker
		grid_texture_rect.add_child(new_marker)
		new_marker.position = player_marker_sprite.position
		
		print("%s added!" % [minimap_object.name])


func remove_minimap_object(minimap_object: Node3D):
	if object_markers_dict.has(minimap_object):
		grid_texture_rect.remove_child(object_markers_dict[minimap_object])
		object_markers_dict.erase(minimap_object)
		
		print("%s removed!" % [minimap_object.name])


func on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			map_zoom -= 0.1
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			map_zoom += 0.1
		print("map zoom: %s" % [map_zoom])


func set_map_zoom(value: float):
	map_zoom = clamp(value, 0.2, 1.0)
	grid_scale = grid_texture_rect.size / (get_viewport_rect().size * map_zoom)
	print("Map zoom: %s" % [map_zoom])


func draw_road_lines():
	## this basically places lines on the minimap that co-relates to the 
	## vehicle paths on the map
	for path: Path3D in VEHICLE_DATA.vehicle_traffic_paths_array:
		var new_line := Line2D.new()
		new_line.width = 2
		new_line.default_color = Color("ff6a00")
		new_line.antialiased = true
		new_line.name = "%s_road_line" % [path.name]
		
		path_to_road_lines_dict[path] = new_line
		line_mask.add_child(new_line)


func update_road_lines():
	for path: Path3D in path_to_road_lines_dict.keys():
		var line: Line2D = path_to_road_lines_dict[path]
		line.clear_points()
		for point in path.curve.point_count:
			var path_point: Vector3 = path.curve.get_point_position(point)
			var point_pos: Vector2 = (vec3_to_vec2(path_point) - vec3_to_vec2(vehicle.global_transform.origin)) \
			* grid_scale + grid_texture_rect.size * 0.5
			point_pos.x = clamp(point_pos.x, 0, grid_texture_rect.size.x)
			point_pos.y = clamp(point_pos.y, 0, grid_texture_rect.size.y)
			line.add_point(point_pos)


func vec3_to_vec2(vec3: Vector3) -> Vector2:
	return Vector2(vec3.x, vec3.z)
