extends Camera3D

@export var rotate_speed_deg: float = 90.0

var target: Node3D
var offset: Vector3
var angle: float = 0.0

func _ready():
	make_current()
	target = SceneManager.control.get_current_player()
	if target:
		offset = global_position - target.global_position
		angle = atan2(offset.x, offset.z)

func _process(delta):
	if not target:
		return

	var rotation_input := 0.0
	if Input.is_action_pressed("camera_rotate_left"):
		rotation_input += 1.0
	if Input.is_action_pressed("camera_rotate_right"):
		rotation_input -= 1.0

	angle += deg_to_rad(rotation_input * rotate_speed_deg * delta)

	var radius := Vector2(offset.x, offset.z).length()
	var height := offset.y

	var new_offset := Vector3(
		sin(angle) * radius,
		height,
		cos(angle) * radius
	)

	global_position = target.global_position + new_offset
	look_at(target.global_position, Vector3.UP)
