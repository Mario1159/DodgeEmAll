extends Node

@export var player: Player

func _ready():
	get_tree().root.get_child(0).client.message_received.connect(_on_message_received)

func _input(event):
	if $TextEdit.has_focus() and event is InputEventKey and event.is_pressed():
		if event.key_label == KEY_ENTER:
			get_viewport().set_input_as_handled()
			var message : String = $TextEdit.text.strip_edges()
			if message != "":
				SceneManager.client.send_message(message)
				$TextEdit.clear()
			$TextEdit.release_focus()

		elif event.key_label == KEY_ESCAPE:
			$TextEdit.release_focus()

func _on_message_received(sender_name: String, message: String):
	$Panel/RichTextLabel.append_text("%s: %s\n" % [sender_name, message])
