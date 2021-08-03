extends RigidBody2D

signal touched_ring()
signal lost_touch()

var touching_ring := false
var ring = null

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.is_pressed():
		if not get_parent().watering:
			# disable all collisions, as if this object doesn't exist anymore
			collision_layer = 0
			collision_mask = 0
			$pop_tween.interpolate_property(self, "scale", Vector2(1, 1), Vector2(0.01, 0.01), 0.25, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
			$pop_tween.interpolate_property($sprite, "modulate:a", 1.0, 0.2, 0.25, Tween.TRANS_LINEAR, Tween.EASE_OUT)
			$pop_tween.start()
			$pop_sound.play()


func _physics_process(delta):
	$Label.text = str(get_colliding_bodies().size())


func _on_CircleCrusher_body_entered(body):
	if body is StaticBody2D:
		touching_ring = true
		emit_signal("touched_ring")


func _on_CircleCrusher_body_exited(body):
	if body is StaticBody2D:
		touching_ring = false
		emit_signal("lost_touch")


func _on_CircleCrusher_tree_exiting():
	if touching_ring:
		emit_signal("lost_touch")


func _on_pop_tween_tween_all_completed():
	queue_free()
