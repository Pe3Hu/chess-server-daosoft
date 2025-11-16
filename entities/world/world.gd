class_name World 
extends Node



var multiplayer_peer = ENetMultiplayerPeer.new()

var connected_peer_ids = []

func _ready():
	host(9999)
	
func host(port):
	multiplayer_peer.create_server(port)
	multiplayer.multiplayer_peer = multiplayer_peer
	
	multiplayer_peer.peer_connected.connect(
		func(peer_id = multiplayer.get_unique_id()):
			add_player(peer_id)
	)
	
	multiplayer_peer.peer_disconnected.connect(
		func(peer_id = multiplayer.get_unique_id()):
			remove_player(peer_id)
	)
	
func add_player(peer_id):
	if connected_peer_ids.size() < 2:
		connected_peer_ids.append(peer_id)
		if connected_peer_ids.size() == 2:
			for _i in connected_peer_ids.size():
				rpc_id(connected_peer_ids[_i], "give_color", MultiplayerManager.player_colors[_i])
	
func remove_player(peer_id):
	connected_peer_ids.erase(peer_id)

@rpc("any_peer")
func send_move_parameters(start_tile_id_: int, end_tile_id_: int, move_type_: FrameworkSettings.MoveType) -> void:
	var sender_index = connected_peer_ids.find(multiplayer.get_remote_sender_id())
	var reciver_index = (sender_index + 1) % connected_peer_ids.size()
	MultiplayerManager.switch_active_color()
	
	if MultiplayerManager.active_color == MultiplayerManager.player_colors[reciver_index]:
		return_enemy_move.rpc_id(connected_peer_ids[reciver_index], MultiplayerManager.active_color, start_tile_id_, end_tile_id_, move_type_)
		#rpc_id(connected_peer_ids[reciver_index], "return_enemy_move", MultiplayerManager.active_color, start_tile_id_, end_tile_id_, move_type_)
		#rpc_id(connected_peer_ids[sender_index], "return_enemy_move", MultiplayerManager.active_color, start_tile_id_, end_tile_id_, move_type_)
	
	
@rpc("any_peer")
func return_enemy_move():
	pass
	
@rpc("any_peer")
func give_color():
	pass
	
@rpc("any_peer")
func try_start_game():
	var peer_id = connected_peer_ids.find(multiplayer.get_remote_sender_id())
	if FrameworkSettings.PieceColor.WHITE == MultiplayerManager.player_colors[peer_id]:
		for _i in connected_peer_ids.size():
			rpc_id(connected_peer_ids[_i], "start_game")

@rpc("any_peer")
func start_game():
	pass
#
##CHEATER PROOFING
#func show_options():
	#moves = get_moves(selected_piece)
	#if moves == []:
		#state = false
		#return
		#


func _input(event) -> void:
	if event is InputEventKey:
		match event.keycode:
			KEY_ESCAPE:
				get_tree().quit()
	
