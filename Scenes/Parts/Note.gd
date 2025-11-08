extends MeshInstance3D


func collide()->void:
	$Fx.emitting=true
	

func born(_pos:Vector3)->void:
	position.z=_pos.z
	
	var _tween:Tween=create_tween().set_parallel(true)
	_tween.tween_property(self,"position:y",0.0,0.35).from(15)\
						.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self,"position:x",_pos.x,0.45).from(_pos.x-5)\
						.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self,"scale",Vector3(1,1,1),0.4).from(Vector3(0.5,2,0.5))\
						.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
