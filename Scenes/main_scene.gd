extends Node3D

#track setup
var distance_per_bit:float#m
var bpm:int
var beat_zones:Dictionary
var counter_multiplayer:int=1 #for x2 bpm songs
				
				
#data params:
#normal/+ - normal speed, obj per 2/1 beat   #speed - speed x2 + objects every beat
#longing - long press beats objects   #pause - nothing
var zones_data:={#beats per object, object type(0-nothing,1-basic,2-long), speed,bump_power,patter
	"pause":[999,0, 1.0,  0.5,"none"],
	"normal-":[2,1, 1.0,  0.65,"side_to_side"],
	"normal":[1,1, 1.0,  0.95,"never_same"],
	"longing-":[4,2, 1.0,  0.5,"step_size_one"],
	"wall":[1,3, 1.0,  1.5,"center"],
	
	"speedpause":[999,0, 1.5,  1.0,"none"],
	"speedwall":[1,3, 1.5,  1.65,"center"],
	"speed":[1,1, 1.5,  1.05,"never_same"],
	
	}


#calculatables
var speed=0.0 #current m per second
var speed_base:float #aimed m per second
var beat_time:float #seconds to one beat
var beat:int=0 #current bit, helps generate objects on road
var zone:String="pause"


var Viewport_:Viewport
@onready var Note:PackedScene=preload("res://Scenes/Parts/Note.tscn")
@onready var NoteLong:PackedScene=preload("res://Scenes/Parts/NoteLong.tscn")
@onready var Chunk:PackedScene=preload("res://Scenes/Parts/RoadChunk.tscn")
@onready var Mat=preload("res://Assets/Materials/NeonMat.tres")
@onready var RoadMat=preload("res://Assets/Materials/RoadMat.tres")
@onready var FxMat=preload("res://Assets/Fx/ParticleMat.tres")
var chunks:=[]
var notes:={}


@onready var Road:Node3D=$Road
@onready var Player=$Player
@onready var AudioPlayer:AudioStreamPlayer=$AudioStreamPlayer

func _ready() -> void:
	Viewport_=get_viewport()
	Viewport_.size_changed.connect(_viewport_change_size)
	_viewport_change_size()
	
	PlayerData.SpeedChange.connect(SpeedChange)
	Player._init_player($WorldEnvironment.environment,$AudioStreamPlayer)

	_set_song("AfterDark")
	_reset_road()


func _viewport_change_size()->void:
	SpeedLines.size.y=Viewport_.size.y*1.3
	SpeedLines.position.y=-0.3*Viewport_.size.y

func _set_song(_name:String)->void:
	var _song_info:Dictionary=Data.Songs[_name]
	
	
	AudioPlayer.stream=load(_song_info["path"])
	for _param in ["distance_per_bit","bpm","beat_zones","counter_multiplayer"]:
		set(_param,_song_info[_param])
	
	AudioPlayer.play()
	beat_time=60.0/bpm
	speed_base=(bpm/60.0)*distance_per_bit
	
	beat=0
	PlayerData.speed=0.0
	zone_change(beat_zones[beat])


func _reset_road()->void:
	for _ch in Road.get_children():
		_ch.queue_free()
	chunks=[]
	notes={}
	#start gen
	for i in 5:
		gen_chunk(false)
	_road_m=250



func _process(delta: float) -> void:
	_road_m-=speed*delta
	Player.position.x-=speed*delta

	if _road_m<0.0: #road generating check
		gen_chunk()
	
	#bit tracker
	var _time:float=AudioPlayer.get_playback_position()+AudioServer.get_time_since_last_mix()
	var _beat=int(_time/beat_time)
	if _beat!=beat:
		beat=_beat
		gen_beat=beat+3
		PlayerData.emit_signal("Beat",beat_time)
		check_cur_note()
		gen_next_note()
		if beat_zones.has(beat):
			zone_change(beat_zones[beat])
		$CanvasLayer/BitTracker.text=str(beat)+"\n"+zone

	#volume to visual
	var _db=db_to_linear(AudioServer.get_bus_peak_volume_left_db(0,0) )
	PlayerData.db=_db
	Mat.set("shader_parameter/light",pow(3*_db,0.6) )
	RoadMat.set("shader_parameter/light",_db)
	
	#$CanvasLayer/Panel.scale.x=3*_db
	#$CanvasLayer/Panel2.scale.x=$CanvasLayer/Panel.scale.x
	FxMat.albedo_color=Color(1.0,0.65,0.0)*(1.1+0.25*_db)

func _set_gen_zone(_zone:String)->void:
	gen_zone=_zone
	gen_zone_info=zones_data[gen_zone]
	obj_gen_counter=0

var gen_beat:int
var gen_zone:String
var gen_zone_info:Array
var obj_gen_counter:int=0
func gen_next_note()->void:
	var _beat_diff:int=gen_beat-beat
	var _time:float=_beat_diff*beat_time
	
	obj_gen_counter+=1
	if beat_zones.has(gen_beat): #change estimated zone
		_set_gen_zone(beat_zones[gen_beat])
	
	#should gen?
	var gen_every_n:int=gen_zone_info[0]*counter_multiplayer
	if float(obj_gen_counter)/gen_every_n==obj_gen_counter/gen_every_n:
		var posing:=[]
		var estim_speed:float=speed_base*gen_zone_info[2]
		var _pos_diff:float=pow(estim_speed/speed_base,2) #for beuty collide
		var _born_pos:Vector3
		
		var _note:MeshInstance3D
		match gen_zone_info[1]:#node typed
			0:
				return
			1:#base
				_note=Note.instantiate()
				_born_pos.z=randi_range(-1,1)*17
				if estim_speed!=speed:
					estim_speed=lerp(speed,estim_speed,0.4)
					posing=[self,Player.Root,_time,_pos_diff]
			2: #long
				_note=NoteLong.instantiate()
				_born_pos.z=randi_range(-1,1)*17
				estim_speed=lerp(speed,estim_speed,0.4)
				posing=[self,Player.Root,_time,_time+(float(gen_every_n)-0.5*counter_multiplayer)*beat_time,_pos_diff]
			3:#wall
				_note=Note.instantiate()
				_note.make_wall()
				if estim_speed!=speed:
					estim_speed=lerp(speed,estim_speed,0.4)
					posing=[self,Player.Root,_time,_pos_diff]
		
		Road.add_child(_note)
		_born_pos.x=Player.position.x-_time*estim_speed-_pos_diff
		
		_note.born(_born_pos,posing)
		notes[gen_beat]=_note
	

func check_cur_note()->void:
	if notes.has(beat):
		var _note:MeshInstance3D=notes[beat]
		if abs(_note.position.z-Player.Root.global_position.z)<_note.note_width:
			Player.bit_bump(beat_time,bump_power)
			_note.collide()
		else:
			_note.miss()

	#delete node
	var beat_to_clean:int=beat-5
	if notes.has(beat_to_clean):
		notes[beat_to_clean].queue_free()
		notes.erase(beat_to_clean)


@onready var SpeedLines:ColorRect=$CanvasLayer/SpeedLines
var bump_power:float

func zone_change(_new_zone:String)->void:
	zone=_new_zone
	
	var _new_speed:float=zones_data[zone][2]
	bump_power=zones_data[zone][3]
	if PlayerData.speed!=_new_speed:
		PlayerData.emit_signal("SpeedChange",_new_speed)
	var _tween:Tween=create_tween()
	_tween.tween_property(SpeedLines.material,"shader_parameter/mask_edge",1.08-0.38*PlayerData.speed,1.5)

	if gen_zone.is_empty():
		_set_gen_zone(zone)
		

func SpeedChange(_new_speed:float,time:float=3.0)->void:
	var _tween:Tween=create_tween()
	_tween.tween_property(self,"speed",speed_base*_new_speed,time)\
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


var _road_m:float=200 #to count when to generate next road chunk
func gen_chunk(_clean:=true)->void:
	_road_m=200
	var _node=Chunk.instantiate()
	var _pos_x:float=50.0
	if !chunks.is_empty():#not first chunk
		_pos_x=chunks[chunks.size()-1].position.x-200
	Road.add_child(_node)
	chunks.append(_node)
	_node.position.x=_pos_x
	
	if _clean:#deleta last chunk
		chunks[0].queue_free()
		chunks.remove_at(0)





##### NOTES
# Notes generating(types, Z placement,Z placement pattern?)
#moyse controller
#wallnote  impulse to full scene
#song name
#ubder wheel fx + special fx on longing notes
#another road objects
#new note models
#two base colors setting(for each song their own)
#diegetical level counter(0-100%?)
#song selecting
#kisel near road's sides
