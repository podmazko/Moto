extends MeshInstance3D

func _ready() -> void:
	set_process(false)


func collide()->void:
	$Fx.emitting=true
	

func miss()->void:
	pass

func born(_pos:Vector3,posing:Array=[])->void:
	position.z=_pos.z
	position.x=_pos.x
	$FxBorn.emitting=true
	var _tween:Tween=create_tween().set_parallel(true)
	_tween.tween_property(self,"position:y",0.0,0.55).from(7)\
						.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self,"scale",Vector3(1,1,1),0.35).from(Vector3(0.33,3,0.33))\
						.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if !posing.is_empty():
		posing_time=posing[2]
		Player=posing[1]
		Main=posing[0]
		posing_diff=posing[3]
		set_process(true)


var posing_time:float
var Main:Node3D
var Player:Node3D
var posing_diff:float
func _process(delta: float) -> void:
	posing_time-=delta
	var _estimated_pos_x:float=Player.global_position.x-Main.speed*posing_time-posing_diff
	position.x=lerp(position.x,_estimated_pos_x,delta*5)

	if posing_time<0.1:
		set_process(false)
