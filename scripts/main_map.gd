extends Node2D

@onready var tile_map = $TileMap

func _ready() -> void:
	await get_tree().process_frame
	var camera = get_node_or_null("Skeleton/Camera2D")
	
	if camera and tile_map:
		var map_rect = tile_map.get_used_rect()
		var tile_size = tile_map.tile_set.tile_size
		
		camera.limit_left = map_rect.position.x * tile_size.x
		camera.limit_top = map_rect.position.y * tile_size.y
		camera.limit_right = map_rect.end.x * tile_size.x
		camera.limit_bottom = map_rect.end.y * tile_size.y
