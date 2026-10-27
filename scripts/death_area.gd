extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if not is_inside_tree():
		return
	GameManager.respawn_to_main_map()
	#get_tree().reload_current_scene()
