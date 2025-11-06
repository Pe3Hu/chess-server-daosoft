class_name World
extends Node


enum PieceColor {
	WHITE = 8,      # 01000
	BLACK = 16      # 10000
}

var multiplayer_peer = ENetMultiplayerPeer.new()

var connected_peer_ids = []

var turn = true if randi_range(0, 1) else false



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
			rpc_id(connected_peer_ids[0], "give_color", PieceColor.WHITE)
			rpc_id(connected_peer_ids[1], "give_color", PieceColor.BLACK)

func remove_player(peer_id):
	connected_peer_ids.erase(peer_id)


@rpc("any_peer")
func send_move_info(start_pos, end_pos, promotion):
	pass
	#if white:
		#if promotion != null && promotion not in [2, 3, 4, 5]:
			#return
	#else:
		#if promotion != null && promotion not in [-2, -3, -4, -5]:
			#return
	
	#selected_piece = start_pos
	#show_options()
	
	#if multiplayer.get_remote_sender_id() == connected_peer_ids[0] && turn:
		#if moves.has(end_pos):
			#set_move(start_pos, end_pos, promotion)
			#rpc_id(connected_peer_ids[1], "return_enemy_move", start_pos, end_pos, promotion)
			#turn = !turn
		#else:
			#print("WRONG!")
	#elif multiplayer.get_remote_sender_id() == connected_peer_ids[1] && !turn:
		#if moves.has(end_pos):
			#set_move(start_pos, end_pos, promotion)
			#rpc_id(connected_peer_ids[0], "return_enemy_move", start_pos, end_pos, promotion)
			#turn = !turn
		#else:
			#print("WRONG!")
	
@rpc("authority")
func return_enemy_move():
	pass
	
@rpc("authority")
func give_turn():
	pass
	
@rpc("authority")
func give_color(color_):
	pass


func set_move(start_pos : Vector2, end_pos : Vector2, promotion = null):
	pass
