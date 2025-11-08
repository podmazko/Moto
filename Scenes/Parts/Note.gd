extends MeshInstance3D


func collide()->void:
	$Fx.emitting=true
	

func born(_pos:Vector3)->void:
	position.z=_pos.z
	$FxBorn.emitting=true
	var _tween:Tween=create_tween().set_parallel(true)
	_tween.tween_property(self,"position:y",0.0,0.55).from(10)\
						.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self,"position:x",_pos.x,0.45).from(_pos.x-5)\
						.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self,"scale",Vector3(1,1,1),0.4).from(Vector3(0.25,4,0.25))\
						.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
