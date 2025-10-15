@tool
extends Node3D

@onready var road_grid_map: GridMap = $RoadGridMap

# ROAD SEGMENTS
const CROSS = preload("res://Map/Roads/RoadSegments/cross.tscn")
const L = preload("res://Map/Roads/RoadSegments/l.tscn")
const L_WIDE = preload("res://Map/Roads/RoadSegments/l_wide.tscn")
const L_WIDE_2 = preload("res://Map/Roads/RoadSegments/l_wide_2.tscn")
const PAVEMENT = preload("res://Map/Roads/RoadSegments/pavement.tscn")
const PAVEMENT_1 = preload("res://Map/Roads/RoadSegments/pavement_1.tscn")
const PAVEMENT_2 = preload("res://Map/Roads/RoadSegments/pavement_2.tscn")
const ROAD_PLAIN = preload("res://Map/Roads/RoadSegments/road_plain.tscn")
const T = preload("res://Map/Roads/RoadSegments/t.tscn")
const THROUGH = preload("res://Map/Roads/RoadSegments/through.tscn")
const THROUGH_WIDE = preload("res://Map/Roads/RoadSegments/through_wide.tscn")
const T_WIDE = preload("res://Map/Roads/RoadSegments/t_wide.tscn")
const T_WIDE_2 = preload("res://Map/Roads/RoadSegments/t_wide_2.tscn")
const T_WIDE_3 = preload("res://Map/Roads/RoadSegments/t_wide_3.tscn")
const T_WIDE_4 = preload("res://Map/Roads/RoadSegments/t_wide_4.tscn")

var ROAD_SEGEMENTS = { 
	"cross":CROSS,
	"l": L,
	"l_wide": L_WIDE,
	"l_wide2": L_WIDE_2,
	"pavement": PAVEMENT,
	"pavement1": PAVEMENT_1,
	"pavement2": PAVEMENT_2,
	"road_plain": ROAD_PLAIN,
	"t": T,
	"t_wide": T_WIDE,
	"t_wide2": T_WIDE_2,
	"t_wide3": T_WIDE_3,
	"t_wide4": T_WIDE_4,
	"through": THROUGH,
	"through_wide": THROUGH_WIDE,
}

func _ready() -> void:
	#print(road_grid_map.get_used_cells().size())
	#print(road_grid_map.get_bake_mesh_instance(0))
	#print(road_grid_map.get_meshes())
	#var cnt: int
	#for pos in road_grid_map.get_used_cells():
		#cnt += 1
		#print("%s. POS: %s -> Item: %s" % [cnt, pos, road_grid_map.get_cell_item(pos)])
	
	var item_list := road_grid_map.mesh_library.get_item_list()
	#print("Item List: %s" % [item_list])
	
	for item in item_list:
		print("Item: %s -> Name: %s -> %s" % [item, road_grid_map.mesh_library.get_item_name(item), road_grid_map.get_used_cells_by_item(item)])
