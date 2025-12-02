class_name World 
extends Node


@onready var game: Game = %Game

var multiplayer_peer = ENetMultiplayerPeer.new()

var connected_peer_ids = []


func _ready():
	host()
	
func host():
	multiplayer_peer.create_server(MultiplayerManager.SERVEW_PORT)
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
		print([peer_id, "joined to server", connected_peer_ids])
		if connected_peer_ids.size() == 2:
			FrameworkSettings.reset_mode_and_test_parameters()
			preparation()
			
			
			for _i in connected_peer_ids.size():
				recive_color.rpc_id(connected_peer_ids[_i], MultiplayerManager.player_colors[_i])
				client_recive_mode_type.rpc_id(connected_peer_ids[_i], FrameworkSettings.active_mode)
			
			MultiplayerManager.peer_to_opponent[connected_peer_ids[0]] = connected_peer_ids[1]
			MultiplayerManager.peer_to_opponent[connected_peer_ids[1]] = connected_peer_ids[0]
			#recive_opponent_peer_id.rpc_id(connected_peer_ids[0], connected_peer_ids[1])
			#recive_opponent_peer_id.rpc_id(connected_peer_ids[1], connected_peer_ids[0])
	
func preparation() -> void:
	FrameworkSettings.BOARD_SIZE = FrameworkSettings.mod_to_board_size[FrameworkSettings.active_mode]
	
	if FrameworkSettings.BOARD_SIZE.x * FrameworkSettings.BOARD_SIZE.y != game.board.resource.tiles.size():
		game.board.resize()
	
	game.reset()
	MultiplayerManager.reset()
	
func remove_player(peer_id):
	if connected_peer_ids.size() == 2:
		server_declare_victory.rpc_id(get_opponent_peer())
		client_recive_fail_start.rpc_id(get_opponent_peer())
		MultiplayerManager.reset()
	
	if MultiplayerManager.peer_to_opponent.has(peer_id):
		var opponent_peer_id = MultiplayerManager.peer_to_opponent[peer_id]
		MultiplayerManager.peer_to_opponent.erase(opponent_peer_id)
	
	MultiplayerManager.peer_to_opponent.erase(peer_id)
	connected_peer_ids.erase(peer_id)
	
	print([peer_id, "removed from server", connected_peer_ids])
	
func users_recive_void_result(captured_tile_ids_: Array) -> void:
	if captured_tile_ids_.is_empty(): return
	print(["server send void result", captured_tile_ids_.size()])
	for tile_id in captured_tile_ids_:
		for peer_id in connected_peer_ids:
			client_recive_void_tile_id_fatigue.rpc_id(peer_id, tile_id)
	
#@rpc("any_peer")
#func recive_opponent_peer_id():
	#pass
	
func process_move_parameters(start_tile_id_: int, end_tile_id_: int, move_type_: FrameworkSettings.MoveType) -> void:
	var start_tile = game.board.tiles.get_child(start_tile_id_)
	var end_tile = game.board.tiles.get_child(end_tile_id_)
	var moved_piece = game.board.get_piece(start_tile.resource.piece)
	if moved_piece == null: return
	
	var move_resource = MoveResource.new(moved_piece.resource, start_tile.resource, end_tile.resource)
	if move_resource.type != move_type_:
		move_resource.type = move_type_
		
		if FrameworkSettings.CAPTURE_TYPES.has(move_type_):
			move_resource.captured_piece = end_tile.resource.piece
	
	if move_resource.piece.template.type == FrameworkSettings.PieceType.HELLHORSE:
		var is_hellhorse = game.notation.resource.moves.is_empty()
		
		if !is_hellhorse:
			var last_move = game.notation.resource.moves.back()
			is_hellhorse = last_move.piece.template.type != FrameworkSettings.PieceType.HELLHORSE or last_move.piece.template.color != move_resource.piece.template.color
		
		if is_hellhorse:
			move_resource.type = FrameworkSettings.MoveType.HELLHORSE
	
	game.receive_move(move_resource, false)
	
	match FrameworkSettings.active_mode:
		FrameworkSettings.ModeType.VOID:
			if MultiplayerManager.is_harakiri:
				for peer_id in connected_peer_ids:
					client_recive_void_tile_id_harakiri.rpc_id(peer_id, start_tile_id_)
			else:
				for peer_id in connected_peer_ids:
					client_recive_move_parameters.rpc_id(peer_id, start_tile_id_, end_tile_id_, MultiplayerManager.move_index, move_type_)
			
			game.recalc_piece_environment()
			MultiplayerManager.is_harakiri = false
			return
	
	client_recive_move_parameters.rpc_id(get_opponent_peer(), start_tile_id_, end_tile_id_, MultiplayerManager.move_index, move_type_)

@rpc("any_peer")
func server_recive_quit():
	remove_player(multiplayer.get_remote_sender_id())
	
	if connected_peer_ids.size() == 1:
		recive_color.rpc_id(connected_peer_ids[0], MultiplayerManager.player_colors[0])

@rpc("any_peer")
func server_recive_move_parameters(start_tile_id_: int, end_tile_id_: int, move_index_: int, move_type_: FrameworkSettings.MoveType) -> void:
	if MultiplayerManager.move_index + 1 != move_index_: return
	
	MultiplayerManager.move_index = move_index_
	#var sender_index = connected_peer_ids.find(multiplayer.get_remote_sender_id())
	#var reciver_index = (sender_index + 1) % connected_peer_ids.size()
	print(["server resend " + str(move_index_) + " move to", get_opponent_peer()])
	process_move_parameters(start_tile_id_, end_tile_id_, move_type_)
	game.referee.apply_void_mod()
	
	#client_recive_move_parameters.rpc_id(connected_peer_ids[reciver_index], start_tile_id_, end_tile_id_, MultiplayerManager.move_index, move_type_)

@rpc("any_peer")
func server_recive_initiative_switch():
	var sender_index = connected_peer_ids.find(multiplayer.get_remote_sender_id())
	print(["server recive initiative from", FrameworkSettings.color_to_str[MultiplayerManager.active_color], sender_index])
	
	if MultiplayerManager.active_color != MultiplayerManager.player_colors[sender_index]: return
	
	MultiplayerManager.switch_active_color()
	client_recive_initiative_switch.rpc_id(get_opponent_peer())

@rpc("any_peer")
func client_recive_initiative_switch():
	print("server send initiative to ", FrameworkSettings.color_to_str[MultiplayerManager.active_color])
	pass

@rpc("any_peer")
func recive_color():
	pass
	
@rpc("any_peer")
func try_start_game():
	if connected_peer_ids.size() != 2: 
		client_recive_fail_start.rpc_id(multiplayer.get_remote_sender_id())
		return
	var peer_id = connected_peer_ids.find(multiplayer.get_remote_sender_id())
	#print(["try_start_game", connected_peer_ids, multiplayer.get_remote_sender_id(), peer_id])
	if FrameworkSettings.PieceColor.WHITE == MultiplayerManager.player_colors[peer_id]:
		preparation()
		for _i in connected_peer_ids.size():
			start_game.rpc_id(connected_peer_ids[_i])
		
		print([FrameworkSettings.active_mode, "start parameters:"])
		for type in FrameworkSettings.test_type_parameters:
			print([type, FrameworkSettings.get_test_parameter_value(type)])

@rpc("any_peer")
func client_recive_fail_start() -> void:
	pass

@rpc("any_peer")
func start_game():
	pass

@rpc("any_peer")
func server_recive_mode_type(mode_type_: FrameworkSettings.ModeType):
	var peer_id = connected_peer_ids.find(multiplayer.get_remote_sender_id())
	if FrameworkSettings.PieceColor.WHITE == MultiplayerManager.player_colors[peer_id]:
		FrameworkSettings.active_mode = mode_type_
		if connected_peer_ids.size() != 2: return
		client_recive_mode_type.rpc_id(get_opponent_peer(), mode_type_)

@rpc("any_peer")
func client_recive_move_parameters(_start_tile_id_: int, _end_tile_id_: int, _move_index_: int, _move_type_: FrameworkSettings.MoveType):
	pass

@rpc("any_peer")
func client_recive_mode_type():
	pass
	
@rpc("any_peer")
func server_recive_fox_swap_parameters(focus_tile_id_: int, swap_tile_id_: int):
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
func client_recive_void_tile_id_harakiri(_tile_id_: int):
	pass

@rpc("any_peer")
func server_recive_void_tile_id_harakiri(tile_id_: int):
	print(["server resend harakiri", tile_id_])
	game.board.apply_tile_fatigue(tile_id_)
	client_recive_void_tile_id_fatigue.rpc_id(get_opponent_peer(), tile_id_)

@rpc("any_peer")
func server_recive_spy_move_parameters(start_tile_id_: int, end_tile_id_: int):
	var start_tile = game.board.tiles.get_child(start_tile_id_)
	var end_tile = game.board.tiles.get_child(end_tile_id_)
	var moved_piece = game.board.get_piece(start_tile.resource.piece)
	if moved_piece == null: return
	var player = game.referee.resource.color_to_player[moved_piece.resource.template.color]
	
	print(["server process_spy_move from", player.color, "to", player.opponent.color, start_tile_id_, end_tile_id_])
	
	var move_resource = MoveResource.new(moved_piece.resource, start_tile.resource, end_tile.resource)
	player.spy_move = move_resource
	client_recive_spy_move_parameters.rpc_id(get_opponent_peer(), start_tile_id_, end_tile_id_)
	
	MultiplayerManager.switch_active_color()
	for peer_id in connected_peer_ids:
		client_recive_initiative_switch.rpc_id(peer_id)

@rpc("any_peer")
func client_recive_spy_move_parameters(_start_tile_id_: int, _end_tile_id_: int):
	pass

@rpc("any_peer")
func client_declare_defeat():
	server_declare_victory.rpc_id(get_opponent_peer())
	
@rpc("any_peer")
func client_declare_victory():
	server_declare_defeat.rpc_id(get_opponent_peer())

@rpc("any_peer")
func server_declare_victory():
	client_declare_defeat.rpc_id(get_opponent_peer())
	print(["server delcare", MultiplayerManager.player_colors[multiplayer.get_remote_sender_id()], "as victory"])
	MultiplayerManager.reset()

@rpc("any_peer")
func server_declare_defeat():
	client_declare_victory.rpc_id(get_opponent_peer())
	print(["server delcare", MultiplayerManager.player_colors[multiplayer.get_remote_sender_id()], "as defeat"])
	MultiplayerManager.reset()


@rpc("any_peer")
func server_recive_test_parameter(type_: FrameworkSettings.TestTypeParameter, value_: float):
	FrameworkSettings.set_test_parameter_value(type_, value_)
	print(["server_test_parameter", type_, value_])
	if connected_peer_ids.size() != 2: return
	client_recive_test_parameter.rpc_id(get_opponent_peer(), type_, value_)

@rpc("authority")
func client_recive_test_parameter(_type_: FrameworkSettings.TestTypeParameter, _value_: float):
	pass


func get_opponent_peer() -> int:
	if !MultiplayerManager.peer_to_opponent.has(multiplayer.get_remote_sender_id()): return multiplayer.get_remote_sender_id()
	return MultiplayerManager.peer_to_opponent[multiplayer.get_remote_sender_id()]
