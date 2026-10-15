extends CanvasLayer

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var stamina_bar: TextureProgressBar = $StaminaBar
@onready var pause_menu: Control = $Menu

func _ready() -> void:
	if pause_menu:
		pause_menu.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	
	if is_paused:
		pause_menu.show()
	else:
		pause_menu.hide()

func update_health(current_hp: int, max_hp: int) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
	else:
		call_deferred("update_health", current_hp, max_hp)
		
func update_stamina(current_stamina: float, max_stamina: float) -> void:
	if stamina_bar:
		stamina_bar.max_value = max_stamina
		stamina_bar.value = current_stamina
	else:
		call_deferred("update_stamina", current_stamina, max_stamina)

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	GameManager.reset_game_state()
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()

func _on_pause_button_pressed() -> void:
	toggle_pause()
