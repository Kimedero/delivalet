extends MarginContainer

@onready var ninePatch = get_node("FrameNinePatch")
@onready var gridMargin = get_node("GridMargin")
var minimap_width = 240
var minimap_height = 160
var minimap_custom_margins = 5
var patch_margins_size = 64
var gridmargin_custom_margins = 15

#@export (NodePath) var player
@export var player: NodePath
var Player
@export var zoom = 0.55 # setget set_zoom # 1.5 1.25

@onready var grid = get_node("GridMargin/Grid")
@onready var iconz = get_node("GridMargin/iconz")
@onready var player_marker = get_node("GridMargin/iconz/PlayerMarker")
@onready var target_marker = get_node("GridMargin//iconz/TargetMarker")
@onready var checkpoint_marker = get_node("GridMargin/iconz/CheckpointMarker")
@onready var alert_marker = get_node("GridMargin//iconz/AlertMarker")
@onready var teammate_marker = get_node("GridMargin/iconz/TeammateMarker")
@onready var opponent_marker = get_node("GridMargin/iconz/OpponentMarker")
@onready var house_marker = get_node("GridMargin/iconz/HouseMarker")
@onready var fence_marker = get_node("GridMargin/iconz/FenceMarker")
@onready var outside_marker = get_node("GridMargin/iconz/OutsideMarker")
@onready var square_marker = get_node("GridMargin/iconz/SquareMarker")

@onready var icons = {
	"target": target_marker, 
	"alert": alert_marker, 
	"checkpoint": checkpoint_marker, 
	"teammate": teammate_marker, 
	"opponent": opponent_marker, 
	"house": house_marker, 
	"fence": fence_marker, 
	"outside": outside_marker, 
	"square": square_marker
	}
var grid_scale
var markers_dict: Dictionary = {}

@onready var pathwayLine = get_node("GridMargin/iconz/pathwayLine2D")

@onready var housesGridMap: GridMap = get_tree().get_nodes_in_group("houses")[0]
var houseGridScale: Vector3
var houses_array = []
var house_markers_dict = {}

@onready var fenceGridMap: GridMap = get_tree().get_nodes_in_group("fence")[0]
var fenceGridScale: Vector3
var fence_array = []
var fence_markers_dict = {}

@onready var outsideGridMap: GridMap = get_tree().get_nodes_in_group("outside")[0]
var outsideGridScale: Vector3
var outside_array = []
var outside_markers_dict = {}

var _frame_counter = 0
var FRAMES_BETWEEN_UPDATES = 2.5

#@onready var variousCombo = preload("res://Minimap/VariousCombo.tscn")

func _ready():
	set_up_elements()
	connect("gui_input", Callable(self, "_on_MiniMap_gui_input"))
	

	Player = get_node(player)
#	player_marker.position = grid.rect_size / 2
	grid_scale = grid.rect_size / (get_viewport_rect().size * zoom)
	
	var map_objects = get_tree().get_nodes_in_group("minimap_object")
	for item in map_objects:
		var new_marker
		if item.is_in_group("teammate"):
			new_marker = icons["teammate"].duplicate()
		else:
			new_marker = icons[item.minimap_icon].duplicate()
		iconz.add_child(new_marker)
		new_marker.show()
		markers_dict[item] = new_marker
	
	# this processes house icon positions according to the houseGridMap
	houses_array = housesGridMap.get_used_cells()
	houseGridScale = housesGridMap.cell_size
	for house in houses_array:
		var house_marker_icon = icons["house"].duplicate()
		iconz.add_child(house_marker_icon)
		house_marker_icon.show()
		house_markers_dict[house] = house_marker_icon
	
	fence_array = fenceGridMap.get_used_cells()
	fenceGridScale = fenceGridMap.cell_size
	for segment in fence_array:
		var fence_marker_icon = icons["fence"].duplicate()
		iconz.add_child(fence_marker_icon)
		fence_marker_icon.show()
		fence_markers_dict[segment] = fence_marker_icon
	
	outside_array = outsideGridMap.get_used_cells()
	outsideGridScale = outsideGridMap.cell_size
	for out in outside_array:
		var outside_marker_icon = icons["outside"].duplicate()
		iconz.add_child(outside_marker_icon)
		outside_marker_icon.show()
		outside_markers_dict[out] = outside_marker_icon
		#place_various_combo(out)
	
#	for stuff in Global.targetArray:
#		var new_marker = icons["alert"].duplicate()
#		grid.add_child(new_marker)
#		new_marker.show()
#		markers[stuff] = new_marker


func _process(delta):
#	if !player:
#		return
	player_marker.rotation = -Player.rotation.y  + PI
	
	if _frame_counter == 0:	
		pathwayLine.clear_points()
		
		for item in markers_dict:
	#		var obj_pos = (Vector2(item.global_translation.x, item.global_translation.z) - Vector2(Player.global_translation.x, Player.global_translation.z)) * grid_scale + grid.rect_size / 2
			var obj_pos = (Vector2(item.global_translation.x, item.global_translation.z) - Vector2(Player.global_translation.x, Player.global_translation.z)) * grid_scale + iconz.rect_size / 2
			if grid.get_rect().has_point(obj_pos + grid.rect_position):
				markers_dict[item].scale = Vector2.ONE
			else:
				markers_dict[item].scale = Vector2.ONE * 0.125
			obj_pos.x = clamp(obj_pos.x, 0, grid.rect_size.x)
			obj_pos.y = clamp(obj_pos.y, 0, grid.rect_size.y)

			markers_dict[item].position = obj_pos
		
		for point in Player.pickupArray:
			var point_pos = (Vector2(point.x, point.z) - Vector2(Player.global_translation.x, Player.global_translation.z)) * grid_scale + iconz.rect_size / 2
			point_pos.x = clamp(point_pos.x, 0, grid.rect_size.x)
			point_pos.y = clamp(point_pos.y, 0, grid.rect_size.y)
			pathwayLine.add_point(point_pos)
		
		for keja in house_markers_dict:
			var keja_pos = (Vector2(keja.x * houseGridScale.x, keja.z * houseGridScale.z) - Vector2(Player.global_translation.x, Player.global_translation.z)) * grid_scale + iconz.rect_size / 2
			if grid.get_rect().has_point(keja_pos + grid.rect_position):
				house_markers_dict[keja].scale = Vector2.ONE
			else:
				house_markers_dict[keja].scale = Vector2.ONE * 0.125
			keja_pos.x = clamp(keja_pos.x, 0, grid.rect_size.x)
			keja_pos.y = clamp(keja_pos.y, 0, grid.rect_size.y)
			house_markers_dict[keja].position = keja_pos
		
		for segment in fence_markers_dict:
			var fence_pos = (Vector2(segment.x * fenceGridScale.x, segment.z * fenceGridScale.z) - Vector2(Player.global_translation.x, Player.global_translation.z)) * grid_scale + iconz.rect_size / 2
			if grid.get_rect().has_point(fence_pos + grid.rect_position):
				fence_markers_dict[segment].scale = Vector2.ONE
			else:
				fence_markers_dict[segment].scale = Vector2.ONE * 0.125
			fence_pos.x = clamp(fence_pos.x, 0, grid.rect_size.x)
			fence_pos.y = clamp(fence_pos.y, 0, grid.rect_size.y)
			fence_markers_dict[segment].position = fence_pos
			
		for sector in outside_markers_dict:
			var sector_pos = (Vector2(sector.x * outsideGridScale.x, sector.z * outsideGridScale.z) - Vector2(Player.global_translation.x, Player.global_translation.z)) * grid_scale + iconz.rect_size / 2
			if grid.get_rect().has_point(sector_pos + grid.rect_position):
				outside_markers_dict[sector].scale = Vector2.ONE
			else:
				outside_markers_dict[sector].scale = Vector2.ONE * 0.125
			sector_pos.x = clamp(sector_pos.x, 0, grid.rect_size.x)
			sector_pos.y = clamp(sector_pos.y, 0, grid.rect_size.y)
			outside_markers_dict[sector].position = sector_pos
			
		# this part makes the map rotate so that player is always pointed up
		iconz.rect_pivot_offset = grid.rect_size / 2
		iconz.rect_rotation = -player_marker.rotation_degrees
	#	grid.rect_pivot_offset = grid.rect_size/2
	#	grid.rect_rotation = player_marker.rotation_degrees

	_frame_counter = wrapi(_frame_counter + 1, 0, FRAMES_BETWEEN_UPDATES)


func set_zoom(value):
	zoom = clamp(value, 0.5, 1.25)
	grid_scale = grid.rect_size / (get_viewport_rect().size * zoom)
	print(zoom)


func _on_MiniMap_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			self.zoom -= 0.1
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			self.zoom += 0.1


func set_up_elements():
	# this sets the minimap at the bottom left of the screen
	anchor_left = 0
	anchor_top = 1
	anchor_right = 0
	anchor_bottom = 1
	
#	margin_left = 0
#	margin_top = -minimap_height
#	margin_right = minimap_width
#	margin_bottom = 0

	set("theme_override_constants/margin_left", 0)
	set("theme_override_constants/margin_top", -minimap_height)
	set("theme_override_constants/margin_right", minimap_width)
	set("theme_override_constants/margin_bottom", 0)
	
	# sets the size of the minimap
	size = Vector2(minimap_width, minimap_height)
	
	# create automatic margins for the main container
	set("custom_constants/margin_right", minimap_custom_margins)
	set("custom_constants/margin_top", minimap_custom_margins)
	set("custom_constants/margin_left", minimap_custom_margins)
	set("custom_constants/margin_bottom", minimap_custom_margins)
	
	ninePatch.patch_margin_left= patch_margins_size
	ninePatch.patch_margin_top = patch_margins_size
	ninePatch.patch_margin_right = patch_margins_size
	ninePatch.patch_margin_bottom = patch_margins_size
	
#	ninePatch.margin_left = 0
#	ninePatch.margin_top = 0
#	ninePatch.margin_right = minimap_width
#	ninePatch.margin_bottom = minimap_height
	
	ninePatch.margin_left = 0
	ninePatch.margin_top = 0
	ninePatch.margin_right = minimap_width
	ninePatch.margin_bottom = minimap_height
	
	gridMargin.set("custom_constants/margin_right", gridmargin_custom_margins)
	gridMargin.set("custom_constants/margin_top", gridmargin_custom_margins)
	gridMargin.set("custom_constants/margin_left", gridmargin_custom_margins)
	gridMargin.set("custom_constants/margin_bottom", gridmargin_custom_margins)
	
	gridMargin.margin_left = 0
	gridMargin.margin_top = 0
	gridMargin.margin_right = minimap_width
	gridMargin.margin_bottom = minimap_height

	grid.margin_left = 0
	grid.margin_top = 0
	grid.margin_right = minimap_width
	grid.margin_bottom = minimap_height
	
	grid.rect_size = gridMargin.rect_size - (Vector2.ONE * gridmargin_custom_margins * 2)
	grid.rect_size = gridMargin.rect_size - (Vector2.ONE * gridmargin_custom_margins * 2)
	grid.stretch_mode = 2 # STRETCH_TILE
	
	player_marker.position = grid.rect_size / 2


#func place_various_combo(pos):
	#var vrsCombo = variousCombo.instance()
	#vrsCombo.global_translation = pos * outsideGridScale
	#vrsCombo.rotation_degrees.y = randi() % 360
	#get_tree().get_nodes_in_group("various")[0].add_child(vrsCombo)
