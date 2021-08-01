extends RigidBody2D

signal touched_ring()
signal lost_touch()

var touching_ring := false
var ring = null

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.is_pressed():
		if not get_parent().watering:
			queue_free()


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
