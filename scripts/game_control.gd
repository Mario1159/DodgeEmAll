extends Node

var _player: Player

# TODO: Node to easily access all major logic nodes like managers or players

func get_current_player():
	return _player

func set_current_player(player: Player):
	_player = player
