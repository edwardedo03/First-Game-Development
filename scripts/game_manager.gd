extends Node

var target_gate_destination: String = ""
var dead_enemies: Dictionary = {}
var deafeated_bosses: Array[String] = []
var defeated_final_bosses: Array[String] = []

const REQUIRED_BOSS: Array[String] = [
	"dark_golem",
	"golem",
	"ice_golem",
]

const MAIN_SCENE_PATH = "res://scenes/main_map.tscn"

const END_SCREEN_SCENE = preload("res://scenes/end_screen.tscn")
var end_screen: CanvasLayer

func _ready() -> void:
	end_screen = END_SCREEN_SCENE.instantiate()
	get_tree().root.add_child.call_deferred(end_screen)

func show_victory_screen() -> void:
	if end_screen and is_instance_valid(end_screen):
		end_screen.show_victory()

func show_game_over_screen() -> void:
	if end_screen and is_instance_valid(end_screen):
		end_screen.show_game_over()

func mark_boss_defeated(boss_id: String) -> void:
	if boss_id == "" or boss_id in deafeated_bosses:
		return
	
	deafeated_bosses.append(boss_id)
	print("Boss dikalahkan: ", boss_id)
	print("Progress Boss: ", deafeated_bosses.size(), " / 3")
	
func is_boss_defeated(boss_id: String) -> bool:
	return boss_id in deafeated_bosses
	
func all_bosses_defeated() -> bool:
	for boss_id in REQUIRED_BOSS:
		if boss_id not in deafeated_bosses:
			return false
	
	return true
	
func mark_final_boss_defeated(boss_id: String) -> void:
	if boss_id == "" or boss_id in defeated_final_bosses:
		return

	defeated_final_bosses.append(boss_id)
	print("Final boss dikalahkan: ", boss_id)
	print(
		"Progres final boss: ",
		defeated_final_bosses.size(),
		" / ",
		REQUIRED_BOSS.size()
	)

func all_final_bosses_defeated() -> bool:
	for boss_id in REQUIRED_BOSS:
		if boss_id not in defeated_final_bosses:
			return false

	return true


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
	
	player_node.boss_power_up()
	
	
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
	deafeated_bosses.clear()
	defeated_final_bosses.clear()
	target_gate_destination = ""
	

func respawn_to_main_map() -> void:
	reset_game_state()
	var error := get_tree().change_scene_to_file(MAIN_SCENE_PATH)
	if error != OK:
		push_error("Gagal kembali ke main map.")
