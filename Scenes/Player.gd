extends Node3D


@onready var Root:Node3D=$Root
@onready var Camera:Camera3D=$Camera3D
@onready var Light:SpotLight3D=$Root/Model/Light


func _ready() -> void:
	PlayerData.SpeedChange.connect(SpeedChange)


var _press_times:=[0.0,0.0]
var pressed:=[false,false]
var _impulse:float
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
			if !event.echo:
				if event.is_action("left"):
					pressed[0]=event.pressed
					_calc_impulse()
					if !event.pressed:
						if _press_times[0]>0.0:
							_jump_n=_calc_jump_n(1)
					else:
						_press_times[0]=0.25 #sec to unpress for jump

				elif event.is_action("right"):
					pressed[1]=event.pressed
					_calc_impulse()
					
					if !event.pressed:
						if _press_times[1]>0.0:
							_jump_n=_calc_jump_n(-1)
					else:
						_press_times[1]=0.25 #sec to unpress for jump

				#elif event.is_action("speed"):
					#PlayerData.emit_signal("SpeedChange",1+int(event.pressed))

func _calc_impulse()->void:
	_impulse=int(pressed[0])-int(pressed[1])

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
	Light.light_energy=150+200*PlayerData.db
	Light.light_color=lerp(Color(0.6,0.05,0.8),Color(0.95,0.65,0.1),0.5*PlayerData.db)
	Light.spot_angle=25+10*PlayerData.db
	
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

	if bump_tween:
		bump_tween.kill()
	if SpdTween:
		SpdTween.kill()
	SpdTween=create_tween().set_parallel(true)
	SpdTween.tween_property(Camera,"fov",85+40*(_control-1),time*0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	SpdTween.tween_property(Camera,"rotation_degrees:x",-28+35*(_control-1),time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	
var _base_saturation:float
func _init_player(_env:Environment,_stream:AudioStreamPlayer)->void:
	env=_env
	stream=_stream
	_base_saturation=env.adjustment_saturation

var env:Environment
var stream:AudioStreamPlayer
var bump_tween:Tween
func bit_bump(_time:float,_power:float)->void:
	bump_tween=create_tween().set_parallel(true)
	if !SpdTween.is_running(): #no bumb during camera movement
		bump_tween.tween_property(Camera,"fov",Camera.fov,_time*0.4).from(Camera.fov-0.4*pow(_power,2.0))\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	
	bump_tween.tween_property(env,"adjustment_saturation",_base_saturation,_time*0.6).from(_base_saturation*1.1)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	bump_tween.tween_property(stream,"volume_db",0.0,_time*0.6).from(3*_power)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
