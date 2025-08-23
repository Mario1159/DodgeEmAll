extends Control

@export_node_path("Button") var connect_button_path: NodePath
@export_node_path("TextEdit") var name_input_path: NodePath
@export var game_scene: PackedScene

var connect_button: Button
var name_input: TextEdit

var player : Player

func _ready():
	connect_button = get_node(connect_button_path)
	name_input = get_node(name_input_path)
	connect_button.pressed.connect(_on_connect_pressed)

	SceneManager.client.connected.connect(_on_connected)
	SceneManager.client.connection_failed.connect(_on_connection_failed)
	
	player = preload("res://prefabs/local_player.tscn").instantiate()
	SceneManager.control.set_current_player(player)

func _on_connect_pressed():
	var name = name_input.text.strip_edges()
	if name.is_empty():
		print("Please enter a name before connecting.")
		return
	SceneManager.control.get_current_player().username = name
	SceneManager.client.connect_to_server()

func _on_connected():
	player.username = name_input.text.strip_edges()
	SceneManager.change_scene(game_scene, player)

func _on_connection_failed():
	print("Connection failed. Please try again.")
