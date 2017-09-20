extends Node2D

const SIZE_MAP = Vector2(0,0)		# Generate
const TILE_SIZE = Vector2(0,0)		# in _ready()

### AStar variables ###
var points = PoolVector2Array()
var bonds = []
var start_pos
var end_pos
var as = AStar.new()

# directions for the search of adjacent points
var dirs = [	
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
onready var tmap = $'map'
# Tiles in TileSet
enum tileID {GRASS, STONE, TREE, WATHER}

func _process(delta):
	# Start position
	if Input.is_action_just_pressed('LBM'):
		var coord = tmap.world_to_map(get_global_mouse_position())	# Mouse pos in tile map
		var global_coord = get_centre(coord)						# Global mouse pos in tile map
		if tmap.get_cell(coord.x, coord.y) == tileID.GRASS:
			start_pos = as.get_closest_point(Vector3(global_coord.x, global_coord.y, 0))
		update()
	# End position
	if Input.is_action_just_pressed('RBM'):
		var coord = tmap.world_to_map(get_global_mouse_position())
		var global_coord = get_global_mouse_position()
		if tmap.get_cell(coord.x, coord.y) == tileID.GRASS:
			end_pos = as.get_closest_point(Vector3(global_coord.x, global_coord.y, 0))
		update()

# To obtain the center of the tile		
func get_centre(pos):
	return Vector2(tmap.map_to_world(pos) + TILE_SIZE/2)

# Adding points to draw in the _draw()
func set_point(x, y):
	points.append(get_centre(Vector2(x,y)))

# Adding bonds to draw in the _draw()
func set_bound(p1, p2):
	bonds.append( [get_centre(p1), get_centre(p2)])

# Create point
func create_points(tilemap, tile = tileID.GRASS):
	
	# Additing points in AStar class
	var i = 0	# ID
	for cx in range(SIZE_MAP.x):
		for cy in range(SIZE_MAP.y):
			if tilemap.get_cell(cx, cy) == tile:
				i += 1
				set_point(cx, cy)
				var m2w = get_centre(Vector2(cx, cy))	# To obtain the center of the tile	
				as.add_point(i, Vector3(m2w.x, m2w.y, 0))	# Additing point without Z coord
	
	# Additing bonds in AStar class
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
							as.connect_points(as.get_closest_point(Vector3(tc.x, tc.y, 0)), as.get_closest_point(Vector3(tdc.x, tdc.y, 0)))
							# Additing bounds in array for _draw()
							set_bound(t, td)				
	update()

func _ready():
	# Constants
	SIZE_MAP = tmap.world_to_map( tmap.get_item_rect().size)
	TILE_SIZE = tmap.cell_size

	create_points(tmap)
	
func _draw():
	# Draw bonds
	for t in bonds:
		draw_line(t[0], t[1], Color(1,1,1))
	# Draw points
	for p in points:
		draw_circle(p, 9, Color(1, 1, 0.5))

	# If there are start and end points
	if start_pos != null and end_pos != null:
		var last_pos = null
		# Drawing bonds the path
		for j in as.get_id_path(start_pos, end_pos):
			var point_pos = as.get_point_pos(j)
			if last_pos != null:
				draw_line(last_pos, Vector2(point_pos.x, point_pos.y), Color(1,1,1), 4, true)
				draw_line(last_pos, Vector2(point_pos.x, point_pos.y), Color(1,0,0), 2)
			last_pos = Vector2(point_pos.x, point_pos.y)
		# Drawing points the path
		for j in as.get_id_path(start_pos, end_pos):
			var point_pos = as.get_point_pos(j)
			draw_circle(Vector2(point_pos.x, point_pos.y), 6, Color(1, 0, 0))
			