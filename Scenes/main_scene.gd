extends Node3D

var _speed=0.0 #m per second

var _bpm=145
var _bpm_time:float
var _aim_spd:float #distance 50 every beat

@onready var Chunk:PackedScene=preload("res://Scenes/Parts/RoadChunk.tscn")
@onready var Mat=preload("res://Assets/Materials/NeonMat.tres")
@onready var RoadMat=preload("res://Assets/Materials/RoadMat.tres")
var chunks:=[]

func _ready() -> void:
	_bpm_time=_bpm/60
	var _beats_per_second:float=_bpm/60.0
	_aim_spd=_beats_per_second*50
	#start gen
	for i in 5:
		gen_chunk(false)
	_count=250

var _count:float=200
var _beats:int
func _process(delta: float) -> void:
	_speed=lerp(_speed,_aim_spd*PlayerData.speed,delta*0.3)
	_count-=_speed*delta
	$Player.position.x-=_speed*delta
	$CanvasLayer/ColorRect.material.set("shader_parameter/mask_edge",0.6+0.5*(2-PlayerData.speed))
	
	if _count<0.0:
		gen_chunk()
	
	var _time:float=$AudioStreamPlayer2D.get_playback_position()+AudioServer.get_time_since_last_mix()
	var _db=db_to_linear(AudioServer.get_bus_peak_volume_left_db(0,0) )
	$CanvasLayer/Panel.scale.x=3*_db
	$CanvasLayer/Panel2.scale.x=$CanvasLayer/Panel.scale.x
	Mat.set("shader_parameter/light",pow($CanvasLayer/Panel.scale.x,0.6) )
	RoadMat.set("shader_parameter/light",_db)


func gen_chunk(_clean:=true)->void:
	_count=200
	var _node=Chunk.instantiate()
	var _pos_x:float=50.0
	if !chunks.is_empty():
		_pos_x=chunks[chunks.size()-1].position.x-200
	$Road.add_child(_node)
	chunks.append(_node)
	_node.position.x=_pos_x
	
	if _clean:#deleta last chunk
		chunks[0].queue_free()
		chunks.remove_at(0)
