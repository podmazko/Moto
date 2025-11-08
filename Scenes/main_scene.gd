extends Node3D

#track setup
var bpm=70
var beat_zones:={0:"pause", 16:"normal-", 36:"normal",68:"speed", 100:"normal",132:"speed",
				164:"longing",196:"normal+",228:"speed",292:"pause"}
				
				
				
#data params:
var distance_per_bit:=100#m
#normal/+ - normal speed, obj per 2/1 beat   #speed - speed x2 + objects every beat
#longing - long press beats objects   #pause - nothing
var zones_data:={#beats per object, object type(0-nothing,1-basic,2-long), speed
	"pause":[0,0, 1.0],
	"normal-":[2,1, 1.0],
	"normal":[1,1, 1.0],
	"normal+":[1,1, 1.0],
	"speed":[1,1, 2.0],
	"longing":[1,2, 1.0],
	}


#calculatables
var speed=0.0 #current m per second
var aim_spd:float #aimed m per second
var beat_time:float #seconds to one beat
var beat:int=0 #current bit, helps generate objects on road
var zone:String="pause"


@onready var Note:PackedScene=preload("res://Scenes/Parts/Note.tscn")
@onready var Chunk:PackedScene=preload("res://Scenes/Parts/RoadChunk.tscn")
@onready var Mat=preload("res://Assets/Materials/NeonMat.tres")
@onready var RoadMat=preload("res://Assets/Materials/RoadMat.tres")
var chunks:=[]
var notes:={}


@onready var Road:Node3D=$Road
@onready var Player=$Player
@onready var AudioPlayer:AudioStreamPlayer=$AudioStreamPlayer

func _ready() -> void:
	PlayerData.SpeedChange.connect(SpeedChange)
	
	beat_time=60.0/bpm
	aim_spd=(bpm/60.0)*distance_per_bit
	
	beat=0
	zone_change(beat_zones[beat])

	#start gen
	for i in 5:
		gen_chunk(false)
	_road_m=250

	PlayerData.call_deferred("emit_signal","SpeedChange",1)



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
		gen_next_note(beat)
		check_note(beat)
		if beat_zones.has(beat):
			zone_change(beat_zones[beat])
		$CanvasLayer/BitTracker.text=str(beat)+"\n"+zone

	#volume to visual
	var _db=db_to_linear(AudioServer.get_bus_peak_volume_left_db(0,0) )
	Mat.set("shader_parameter/light",pow(3*_db,0.6) )
	RoadMat.set("shader_parameter/light",_db)
	
	$CanvasLayer/Panel.scale.x=3*_db
	$CanvasLayer/Panel2.scale.x=$CanvasLayer/Panel.scale.x





func gen_next_note(_beat:int)->void:
	var _note:MeshInstance3D=Note.instantiate()
	Road.add_child(_note)
	var _born_pos:Vector3
	_born_pos.x=Player.position.x-distance_per_bit*4-1
	_born_pos.z=randi_range(-1,1)*17
	_note.born(_born_pos)
	notes[_beat+4]=_note
	
	#delete node
	var beat_to_clean:int=_beat-3
	if notes.has(beat_to_clean):
		notes[beat_to_clean].queue_free()
		notes.erase(beat_to_clean)

func check_note(_beat:int)->void:
	if notes.has(_beat):
		notes[_beat].collide()



@onready var SpeedLines:ColorRect=$CanvasLayer/SpeedLines
func zone_change(_new_zone:String)->void:
	zone=_new_zone
	
	var _new_speed:float=zones_data[zone][2]
	if PlayerData.speed!=_new_speed:
		PlayerData.emit_signal("SpeedChange",_new_speed)
	SpeedLines.material.set("shader_parameter/mask_edge",0.6+0.5*(2-PlayerData.speed))


func SpeedChange(_new_speed:float,time:float=3.0)->void:
	var _tween:Tween=create_tween()
	_tween.tween_property(self,"speed",aim_spd*_new_speed,time)\
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
