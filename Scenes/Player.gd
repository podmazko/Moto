extends Node3D


@onready var Root:Node3D=$Root
@onready var Camera:Camera3D=$Camera3D


func _ready() -> void:
	PlayerData.SpeedChange.connect(SpeedChange)


var _press_times:=[0.0,0.0]
var _impulse:float
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
			if !event.echo:
				if event.is_action("left"):
					_impulse+=-1+2*int(event.pressed)
					if !event.pressed:
						if _press_times[0]>0.0:
							_jump_n=_calc_jump_n(1)
					else:
						_press_times[0]=0.25 #sec to unpress for jump

				elif event.is_action("right"):
					_impulse-=-1+2*int(event.pressed)
					
					if !event.pressed:
						if _press_times[1]>0.0:
							_jump_n=_calc_jump_n(-1)
					else:
						_press_times[1]=0.25 #sec to unpress for jump

				#elif event.is_action("speed"):
					#PlayerData.emit_signal("SpeedChange",1+int(event.pressed))


func _calc_jump_n(_change:int):
	if _jump_n!=null:#has current jump in queue
		return clamp(_jump_n+_change,-1,1)
	
	if abs(Root.position.z)<7: #line width
		return clamp(0+_change,-1,1)
	elif Root.position.z>0:
		return clamp(1+_change,-1,1)
	else:
		return clamp(-1+_change,-1,1)
	


var _jump_n=null
var _impulse_r:float
var _control:float
var road_width:float=22.0
func _process(delta: float) -> void:
	_press_times[0]-=delta
	_press_times[1]-=delta
	
	_impulse_r=lerp(_impulse_r,_impulse,delta*3.5*_control)
		
	if _jump_n!=null:
		if _impulse!=0.0 and _press_times[0]<0.1 and _press_times[1]<0.1:#rewrite jump command, but dont stop double taps
			_jump_n=null
		else:
			var _aim_z=_jump_n*17 #jump width
			var _diff=(_aim_z-$Root.global_position.z)
			if abs(_diff)<0.5: #how close jump deternines as finished
				_jump_n=null

			_impulse_r=lerp( _impulse_r,((_diff*_control)/12),delta*4 )
	
	if abs(Root.position.z)>road_width: #stop going out of roadd
		if (Root.position.z<0)==(_impulse_r<0):
			_impulse_r=lerp(_impulse_r,0.0,delta*25)
			if abs(_impulse_r)<0.1:
				_impulse_r=0.0
	
	Root.position.z+=_impulse_r*delta*70
	Root.rotation_degrees.x=lerp(Root.rotation_degrees.x,_impulse_r*25,delta*10*_control)
	Root.rotation_degrees.y=lerp(Root.rotation_degrees.y,_impulse_r*32,delta*12*_control)



var SpdTween:Tween
func SpeedChange(_new_speed:float,time:float=3.0)->void:
	PlayerData.speed=_new_speed
	_control=pow(PlayerData.speed,0.5)#conrollobility according to speed

	if SpdTween:
		SpdTween.kill()
	SpdTween=create_tween().set_parallel(true)
	SpdTween.tween_property(Camera,"fov",75+40*(_control-1),time*0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	SpdTween.tween_property(Camera,"rotation_degrees:x",-28+35*(_control-1),time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
