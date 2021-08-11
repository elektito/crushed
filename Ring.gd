extends StaticBody2D

signal imploded()

var contacts := []
var crushing_force := 0.0
var all_crushers := []
var original_scale : Vector2
var disable_recalculate := false

func _ready():
	original_scale = scale


func register_contact(crusher):
	contacts.append(crusher)
	calculate_crushing_force()


func unregister_contact(crusher):
	contacts.erase(crusher)
	calculate_crushing_force()


func calculate_crushing_force():
	$Label.text = str(len(all_crushers))
	if disable_recalculate:
		return
	if len(all_crushers) <= 10:
		return
	var n = len(all_crushers) - 10
	if n > 250:
		n = 250
	var xx = 1.0 - 0.003 * n
	var cf = Vector2(xx, xx) * original_scale
	#scale = cf
	$scale_tween.interpolate_property(self, 'scale', null, cf, 0.015, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	$scale_tween.start()
	yield($scale_tween, "tween_completed")


var already_burst = false
func burst():
	if already_burst:
		return
	already_burst = true
	var burst_time := 0.016*15
	$scale_tween.stop_all()
	$burst_sound.play()
	$scale_tween.interpolate_property(self, 'scale', null, original_scale * 2, burst_time, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	$scale_tween.interpolate_property($sprite, 'modulate:a', 1.0, 0.0, burst_time, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	$scale_tween.start()
	yield($scale_tween, "tween_all_completed")
	
	get_parent().get_node("player").z_index = -100
	get_parent().get_node("plant").z_index = -100
	var implode_time := 1.5
	$scale_tween.interpolate_property(get_parent().get_node("player"), "modulate:a", null, 0.0, implode_time, Tween.TRANS_EXPO, Tween.EASE_IN)
	$scale_tween.interpolate_property(get_parent().get_node("plant"), "modulate:a", null, 0.0, implode_time, Tween.TRANS_EXPO, Tween.EASE_IN)
	for node in get_tree().get_nodes_in_group("crushers"):
		node.collision_layer = 0
		node.collision_mask = 0
		#node.linear_velocity = (get_parent().get_node("player").global_position - node.global_position) * 1
		node.mode = RigidBody2D.MODE_KINEMATIC
		$scale_tween.interpolate_property(node, "position", null, position, implode_time, Tween.TRANS_EXPO, Tween.EASE_IN)
		$scale_tween.interpolate_property(node.get_node("bg"), "modulate:a", null, 0.0, implode_time, Tween.TRANS_EXPO, Tween.EASE_IN)
		$scale_tween.interpolate_property(node.get_node("border"), "modulate:a", null, 0.0, implode_time, Tween.TRANS_EXPO, Tween.EASE_IN)
	$scale_tween.start()
	yield($scale_tween, "tween_all_completed")
	yield(get_tree().create_timer(0.5), "timeout")
	emit_signal("imploded")


func _on_doom_timer_timeout():
	if len(all_crushers) < 300:
		return
	
	for i in range(4):
		$sprite.scale = Vector2(0.985, 0.985)
		yield(get_tree().create_timer(0.035), "timeout")
		$sprite.scale = Vector2(1.0, 1.0)
		yield(get_tree().create_timer(0.035), "timeout")
