extends Node

var is_connected: bool = false

signal connected
signal connection_failed
signal message_received(sender_name: String, message: String)
signal player_spawned(id: int, player_name: String)
signal player_disconnected(id: int)

var _peer := ENetMultiplayerPeer.new()
var player_name : String
var players: Dictionary = {}

func connect_to_server(ip: String = "127.0.0.1", port: int = 4242):
	player_name = SceneManager.control.get_current_player().username
	if player_name.is_empty():
		push_error("Player name is empty.")
		emit_signal("connection_failed")
		return

	var result := _peer.create_client(ip, port)
	if result != OK:
		push_error("Failed to create client peer.")
		emit_signal("connection_failed")
		return

	multiplayer.multiplayer_peer = _peer
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)

	print("Connecting to %s:%d as '%s'..." % [ip, port, player_name])

func _on_connected():
	print("Connected to server.")
	is_connected = true
	emit_signal("connected")
	rpc("_player_joined", player_name)

func _on_connection_failed():
	print("Connection to server failed.")
	is_connected = false
	emit_signal("connection_failed")

func send_message(message: String):
	message = message.strip_edges()
	if not is_connected or message.is_empty():
		return
	print("Sending message: %s" % message)
	rpc_id(1, "_server_receive_message", player_name, message)

func _process(delta):
	if not is_connected:
		return
	var player = SceneManager.control.get_current_player()
	if player:
		rpc_id(1, "_update_transform", get_tree().get_multiplayer().get_unique_id(), player.position, player.rotation)

@rpc("any_peer", "call_remote", "reliable")
func _broadcast_message(sender_name: String, message: String):
	print("Received message: %s: %s" % [sender_name, message])
	emit_signal("message_received", sender_name, message)

@rpc("any_peer", "call_remote", "reliable")
func _spawn_player(id: int, player_name: String):
	print("_spawn_player received: ID %d, name '%s'" % [id, player_name])
	if id in players:
		print("Already have player %d, skipping" % id)
		return
	if id == multiplayer.get_unique_id():
		print("This is local player, skipping")
		return

	var player_scene = preload("res://prefabs/local_player.tscn")
	var player_instance = player_scene.instantiate()
	player_instance.username = player_name
	add_child(player_instance)
	players[id] = player_instance
	print("Spawned remote player '%s' with ID %d" % [player_name, id])
	SceneManager.control.get_node("AudioManager").setup_audio()
	emit_signal("player_spawned", id, player_name)

@rpc("any_peer", "call_remote", "reliable")
func _remove_player(id: int):
	if id in players:
		players[id].queue_free()
		players.erase(id)
		print("Player ID %d removed" % id)
		emit_signal("player_disconnected", id)

@rpc("any_peer", "call_remote", "reliable")
func _update_transform(peer_id: int, position: Vector3, rotation: Vector3):
	pass

@rpc("any_peer", "call_remote", "reliable")
func _set_transform(peer_id: int, position: Vector3, rotation: Vector3):
	if peer_id == get_tree().get_multiplayer().get_unique_id():
		return
	if peer_id in players:
		players[peer_id].position = position
		players[peer_id].rotation = rotation
		#print("Updated remote player %d position %s rotation %s" % [peer_id, position, rotation])
	else:
		print("Tried to update transform of unknown player %d" % peer_id)


@rpc("any_peer", "call_remote", "reliable")
func _player_joined(player_name: String):
	pass

@rpc("any_peer", "call_remote", "reliable")
func _server_receive_message(sender_name: String, message: String):
	pass
