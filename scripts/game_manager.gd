extends Node

var target_gate_destination: String = ""
var dead_enemies: Dictionary = {}

const MAIN_SCENE_PATH = "res://scenes/main_map.tscn"

func transition_to_scene(target_path: String, gate_name: String, player_node: Node) -> void:
	if not is_instance_valid(player_node):
		return
	
	target_gate_destination = gate_name
	
	var old_parent = player_node.get_parent()
	if old_parent:
		old_parent.remove_child(player_node)
	
	var error = get_tree().change_scene_to_file(target_path)
	if error != OK:
		push_error("Gagal ganti scene: " + target_path)
		return
		
	await get_tree().scene_changed
	
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return
	
	var existing_player = current_scene.get_node_or_null("Skeleton")
	if existing_player and existing_player != player_node:
		existing_player.queue_free()
		await get_tree().process_frame
	
	current_scene.add_child(player_node)
	
	var spawn_node = current_scene.get_node_or_null(target_gate_destination)
	if spawn_node:
		player_node.global_position = spawn_node.global_position
	else:
		push_warning("Spawn gate tidak ketemu: " + target_gate_destination)
	
	player_node.ladder_layer = get_tree().get_first_node_in_group(
		"ladder_layer"
	) as TileMapLayer
	
	player_node.find_lava_layer()
	
	if player_node.ladder_layer == null:
		push_warning("TileMapLayer tangga tidak ditemukan pada scene baru")
	
	setup_camera_limits(player_node, current_scene)
	
	
func setup_camera_limits(player_node: Node2D, current_scene: Node) -> void:
	var camera := player_node.get_node_or_null("Camera2D") as Camera2D

	if camera == null:
		push_warning("Camera2D tidak ditemukan pada player.")
		return

	var top_left := current_scene.get_node_or_null(
        "CameraBounds/TopLeft"
	) as Marker2D

	var bottom_right := current_scene.get_node_or_null(
        "CameraBounds/BottomRight"
	) as Marker2D

	if top_left == null or bottom_right == null:
		push_warning("TopLeft atau BottomRight CameraBounds tidak ditemukan.")
		return

	# Ambil posisi global kedua marker.
	var min_x := minf(top_left.global_position.x, bottom_right.global_position.x)
	var min_y := minf(top_left.global_position.y, bottom_right.global_position.y)
	var max_x := maxf(top_left.global_position.x, bottom_right.global_position.x)
	var max_y := maxf(top_left.global_position.y, bottom_right.global_position.y)

	# Terapkan batas kamera.
	camera.limit_left = floori(min_x)
	camera.limit_top = floori(min_y)
	camera.limit_right = ceili(max_x)
	camera.limit_bottom = ceili(max_y)

	camera.enabled = true
	camera.make_current()
	camera.reset_smoothing()


func reset_game_state() -> void:
	dead_enemies.clear()
	target_gate_destination = ""
	

func respawn_to_main_map() -> void:
	reset_game_state()
	var error := get_tree().change_scene_to_file(MAIN_SCENE_PATH)
	if error != OK:
		push_error("Gagal kembali ke main map.")
