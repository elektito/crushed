extends RigidBody2D

signal touched_ring()
signal lost_touch()

var touching_ring := false
var ring = null
var last_v

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
	
	# the crusher can be any of the different sizes (scale factors), some of
	# which are more likely than the others.
	var scale_factors := [
		0.75,
		1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
		1.5, 1.5,
		2.0
	]
	var scale_factor_idx := randi() % len(scale_factors)
	var scale_factor : float = scale_factors[scale_factor_idx]
	set_scale_factor(scale_factor)
	mass = scale_factor


func set_scale_factor(scale_factor):
	if get_filename() == 'res://CircleCrusher.tscn':
		$shape.shape.radius *= scale_factor
		$bg.scale *= scale_factor
		$border.scale *= scale_factor
	elif get_filename() == 'res://TriangleCrusher.tscn':
		for i in range(len($shape.polygon)):
			$shape.polygon[i] *= Vector2(scale_factor, scale_factor)
		$bg.scale *= Vector2(scale_factor, scale_factor)
		$border.scale *= Vector2(scale_factor, scale_factor)


func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
		if not get_parent().watering:
			# disable all collisions, as if this object doesn't exist anymore
			collision_layer = 0
			collision_mask = 0
			#$pop_tween.interpolate_property(self, "scale", Vector2(1, 1), Vector2(0.01, 0.01), 0.25, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
			$pop_tween.interpolate_property($bg, "scale", null, Vector2(0.01, 0.01), 0.25, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
			$pop_tween.interpolate_property($border, "scale", null, Vector2(0.01, 0.01), 0.25, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
			$pop_tween.interpolate_property($border, "modulate:a", 1.0, 0.2, 0.25, Tween.TRANS_LINEAR, Tween.EASE_OUT)
			$pop_tween.interpolate_property($bg, "modulate:a", 1.0, 0.2, 0.25, Tween.TRANS_LINEAR, Tween.EASE_OUT)
			$pop_tween.start()
			$pop_sound.play()


func _on_CircleCrusher_body_entered(body):
	var delta_v = (linear_velocity - last_v).length()
	var momentum_diff = delta_v * mass
	
	# map momentum min to max range to 0.0 to 1.0
	var min_momentum = 10
	var max_momentum = 150
	var volume = (momentum_diff - min_momentum) / (max_momentum - min_momentum)
	volume = 0.0 if volume < 0.0 else volume
	volume = 1.0 if volume > 1.0 else volume
	var hit_sound = $hit_sound.duplicate()
	hit_sound.volume_db = linear2db(volume)
	hit_sound.play()
	hit_sound.connect("finished", self, "_on_hit_sound_finished", [hit_sound])
	add_child(hit_sound)
	
	if body is StaticBody2D:
		touching_ring = true
		emit_signal("touched_ring")


func _on_hit_sound_finished(hit_sound):
	hit_sound.queue_free()


func _physics_process(delta):
	last_v = linear_velocity


func _on_CircleCrusher_body_exited(body):
	if body is StaticBody2D:
		touching_ring = false
		emit_signal("lost_touch")


func _on_CircleCrusher_tree_exiting():
	if touching_ring:
		emit_signal("lost_touch")


func _on_pop_tween_tween_all_completed():
	queue_free()
