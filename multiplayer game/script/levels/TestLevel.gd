extends Spatial

onready var p1pos = $Players/Player1Pos
onready var p2pos = $Players/Player2Pos

func _ready():
	#loads in player 1
	var p1 = preload("res://scenes/entitys/player.tscn").instance()
	#gives the player a unique ID
	p1.set_name(str(get_tree().get_network_unique_id()))
	#makes it clear that this player owns this character controller
	p1.set_network_master(get_tree().get_network_unique_id())
	p1.global_transform = p1pos.global_transform
	add_child(p1)
	
	var p2 = preload("res://scenes/entitys/player.tscn").instance()
	p2.set_name(str(Global.player2id))
	p2.set_network_master(Global.player2id)
	p2.global_transform = p2pos.global_transform
	add_child(p2)
