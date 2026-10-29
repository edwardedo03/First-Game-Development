extends CanvasLayer

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var stamina_bar: TextureProgressBar = $StaminaBar
@onready var pause_menu: Control = $Menu

@onready var health_label: Label = $HealthPanel/HealthLabel
@onready var attack_damage_label: Label = $AttackDamagePanel/AttackDamageLabel

func _ready() -> void:
	if pause_menu:
		pause_menu.hide()

func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("ui_cancel"):
		#toggle_pause()

	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return

	if GameManager.end_screen \
	and is_instance_valid(GameManager.end_screen) \
	and GameManager.end_screen.is_showing_end_screen:
		return

	toggle_pause()
	get_viewport().set_input_as_handled()

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
		
	if health_label:
		health_label.text = "%d / %d" % [current_hp, max_hp]
		
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
	if not is_inside_tree():
			return
	GameManager.respawn_to_main_map()
	# GameManager.reset_game_state()
	
	# var player = get_tree().get_first_node_in_group("player")
	# if player:
		# player.queue_free()
	
	#get_tree().reload_current_scene()
	# get_tree().change_scene_to_file("res://scenes/main_map.tscn")

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()

func _on_pause_button_pressed() -> void:
	toggle_pause()

func update_attack_damage(damage: int) -> void:
	if attack_damage_label:
		attack_damage_label.text = "Attack Damage : %d" % damage
