extends Node2D

var SIZE_MAP : Vector2	# Generate
var TILE_SIZE: Vector2	# in _ready()

### AStar variables ###
var points = PoolVector2Array()
var bonds = []
var start_pos: int = -1
var end_pos: int = -1
var astar = AStar2D.new()

var point_start: Vector2
var point_end: Vector2

# directions for the search of adjacent points
var dirs: Array = [	
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
# Get TileMap
onready var tmap: TileMap = $'map'
# Tiles in TileSet
enum tileID {GRASS, STONE, TREE, WATHER}


func _process(delta):
	# Start position
	if Input.is_action_just_pressed('LBM'):
		var coord = tmap.world_to_map(get_global_mouse_position())	# Mouse pos in tile map
		point_start = get_centre(coord)
		start_pos = astar.get_closest_point(get_centre(coord))
		update()
	# End position
	if Input.is_action_just_pressed('RBM'):
		var coord = tmap.world_to_map(get_global_mouse_position())
		point_end = get_centre(coord)
		end_pos = astar.get_closest_point(get_centre(coord))
		update()


# To obtain the center of the tile		
func get_centre(pos) -> Vector2:
	return Vector2(tmap.map_to_world(pos) + TILE_SIZE/2)


# Adding points to draw in the _draw()
func set_point(x, y) -> void:
	points.append(get_centre(Vector2(x,y)))


# Adding bonds to draw in the _draw()
func set_bound(p1, p2) -> void:
	bonds.append( [get_centre(p1), get_centre(p2)])


# Create point
func create_points(tilemap, tile = tileID.GRASS) -> void:
	
	# Additing points in AStar clastars
	var id = 0
	for cx in range(SIZE_MAP.x):
		for cy in range(SIZE_MAP.y):
			if tilemap.get_cell(cx, cy) == tile:
				id += 1
				set_point(cx, cy)
				var m2w = get_centre(Vector2(cx, cy))	# To obtain the center of the tile	
				astar.add_point(id, m2w)	# Additing point without Z coord
	
	# Additing bonds in AStar clastars
	for cx in range(SIZE_MAP.x):
		# The choice of directions
		var ddirs
		if tmap.cell_half_offset == tmap.HALF_OFFSET_Y:
			if cx%2 == 0:
				ddirs = dirs[1]
			elif cx%2 == 1:
				ddirs = dirs[2]
		else:
			ddirs = dirs[0]

		for cy in range(SIZE_MAP.y):
			# The choice of directions
			if tmap.cell_half_offset == tmap.HALF_OFFSET_X:
				if cy%2 == 0:
					ddirs = dirs[3]
				elif cy%2 == 1:
					ddirs = dirs[4]
			else:
				ddirs = dirs[0]

			if tilemap.get_cell(cx, cy) == tile:
				var t = Vector2(cx, cy)		# Tile position to Vector2
				for d in ddirs:				# The sorting out of directions
					var td = t + d 			# Tile position + direction
					# Check out negative limits
					if not( td.x in [SIZE_MAP.x, -1] or td.y in [SIZE_MAP.y, -1] ):
						if tilemap.get_cell(td.x, td.y) == tile:
							# To obtain the center of the tile	 
							var tc = get_centre(t)
							var tdc = get_centre(td)
							# Connecting the points
							astar.connect_points(astar.get_closest_point(tc), astar.get_closest_point(tdc))
							# Additing bounds in array for _draw()
							set_bound(t, td)				
	update()


func _ready() -> void:
	# Constants
	TILE_SIZE = tmap.cell_size
	SIZE_MAP = tmap.get_used_rect().size
	
	create_points(tmap)


func _draw() -> void:
	# Draw bonds
	for t in bonds:
		draw_line(t[0], t[1], Color(1, 1, 1, 0.25), 3)
	# Draw points
	for p in points:
		draw_circle(p, 8, Color(1, 1, 0.5))
	
	# If there are start and end points
	if start_pos != -1 and end_pos != -1:
		var points = astar.get_id_path(start_pos, end_pos)
		
		# Draw non-AStar path
		var astar_start: Vector2 = astar.get_point_position(points[0])
		var astar_end: Vector2 = astar.get_point_position(points[points.size() - 1])
		
		if (astar_start != point_start):
			draw_line(point_start, astar_start, Color.greenyellow)
		if (astar_end != point_end):
			draw_line(point_end, astar_end, Color.orange)
		
		# Drawing path bonds
		var lastart_pos = null
		for p in points:
			var point_pos = astar.get_point_position(p)
			if lastart_pos != null:
				draw_line(lastart_pos, Vector2(point_pos.x, point_pos.y), Color.white, 3, true)
				draw_line(lastart_pos, Vector2(point_pos.x, point_pos.y), Color(0.2, 0.6, 1, 1), 1.5)
			lastart_pos = Vector2(point_pos.x, point_pos.y)
		# Drawing path points
		for p in points:
			var point_pos = astar.get_point_position(p)
			draw_circle(Vector2(point_pos.x, point_pos.y), 6, Color.blue)
	
	# Draw start/end points
	if (start_pos != -1):
		draw_circle(point_start, 8, Color.black)
		draw_circle(point_start, 7, Color.green)
	
	if (end_pos != -1):
		draw_circle(point_end, 8, Color.black)
		draw_circle(point_end, 7, Color.red)
