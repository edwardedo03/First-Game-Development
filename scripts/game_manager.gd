extends Node

var target_gate_destination: String = ""
var dead_enemies: Dictionary = {}

func transition_to_scene(target_path: String, gate_name: String, player_node: Node) -> void:
	target_gate_destination = gate_name
	
	player_node.get_parent().call_deferred("remove_child", player_node)
	
	get_tree().change_scene_to_file(target_path)
	
	await get_tree().process_frame
	var current_scene = get_tree().current_scene
	current_scene.add_child(player_node)
	
	var existing_player = current_scene.get_node_or_null("Skeleton")
	if existing_player and existing_player != player_node:
		existing_player.queue_free()
	
	if player_node and is_instance_valid(player_node):
		current_scene.add_child(player_node)
		
		var spawn_node = current_scene.get_node_or_null(target_gate_destination)
		if spawn_node:
			player_node.global_position = spawn_node.global_position
			
		var camera = player_node.get_node_or_null("Camera2D")
		var tile_map = current_scene.get_node_or_null("Object")
	
		if camera and tile_map:
			var map_rect = tile_map.get_used_rect()
			var tile_size = tile_map.tile_set.tile_size
			
			camera.limit_left = map_rect.position.x * tile_size.x
			camera.limit_top = map_rect.position.y * tile_size.y
			camera.limit_right = map_rect.end.x * tile_size.x
			camera.limit_bottom = map_rect.end.y * tile_size.y

func reset_game_state() -> void:
	dead_enemies.clear()
	target_gate_destination = ""

	target_gate_destination = ""
