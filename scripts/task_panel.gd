extends PanelContainer

@onready var close_button: Button = $VBoxContainer/CloseButton

func _ready() -> void:
	visible = false
	close_button.pressed.connect(close_panel)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_tasks"):
		visible = not visible
		get_viewport().set_input_as_handled()

func toggle_panel() -> void:
	visible = not visible

func close_panel() -> void:
	visible = false

func _on_task_button_pressed() -> void:
	toggle_panel()
