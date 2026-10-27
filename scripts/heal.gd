extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("apply_power_up"):
		body.apply_power_up("heal")
		queue_free()
