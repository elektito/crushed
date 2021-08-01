extends StaticBody2D

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
