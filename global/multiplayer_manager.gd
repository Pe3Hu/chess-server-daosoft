extends Node



const SERVEW_PORT: int = 9999
#var notation: NotationResource = NotationResource.new()
#var referee: RefereeResource = RefereeResource.new()
#var board: BoardResource = BoardResource.new()
var player: PlayerResource
var move_index: int = 0
var is_harakiri: bool = false

var active_color: FrameworkSettings.PieceColor = FrameworkSettings.PieceColor.WHITE
var player_colors: Array[FrameworkSettings.PieceColor] = [FrameworkSettings.PieceColor.WHITE, FrameworkSettings.PieceColor.BLACK]

var peer_to_fox: Dictionary
var peer_to_opponent: Dictionary

func switch_active_color() -> void:
	var next_color_index = (player_colors.find(active_color) + 1) % player_colors.size()
	active_color = player_colors[next_color_index]
	
func reset() -> void:
	#FrameworkSettings.active_mode = FrameworkSettings.ModeType.CLASSIC
	move_index = 0
	
	peer_to_fox = {}
	#peer_to_opponent = {}
	
#func _init() -> void:
	#referee.board = board
	#board.referee = referee
	#
	#update_players()
	#
#func update_players() -> void:
	#for _player in referee.players:
		#if _player.color_template == user_color:
			#player = _player
		#
		#_player.board = board
	#
#func get_active_player() -> PlayerResource:
	#var active_player = player
	#
	#if user_color != active_color:
		#active_player = player.opponent
	#
	#return active_player
