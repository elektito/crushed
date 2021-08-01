extends Node2D

var CircleCrusher := preload("res://CircleCrusher.tscn")
var scrw : int = ProjectSettings.get("display/window/size/width")
var scrh : int = ProjectSettings.get("display/window/size/height")

var dragging := false

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
	if len($ring.all_crushers) >= 500:
		return
	
	var crusher = CircleCrusher.instance()
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
	add_child(crusher)
	$ring.all_crushers.append(crusher)
	
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
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		$player.frame = 3
		$watering_timer.start()


func _on_watering_timer_timeout():
	$player.frame = 0
