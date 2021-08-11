extends Node2D

const BURST_LIMIT := 350

var CircleCrusher := preload("res://CircleCrusher.tscn")
var TriangleCrusher := preload("res://TriangleCrusher.tscn")
var DiamondCrusher := preload("res://DiamondCrusher.tscn")
var scrw : int = ProjectSettings.get("display/window/size/width")
var scrh : int = ProjectSettings.get("display/window/size/height")

var dragging := false
var watering := false setget set_watering
var mouse_inside_watering_area = false
var waiting_mouse := preload("res://assets/waiting-mouse.png")
var active_mouse := preload("res://assets/active-mouse.png")

func _ready():
	for i in range(0):
		_on_spawn_timer_timeout()


func set_watering(value : bool):
	watering = value
	adjust_spawn_rate()


func adjust_spawn_rate():
	# the worse the plant, the higher the spawn rate
	$spawn_timer.wait_time = 0.4 - 0.05 * $plant.frame
	
	if watering:
		$spawn_timer.wait_time /= 2.0


func _input(event):
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
	
	if not OS.is_debug_build():
		return
	
	if event is InputEventMouseButton and event.is_pressed():
		var z = 0.05
		if event.button_index == BUTTON_WHEEL_UP:
			$ring/Camera2D.zoom -= Vector2(z, z)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			$ring/Camera2D.zoom += Vector2(z, z)
	
	if event is InputEventMouseButton and event.button_index == BUTTON_MIDDLE:
		dragging = event.is_pressed()
	if dragging and event is InputEventMouseMotion:
		$ring/Camera2D.position -= event.relative

func _on_spawn_timer_timeout():
	if len($ring.all_crushers) >= BURST_LIMIT:
		$ring.burst()
		yield($ring, "imploded")
		get_tree().paused = true
		$crushed_screen.visible = true
		$crushed_screen.grab_focus()
		return
	
	var crusher_types = [
		CircleCrusher, CircleCrusher, CircleCrusher, CircleCrusher, CircleCrusher,
		TriangleCrusher,
		DiamondCrusher,
	]
	var crusher_type = crusher_types[randi() % len(crusher_types)]
	
	var crusher = crusher_type.instance()
	var pos : Vector2
	var region := randi() % 4
	match region:
		0:
			pos = Vector2(-100, rand_range(0, scrh))
		1:
			pos = Vector2(scrw + 100, rand_range(0, scrh))
		2:
			pos = Vector2(rand_range(0, scrw), -100)
		3:
			pos = Vector2(rand_range(0, scrw), scrw + 100)
	crusher.position = pos
	crusher.z_index = -100
	add_child(crusher)
	$ring.all_crushers.append(crusher)
	$ring.calculate_crushing_force()
	
	crusher.connect("touched_ring", self, "_on_crusher_touched", [crusher])
	crusher.connect("lost_touch", self, "_on_crusher_lost_touch", [crusher])
	crusher.connect("tree_exiting", self, "_on_crusher_exiting", [crusher])


func _on_crusher_touched(crusher):
	$ring.register_contact(crusher)


func _on_crusher_lost_touch(crusher):
	$ring.unregister_contact(crusher)


func _on_crusher_exiting(crusher):
	$ring.all_crushers.erase(crusher)


func _on_player_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed and not watering:
		set_watering(true)
		$player.frame = 1
		yield(get_tree().create_timer(0.016 * 3), "timeout")
		$player.frame = 2
		yield(get_tree().create_timer(0.016 * 3), "timeout")
		$player.frame = 3
		$watering_audio.play()
		$watering_timer.start()
		Input.set_custom_mouse_cursor(waiting_mouse, 0, Vector2(16, 16))
		$effect_circle.modulate = Color.blue
		$effect_circle.visible = true
		$effect_tween.interpolate_property($effect_circle, "scale", Vector2(0.125, 0.125), Vector2(1.0, 1.0), 1.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
		$effect_tween.interpolate_property($effect_circle, "modulate:a", 1.0, 0.0, 1.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
		$effect_tween.start()


func _on_watering_timer_timeout():
	if $plant.frame > 0:
		$plant.frame -= 1
	
	$player.frame = 0
	set_watering(false)
	if mouse_inside_watering_area:
		Input.set_custom_mouse_cursor(active_mouse, 0, Vector2(15, 13))
	else:
		Input.set_custom_mouse_cursor(null)
	
	# restart plant life stage timer
	$plant_timer.start()


func _on_plant_timer_timeout():
	var plant_last_frame := 6
	$plant.frame += 1
	adjust_spawn_rate()
	$crumble_sound.play()
	
	$effect_circle.visible = true
	$effect_circle.modulate = Color.darkgreen
	$effect_tween.interpolate_property($effect_circle, "scale", Vector2(1.0, 1.0), Vector2(0.125, 0.125), 1.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$effect_tween.interpolate_property($effect_circle, "modulate:a", 1.0, 0.0, 1.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$effect_tween.start()
	
	if $plant.frame == plant_last_frame:
		get_tree().paused = true
		$dead_plant_screen.visible = true
		$dead_plant_screen.grab_focus()


func _on_end_screen_gui_input(event):
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
	if Input.is_action_just_pressed("restart"):
		get_tree().paused = false
		get_tree().reload_current_scene()


func _on_effect_tween_tween_all_completed():
	$effect_circle.visible = false


func _on_area_mouse_entered():
	mouse_inside_watering_area = true
	if not watering:
		Input.set_custom_mouse_cursor(active_mouse, 0, Vector2(15, 13))


func _on_area_mouse_exited():
	mouse_inside_watering_area = false
	if not watering:
		Input.set_custom_mouse_cursor(null)
