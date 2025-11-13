extends MeshInstance3D

var note_width:float=8.5
var base_scale:Vector3=Vector3(1,1,1)


func make_wall()->void:
	base_scale=Vector3(1.0,2.0,3.0)
	note_width*=3
	$Fx.amount=400


func _ready() -> void:
	set_process(false)


func collide()->void:
	$Fx.emitting=true
	

func miss()->void:
	pass

var _born_tween:Tween
func born(_pos:Vector3,posing:Array=[])->void:
	position.z=_pos.z
	position.x=_pos.x
	$FxBorn.emitting=true
	_born_tween=create_tween().set_parallel(true)
	_born_tween.tween_property(self,"position:y",-0.1,0.55).from(7)\
						.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_born_tween.tween_property(self,"scale",base_scale,0.35).from(base_scale*Vector3(0.33,3,0.33))\
						.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	PlayerData.Beat.connect(_beat_anim)
	if !posing.is_empty():
		posing_time=posing[2]
		Player=posing[1]
		Main=posing[0]
		posing_diff=posing[3]
		set_process(true)

func _beat_anim(_time:float)->void:
	if _born_tween.is_running():
		return

	var _tween:Tween=create_tween()
	_tween.tween_property(self,"scale",base_scale,_time*0.4).from(base_scale-PlayerData.db*Vector3(0.3,0.3,0.3))\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


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
