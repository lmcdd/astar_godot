extends Node2D

onready var _tilemap: TileMap = $map
# Tiles in TileSet
enum tileID {GRASS, STONE, TREE, WATHER}

# Cached in _ready()
var _size_map : Vector2
var _tile_size: Vector2


### AStar variables ###
var points = PoolVector2Array()
var bonds = []
var start_pos: int = -1
var end_pos: int = -1
var astar = AStar2D.new()

var point_start: Vector2
var point_end: Vector2

export(bool) var _draw_debug_enabled = true
export(bool) var _draw_points_enabled = true
export(bool) var _draw_path_points_enabled = true
export(bool) var _draw_bonds_enabled = true
export(bool) var _draw_path_enabled = true
export(bool) var _draw_non_astar_path_enabled = true


# directions for the search of adjacent points
const dirs: Array = [
		# For without offset
		[	Vector2(-1, 1),	Vector2(0, 1),	Vector2(1, 1),
			Vector2(-1, 0),					Vector2(1, 0),
			Vector2(-1,-1),	Vector2(0, -1),	Vector2(1, -1)
		],
		
		# For Y offset
		# For X % 2 == 0
		[					Vector2(0, 1),
			Vector2(-1, 0),					Vector2(1, 0),
			Vector2(-1,-1),	Vector2(0, -1),	Vector2(1, -1)
		],
		# For X % 2 == 1
		[	Vector2(-1, 1),	Vector2(0, 1),	Vector2(1, 1),
			Vector2(-1, 0),					Vector2(1, 0),
							Vector2(0, -1),
		],
		# For X offset
		# For Y % 2 == 0	
		[	Vector2(-1, 1),	Vector2(0, 1),
			Vector2(-1, 0),					Vector2(1, 0),
			Vector2(-1,-1),	Vector2(0, -1),
		],
		# For Y % 2 == 1
		[					Vector2(0, 1),	Vector2(1, 1),
			Vector2(-1, 0),					Vector2(1, 0),
							Vector2(0, -1),	Vector2(1, -1)
		],
		
	]


func _process(_delta: float) -> void:
	# Start position
	if Input.is_action_just_pressed('LBM'):
		var coord = _tilemap.world_to_map(get_global_mouse_position())
		point_start = get_centre(coord)
		start_pos = astar.get_closest_point(get_centre(coord))
		update()
	# End position
	elif Input.is_action_pressed('LBM'):
		var coord = _tilemap.world_to_map(get_global_mouse_position())
		point_end = get_centre(coord)
		end_pos = astar.get_closest_point(get_centre(coord))
		update()


# To obtain the center of the tile		
func get_centre(pos) -> Vector2:
	return Vector2(_tilemap.map_to_world(pos) + _tile_size/2)


# Adding points to draw in the _draw()
func _set_point(id, pos) -> void:
	var centre_pos = get_centre(pos)
	points.append(centre_pos)
	astar.add_point(id, centre_pos)


# Adding bonds to draw in the _draw()
func _set_bound(p1, p2) -> void:
	bonds.append([get_centre(p1), get_centre(p2)])


# Create point
func _create_points(tilemap, tile = tileID.GRASS) -> void:
	# Additing points in AStar clastars
	var id = 0
	for cell_x in range(_size_map.x):
		for cell_y in range(_size_map.y):
			var cell = Vector2(cell_x, cell_y)
			if tilemap.get_cellv(cell) == tile:
				id += 1
				_set_point(id, cell)
	
	# Additing bonds in AStar clastars
	for cell_x in _size_map.x:
		# The choice of directions
		var current_dirs
		if _tilemap.cell_half_offset == _tilemap.HALF_OFFSET_Y:
			if cell_x%2 == 0:
				current_dirs = dirs[1]
			elif cell_x%2 == 1:
				current_dirs = dirs[2]
		else:
			current_dirs = dirs[0]

		for cell_y in _size_map.y:
			# The choice of directions
			if _tilemap.cell_half_offset == _tilemap.HALF_OFFSET_X:
				if cell_y%2 == 0:
					current_dirs = dirs[3]
				elif cell_y%2 == 1:
					current_dirs = dirs[4]
			else:
				current_dirs = dirs[0]
			
			var tile_pos = Vector2(cell_x, cell_y)
			if tilemap.get_cellv(tile_pos) == tile:
				# The sorting out of directions
				for dir in current_dirs:
					var tile_with_dir = tile_pos + dir
					# Check out negative limits
					if not( tile_with_dir.x in [_size_map.x, -1] or tile_with_dir.y in [_size_map.y, -1] ):
						if tilemap.get_cellv(tile_with_dir) == tile:
							# Connecting the points
							astar.connect_points(
								astar.get_closest_point(get_centre(tile_pos)), 
								astar.get_closest_point(get_centre(tile_with_dir))
							)
							# Additing bonds in array for _draw()
							_set_bound(tile_pos, tile_with_dir)
	update()


func _ready() -> void:
	_tile_size = _tilemap.cell_size
	_size_map = _tilemap.get_used_rect().size
	
	_create_points(_tilemap)


func _draw() -> void:
	if OS.is_debug_build() and _draw_debug_enabled:
		_draw_bonds()
		_draw_points()
		_draw_path()


func _draw_bonds() -> void:
	if _draw_bonds_enabled:
		for bond in bonds:
			draw_line(bond[0], bond[1], Color(1, 1, 1, 0.25), 2)


func _draw_points() -> void:
	if _draw_points_enabled:
		for point in points:
			draw_circle(point, 8, Color(1, 1, 0.5))


func _draw_path() -> void:
	if _draw_path_enabled:
		if start_pos != -1 and end_pos != -1:
			var path_points = astar.get_id_path(start_pos, end_pos)
			
			_draw_non_astar_path(path_points)
			_draw_path_bonds(path_points)
			_draw_path_points(path_points)


func _draw_non_astar_path(path_points: PoolIntArray) -> void:
	if _draw_non_astar_path_enabled:
		var astar_start: Vector2 = astar.get_point_position(path_points[0])
		var astar_end: Vector2 = astar.get_point_position(path_points[path_points.size() - 1])
		
		if (astar_start != point_start):
			draw_line(point_start, astar_start, Color.greenyellow)
		if (astar_end != point_end):
			draw_line(point_end, astar_end, Color.orange)


func _draw_path_bonds(path_points: PoolIntArray) -> void:
	var lastart_pos = null
	for point in path_points:
		var point_pos = astar.get_point_position(point)
		if lastart_pos != null:
			draw_line(lastart_pos, Vector2(point_pos.x, point_pos.y), Color(1, 1, 1, 0.25), 3, true)
			draw_line(lastart_pos, Vector2(point_pos.x, point_pos.y), Color(0.2, 0.6, 1, 1), 1.5)
		lastart_pos = Vector2(point_pos.x, point_pos.y)


func _draw_path_points(path_points: PoolIntArray) -> void:
	if _draw_path_points_enabled:
		for point in path_points:
			var point_pos = astar.get_point_position(point)
			draw_circle(Vector2(point_pos.x, point_pos.y), 7, Color(1, 1, 1, 0.25))
			draw_circle(Vector2(point_pos.x, point_pos.y), 6, Color.blue)
		
		# Draw start/end points
		draw_circle(point_start, 8, Color(1, 1, 1, 0.25))
		draw_circle(point_start, 7, Color.green)
		
		draw_circle(point_end, 8, Color(1, 1, 1, 0.25))
		draw_circle(point_end, 7, Color.red)
