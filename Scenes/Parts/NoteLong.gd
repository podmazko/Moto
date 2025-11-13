extends MeshInstance3D

var note_width:float=8.5

@onready var Tail:Node3D=$TailRoot
@onready var FxLong:GPUParticles3D=$FxLong

func _ready() -> void:
	set_process(false)


func collide()->void:
	$Fx.emitting=true
	

func born(_pos:Vector3,posing:Array=[])->void:
	position.z=_pos.z
	position.x=_pos.x
	$FxBorn.emitting=true
	var _tween:Tween=create_tween().set_parallel(true)
	_tween.tween_property(self,"position:y",-0.1,0.55).from(7)\
						.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self,"scale",Vector3(1,1,1),0.35).from(Vector3(0.33,3,0.33))\
						.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if !posing.is_empty():
		posing_time=posing[2]
		tail_posing_time=posing[3]
		Player=posing[1]
		Main=posing[0]
		posing_diff=posing[4]
		set_process(true)

var tail_posing_time:float #time to end tail
var posing_time:float #time to collide
var Main:Node3D
var Player:Node3D
var posing_diff:float
func _process(delta: float) -> void:
	tail_posing_time-=delta
	posing_time-=delta
	var _estimated_pos_x:float=Player.global_position.x-Main.speed*posing_time-posing_diff
	position.x=lerp(position.x,_estimated_pos_x,delta*5)
	var _estimated_tail_pos_x:float=Player.global_position.x-Main.speed*tail_posing_time
	Tail.scale.x=lerp(Tail.scale.x,_estimated_pos_x-_estimated_tail_pos_x,delta*5)
	
	if posing_time<0.1: #player reached note
		if abs(Player.global_position.z-position.z)<note_width:
			FxLong.global_position=Player.global_position-Vector3(posing_diff+2,0,0)
			var _destortion:float=randf()*0.05
			Tail.scale.z=0.975+_destortion
			Tail.scale.x+=_destortion*25
			if !FxLong.emitting:
				FxLong.emitting=true
		else:
			if FxLong.emitting:
				FxLong.emitting=false
			if posing_time<-0.3: #not on a path 0.3s+ after collidong
				miss(clamp(2.0-tail_posing_time,0.2,2.0)) #Slower hiding if on tail
	
	if tail_posing_time<0.1:
		set_process(false)

func miss(_time:float=0.2)->void:
	set_process(false)
	var _tween:Tween=create_tween().set_parallel(true)
	_tween.tween_property(Tail,"scale:x",0,_time)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(Tail,"scale:z",-0.05,_time)\
			.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
