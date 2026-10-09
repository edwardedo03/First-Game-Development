extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("jump_power_up"):
		body.jump_power_up()
		queue_free()
