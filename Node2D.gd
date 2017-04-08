extends Node2D

const SIZE_MAP = Vector2(7, 6)
const TILE_SIZE = 64

onready var tmap = get_node('TileMap')
var points = Vector2Array()
var bonds = []
var start_pos
var end_pos
var as = AStar.new()

func _process(delta):
	if Input.is_action_just_pressed('LBM'):
		var coord = tmap.world_to_map(get_global_mouse_pos())
		if tmap.get_cell(coord.x, coord.y) == 0:
			start_pos = as.get_closest_point(Vector3(coord.x, coord.y, 0))
		update()
	if Input.is_action_just_pressed('RBM'):
		var coord = tmap.world_to_map(get_global_mouse_pos())
		if tmap.get_cell(coord.x, coord.y) == 0:
			end_pos = as.get_closest_point(Vector3(coord.x, coord.y, 0))
		update()
	#if start_pos != null and end_pos != null:
	#	print(start_pos, ' ', end_pos, ' ', as.get_id_path(start_pos, end_pos))
		
func get_centre(pos):
	return Vector2((pos.x * TILE_SIZE) + TILE_SIZE / 2, (pos.y * TILE_SIZE) + TILE_SIZE / 2)
	
func set_point(x, y):
	points.append(get_centre(Vector2(x,y)))

func set_bound(p1, p2):
	bonds.append( [get_centre(p1), get_centre(p2)])

func create_points(tilemap, tile = 0):

	var dirs = [ Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(1, -1), Vector2(0, -1), Vector2(-1,-1), Vector2(-1, 0) ]

	tilemap.set_z(-1)
	var i = 0
	for cx in range(SIZE_MAP.x):
		for cy in range(SIZE_MAP.y):
			if tilemap.get_cell(cx, cy) == tile:
				i += 1
				set_point(cx, cy)
				as.add_point(i, Vector3(cx, cy, 0))
	
	for cx in range(SIZE_MAP.x):
		for cy in range(SIZE_MAP.y):	
			if tilemap.get_cell(cx, cy) == tile:
				var t = Vector2(cx, cy)		
				for d in dirs:
					if not( (t + d).x in [SIZE_MAP.x, -1] or (t + d).y in [SIZE_MAP.y, -1] ):
						if tilemap.get_cell(cx + d.x, cy + d.y) == tile:
							as.connect_points(as.get_closest_point(Vector3(t.x, t.y, 0)), as.get_closest_point(Vector3(t.x + d.x, t.y + d.y,0)))
							set_bound(t, t + d)
						
	update()
	set_process(true)

func _ready():
	create_points(tmap)
	
func _draw():
	var i = 0
	for p in points:
		i += 1
		draw_circle(p, 9, Color(1, 1, 1))
	for t in bonds:
		draw_line(t[0], t[1], Color(1,1,1))
	if start_pos != null and end_pos != null:
		for j in as.get_id_path(start_pos, end_pos):
			draw_circle(get_centre(Vector2(as.get_point_pos(j).x, as.get_point_pos(j).y)), 6, Color(1, 0, 0))
	
