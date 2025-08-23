extends Node

var enet_peer: ENetMultiplayerPeer
var players: Dictionary = {}

func _ready():
	start_server()

func start_server():
	enet_peer = ENetMultiplayerPeer.new()
	var port = 4242
	var max_clients = 10
	var result := enet_peer.create_server(port, max_clients)
	if result != OK:
		print("Failed to create server.")
		return

	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	print("Server started on port %d" % port)

func _on_peer_connected(id: int):
	print("Client connected: ID %d" % id)
	for peer_id in players.keys():
		if peer_id != id:
			rpc_id(id, "_spawn_player", peer_id, players[peer_id])

func _on_peer_disconnected(id: int):
	print("Client disconnected: ID %d" % id)
	players.erase(id)
	rpc("_remove_player", id)

@rpc("any_peer", "call_remote", "reliable")
func _player_joined(player_name: String):
	var caller_id = multiplayer.get_remote_sender_id()
	print("_player_joined called by ID %d with name '%s'" % [caller_id, player_name])
	
	if caller_id in players:
		print("Warning: player ID %d already exists!" % caller_id)
	else:
		players[caller_id] = player_name
		print("Registered player '%s' with ID %d" % [player_name, caller_id])
	
	for peer_id in players.keys():
		if peer_id != caller_id:
			print("Notifying client %d to spawn player %d ('%s')" % [peer_id, caller_id, player_name])
			rpc_id(peer_id, "_spawn_player", caller_id, player_name)
		else:
			print("Skipping notifying self (%d)" % caller_id)


@rpc("any_peer", "call_remote", "reliable")
func _server_receive_message(sender_name: String, message: String):
	print("Server received message from '%s': %s" % [sender_name, message])
	rpc("_broadcast_message", sender_name, message)

@rpc("any_peer", "call_remote", "reliable")
func _update_transform(peer_id: int, position: Vector3, rotation: Vector3):
	for id in get_tree().get_multiplayer().get_peers():
		if id != peer_id:
			rpc_id(id, "_set_transform", peer_id, position, rotation)


@rpc("any_peer", "call_remote", "reliable")
func _set_transform(peer_id: int, position: Vector3, rotation: Vector3):
	pass

@rpc("any_peer", "call_remote", "reliable")
func _broadcast_message(sender_name: String, message: String):
	emit_signal("message_received", sender_name, message)

@rpc("any_peer", "call_remote", "reliable")
func _spawn_player(id: int, player_name: String):
	pass

@rpc("any_peer", "call_remote", "reliable")
func _remove_player(id: int):
	emit_signal("player_disconnected", id)
