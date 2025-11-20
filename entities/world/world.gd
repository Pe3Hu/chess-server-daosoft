class_name World 
extends Node


@onready var game: Game = %Game

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
				recive_color.rpc_id(connected_peer_ids[_i], MultiplayerManager.player_colors[_i])
				recive_mode_parameters.rpc_id(connected_peer_ids[_i], FrameworkSettings.active_mode)
			
			MultiplayerManager.peer_to_opponent[connected_peer_ids[0]] = connected_peer_ids[1]
			MultiplayerManager.peer_to_opponent[connected_peer_ids[1]] = connected_peer_ids[0]
			#recive_opponent_peer_id.rpc_id(connected_peer_ids[0], connected_peer_ids[1])
			#recive_opponent_peer_id.rpc_id(connected_peer_ids[1], connected_peer_ids[0])
	
func remove_player(peer_id):
	if MultiplayerManager.peer_to_opponent.has(peer_id):
		var opponent_peer_id = MultiplayerManager.peer_to_opponent[peer_id]
		MultiplayerManager.peer_to_opponent.erase(opponent_peer_id)
	
	MultiplayerManager.peer_to_opponent.erase(peer_id)
	connected_peer_ids.erase(peer_id)
	
func users_recive_void_result(captured_tile_ids_: Array) -> void:
	if captured_tile_ids_.is_empty(): return
	print("server send void result")
	for tile_id in captured_tile_ids_:
		for peer_id in connected_peer_ids:
			client_recive_void_tile_id_fatigue.rpc_id(peer_id, tile_id)
	
#@rpc("any_peer")
#func recive_opponent_peer_id():
	#pass

@rpc("any_peer")
func server_recive_move_parameters(start_tile_id_: int, end_tile_id_: int, move_index_: int, move_type_: FrameworkSettings.MoveType) -> void:
	if MultiplayerManager.move_index + 1 != move_index_: return
	
	MultiplayerManager.move_index = move_index_
	#var sender_index = connected_peer_ids.find(multiplayer.get_remote_sender_id())
	#var reciver_index = (sender_index + 1) % connected_peer_ids.size()
	print(["server resend move to", get_opponent_peer()])
	game.referee.apply_void_mod()
	client_recive_move_parameters.rpc_id(get_opponent_peer(), start_tile_id_, end_tile_id_, MultiplayerManager.move_index, move_type_)

	#client_recive_move_parameters.rpc_id(connected_peer_ids[reciver_index], start_tile_id_, end_tile_id_, MultiplayerManager.move_index, move_type_)

@rpc("any_peer")
func server_recive_initiative_switch():
	var sender_index = connected_peer_ids.find(multiplayer.get_remote_sender_id())
	print(["server recive initiative from", FrameworkSettings.color_to_str[MultiplayerManager.active_color], sender_index])
	
	if MultiplayerManager.active_color != MultiplayerManager.player_colors[sender_index]: return
	#var reciver_index = (sender_index + 1) % connected_peer_ids.size()
	
	
	
	MultiplayerManager.switch_active_color()
	client_recive_initiative_switch.rpc_id(get_opponent_peer())
	#client_recive_initiative_switch.rpc_id(connected_peer_ids[reciver_index])

@rpc("any_peer")
func client_recive_initiative_switch():
	print("server send initiative to ", FrameworkSettings.color_to_str[MultiplayerManager.active_color])
	pass

@rpc("any_peer")
func recive_color():
	pass
	
@rpc("any_peer")
func try_start_game():
	var peer_id = connected_peer_ids.find(multiplayer.get_remote_sender_id())
	if FrameworkSettings.PieceColor.WHITE == MultiplayerManager.player_colors[peer_id]:
		MultiplayerManager.reset()
		for _i in connected_peer_ids.size():
			start_game.rpc_id(connected_peer_ids[_i])

@rpc("any_peer")
func send_mode_parameters(mode_type_: FrameworkSettings.ModeType):
	var peer_id = connected_peer_ids.find(multiplayer.get_remote_sender_id())
	if FrameworkSettings.PieceColor.WHITE == MultiplayerManager.player_colors[peer_id]:
		FrameworkSettings.active_mode = mode_type_
		
		#var sender_index = connected_peer_ids.find(multiplayer.get_remote_sender_id())
		#var reciver_index = (sender_index + 1) % connected_peer_ids.size()
		
		recive_mode_parameters.rpc_id(get_opponent_peer(), mode_type_)

@rpc("any_peer")
func client_recive_move_parameters(_start_tile_id_: int, _end_tile_id_: int, _move_index_: int, _move_type_: FrameworkSettings.MoveType):
	pass

@rpc("any_peer")
func recive_mode_parameters():
	pass
	
@rpc("any_peer")
func start_game():
	pass

@rpc("any_peer")
func server_recive_fox_swap_parameters(focus_tile_id_: int, swap_tile_id_: int):
	print(connected_peer_ids)
	#var sender_index = connected_peer_ids.find(multiplayer.get_remote_sender_id())
	#var reciver_index = (sender_index + 1) % connected_peer_ids.size()
	MultiplayerManager.peer_to_fox[get_opponent_peer()] = [focus_tile_id_, swap_tile_id_]
	print(["server recive fox to", get_opponent_peer(), [focus_tile_id_, swap_tile_id_]])
	
	if MultiplayerManager.peer_to_fox.keys().size() == 2:
		print(["server resend fox"])
		for peer_id in MultiplayerManager.peer_to_fox:
			var focus_tile_id = MultiplayerManager.peer_to_fox[peer_id][0]
			var swap_tile_id = MultiplayerManager.peer_to_fox[peer_id][1]
			client_recive_fox_swap_parameters.rpc_id(peer_id, focus_tile_id, swap_tile_id)
		
		MultiplayerManager.peer_to_fox = {}

@rpc("authority")
func client_recive_fox_swap_parameters():
	pass

@rpc("any_peer")
func client_recive_void_tile_id_fatigue(_tile_id_: int):
	pass

@rpc("any_peer")
func declare_defeat():
	#var sender_index = connected_peer_ids.find(multiplayer.get_remote_sender_id())
	#var reciver_index = (sender_index + 1) % connected_peer_ids.size()
	#declare_victory.rpc_id(connected_peer_ids[reciver_index])
	declare_victory.rpc_id(get_opponent_peer())
	MultiplayerManager.reset()

@rpc("any_peer")
func declare_victory():
	#var sender_index = connected_peer_ids.find(multiplayer.get_remote_sender_id())
	#var reciver_index = (sender_index + 1) % connected_peer_ids.size()
	#declare_defeat.rpc_id(connected_peer_ids[reciver_index])
	declare_defeat.rpc_id(get_opponent_peer())

func _input(event) -> void:
	if event is InputEventKey:
		match event.keycode:
			KEY_ESCAPE:
				get_tree().quit()

func get_opponent_peer() -> int:
	return MultiplayerManager.peer_to_opponent[multiplayer.get_remote_sender_id()]
