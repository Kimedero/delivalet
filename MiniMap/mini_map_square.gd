extends Control
class_name MiniMap

var MiniMapStats = preload("res://Minimap/Resources/mini_map_stats.tres")

@onready var frame_nine_patch_rect: NinePatchRect = $FrameNinePatchRect
@onready var grid_margin_container: MarginContainer = $GridMarginContainer
@onready var grid_texture: TextureRect = $GridMarginContainer/GridTexture
@onready var grid: TextureRect = $GridMarginContainer/Grid

@onready var player_marker_sprite: Sprite2D = $GridMarginContainer/GridTexture/PlayerMarkerSprite
@onready var teammate_marker_sprite: Sprite2D = $GridMarginContainer/GridTexture/TeammateMarkerSprite
@onready var opponent_marker_sprite: Sprite2D = $GridMarginContainer/GridTexture/OpponentMarkerSprite
@onready var pickup_marker_sprite: Sprite2D = $GridMarginContainer/GridTexture/PickupMarkerSprite
@onready var player_path_line: Line2D = $GridMarginContainer/GridTexture/PlayerPathLine

@export var minimap_size: float = 160
@onready var map_size := Vector2.ONE * minimap_size
var map_margin: float = 20
var ninepatch_margin: float = 32 # 64
var grid_container_margin: float = 10 # 15

@onready var icons_dict: Dictionary = {
	"player": player_marker_sprite, 
	"teammate": teammate_marker_sprite, 
	"opponent": opponent_marker_sprite, 
	"pickup": pickup_marker_sprite, 
	}

@export var player: Vehicle

@export var map_zoom: float = 0.4: set = set_map_zoom
var grid_scale: Vector2

var markers_dict: Dictionary
var marker_count: int

func _ready():
	gui_input.connect(_on_MiniMap_gui_input)
	
	MiniMapStats.add_minimap_object.connect(add_minimap_object)
	MiniMapStats.remove_minimap_object.connect(remove_minimap_object)
	
	initialise_elements()
	
	grid_scale = grid_texture.size / (get_viewport_rect().size * map_zoom)
	print("grid_scale: ", grid_scale)
	
	await get_tree().process_frame
	#var minimap_objects = MiniMapStats.minimap_objects
	#print("Minimap objects: %s" % [minimap_objects])
	for object in MiniMapStats.minimap_objects:
		add_minimap_object(object)
	


func _process(_delta):
	if not player:
		return
	
	player_marker_sprite.rotation = -player.rotation.y + PI
	
	for marker in markers_dict:
		var marker_pos: Vector2 = (vec3_to_vec2(marker.global_position) - \
		vec3_to_vec2(player.global_position)) * grid_scale + grid_texture.size * 0.5
		if grid_texture.get_rect().has_point(marker_pos + grid_texture.position):
			markers_dict[marker].scale = Vector2.ONE
		else:
			markers_dict[marker].scale = Vector2.ONE * 0.5
		marker_pos.x = clamp(marker_pos.x, 0, grid_texture.size.x)
		marker_pos.y = clamp(marker_pos.y, 0, grid_texture.size.y)
		markers_dict[marker].position = marker_pos
		
	player_path_line.clear_points()
	for path_point: Vector3 in player.target_path:
		var point_pos: Vector2 = (vec3_to_vec2(path_point) - vec3_to_vec2(player.global_position)) \
		* grid_scale + grid_texture.size * 0.5
		point_pos.x = clamp(point_pos.x, 0, grid_texture.size.x)
		point_pos.y = clamp(point_pos.y, 0, grid_texture.size.y)
		player_path_line.add_point(point_pos)
	
	grid_texture.pivot_offset = grid_texture.size * 0.5
	grid_texture.rotation_degrees = -player_marker_sprite.rotation_degrees


func initialise_elements():
	#custom_minimum_size = Vector2.ONE * minimap_size # (minimap_size + (grid_container_margin * 2))
	##size = Vector2.ONE * (minimap_size + (grid_container_margin * 2))
	#print("Size: %s" % [size])
	
	player_marker_sprite.position = grid_texture.size * 0.5
	#print("Pos: ", player_marker_sprite.position)
	
	# Minimap Margin Container
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	
	frame_nine_patch_rect.size = map_size
	
	grid_margin_container.set_deferred("size", map_size)
	
	# Grid Margin Container	
	grid_margin_container.set("theme_override_constants/margin_right", grid_container_margin)
	grid_margin_container.set("theme_override_constants/margin_top", grid_container_margin)
	grid_margin_container.set("theme_override_constants/margin_left", grid_container_margin)
	grid_margin_container.set("theme_override_constants/margin_bottom", grid_container_margin)
	
	# Grid
#	grid_texture.stretch_mode = TextureRect.STRETCH_TILE
#	grid_texture.rect_size = map_size - ((Vector2.ONE * grid_container_margin * 2) + (Vector2.ONE * map_margin * 2))
	
	player_marker_sprite.position = grid_texture.size * 0.5


func add_minimap_object(m_obj: Node3D):
	var new_marker: Sprite2D = icons_dict[m_obj.minimap_icon].duplicate()
	new_marker.name = "Marker_%s" % [marker_count]
	marker_count += 1
	new_marker.show()
	markers_dict[m_obj] = new_marker
	grid_texture.add_child(new_marker)


func remove_minimap_object(m_obj: Node3D):
	if markers_dict.has(m_obj):
		grid_texture.remove_child(markers_dict[m_obj])
		markers_dict.erase(m_obj)
	else:
		print("%s not found!" % [m_obj.name])


func _on_MiniMap_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			map_zoom -= 0.1
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			map_zoom += 0.1
		print("map zoom: %s" % [map_zoom])


func set_map_zoom(value):
	map_zoom = clamp(value, 0.2, 1)
	grid_scale = grid_texture.size / (get_viewport_rect().size * map_zoom)
	print("Map zoom: %s" % [map_zoom])


func vec3_to_vec2(vec3: Vector3) -> Vector2:
	return Vector2(vec3.x, vec3.z)
