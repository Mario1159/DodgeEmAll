extends Node

@export var server_scene: PackedScene
@export var game_menu_scene: PackedScene

@export var client_manager_packed_scene: PackedScene
@export var server_manager_packed_scene: PackedScene

var current_scene_root: Node
var client: Node
var control: Node

signal scene_changed()

func _ready():
	control = $GameControl
	if OS.has_feature("dedicated_server"):
		if server_manager_packed_scene:
			client = server_manager_packed_scene.instantiate()
			add_child(client)
		if server_scene:
			change_scene(server_scene)
			print("Running as dedicated server. Switched to server scene.")
		else:
			push_error("Server scene not set.")
	else:
		if client_manager_packed_scene:
			client = client_manager_packed_scene.instantiate()
			add_child(client)
		if game_menu_scene:
			change_scene(game_menu_scene)
			print("Running as client or editor. Switched to game menu.")
		else:
			push_error("Game menu scene not set.")

func change_scene(scene: PackedScene, passthrough: Node = null):
	if (passthrough):
		$Passthough.add_child(passthrough)
	if is_instance_valid(current_scene_root):
		current_scene_root.queue_free()
	current_scene_root = scene.instantiate()
	$Scene.call_deferred("add_child", current_scene_root)
	current_scene_root.tree_entered.connect(_emit_scene_changed_signal)

func _emit_scene_changed_signal():
	if $Passthough.get_child_count() > 0:
		$Passthough.get_child(0).reparent($Scene)
	get_tree().process_frame.connect(func(): scene_changed.emit(), CONNECT_ONE_SHOT)
	
