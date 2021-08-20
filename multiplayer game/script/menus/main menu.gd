extends Node2D

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")


func _on_ButtonHost_pressed():
	#creating a new server
	var net = NetworkedMultiplayerENet.new()
	#sets the server number and amount of player
	net.create_server(54833, 2)
	get_tree().set_network_peer(net)
	print ("hosting")


func _on_ButtonJoin_pressed():
	var net = NetworkedMultiplayerENet.new()
	net.create_client("26.41.208.87", 54833)
	get_tree().set_network_peer(net)

func _player_connected(id):
	Global.player2id = id
	var game = preload("res://scenes/levels/testing/TestLevel.tscn").instance()
	get_tree().get_root().add_child(game)
	hide()
