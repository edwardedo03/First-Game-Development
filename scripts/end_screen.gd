extends CanvasLayer

@onready var victory = $Overlay/Victory
@onready var game_over = $Overlay/GameOver

var is_showing_end_screen := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	victory.hide()
	game_over.hide()

	victory.get_node("VBoxContainer/RestartButton").pressed.connect(restart_game)
	victory.get_node("VBoxContainer/QuitButton").pressed.connect(quit_game)

	game_over.get_node("VBoxContainer/RestartButton").pressed.connect(restart_game)
	game_over.get_node("VBoxContainer/QuitButton").pressed.connect(quit_game)


func show_victory() -> void:
	is_showing_end_screen = true
	victory.show()
	game_over.hide()
	get_tree().paused = true


func show_game_over() -> void:
	is_showing_end_screen = true
	game_over.show()
	victory.hide()
	get_tree().paused = true


func restart_game() -> void:
	get_tree().paused = false
	victory.hide()
	game_over.hide()
	is_showing_end_screen = false

	GameManager.reset_game_state()
	get_tree().change_scene_to_file(GameManager.MAIN_SCENE_PATH)


func quit_game() -> void:
	get_tree().paused = false
	get_tree().quit()
