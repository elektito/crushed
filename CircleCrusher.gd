extends RigidBody2D

signal touched_ring()
signal lost_touch()

var touching_ring := false
var ring = null
var possible_bg_colors = [
	Color.aqua,
	Color.blue,
	Color.blueviolet,
	Color.crimson,
	Color.greenyellow,
	Color.darkcyan,
	Color.darkgreen,
	Color.darkred,
	Color.darkorange,
	Color.darkkhaki,
	Color.darkviolet,
]

var possible_border_colors = [
	Color.aqua,
	Color.blue,
	Color.blueviolet,
	Color.crimson,
	Color.greenyellow,
	Color.darkcyan,
	Color.darkgreen,
	Color.darkred,
	Color.darkorange,
	Color.darkkhaki,
	Color.darkviolet,
]

func _ready():
	randomize()
	$bg.modulate = possible_bg_colors[randi() % len(possible_bg_colors)]
	$border.modulate = possible_bg_colors[randi() % len(possible_border_colors)]
	while $border.modulate == $bg.modulate:
		$border.modulate = possible_bg_colors[randi() % len(possible_border_colors)]


func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.is_pressed():
		if not get_parent().watering:
			# disable all collisions, as if this object doesn't exist anymore
			collision_layer = 0
			collision_mask = 0
			$pop_tween.interpolate_property(self, "scale", Vector2(1, 1), Vector2(0.01, 0.01), 0.25, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
			$pop_tween.interpolate_property($border, "modulate:a", 1.0, 0.2, 0.25, Tween.TRANS_LINEAR, Tween.EASE_OUT)
			$pop_tween.interpolate_property($bg, "modulate:a", 1.0, 0.2, 0.25, Tween.TRANS_LINEAR, Tween.EASE_OUT)
			$pop_tween.start()
			$pop_sound.play()


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
