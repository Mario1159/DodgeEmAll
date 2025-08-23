extends CharacterBody3D

class_name Player

@export var speed: float = 4.0
@export var jump_speed: float = 6.0
@export var mouse_sensitivity: float = 0.002

var username: String = "anonymous"

var camera: Camera3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	$MeshInstance3D/SubViewport/Control/Label.text = username
	camera = get_viewport().get_camera_3d()
	get_tree().root.get_child(0).connect("scene_changed", _on_scene_changed)

func _on_scene_changed():
	camera = get_viewport().get_camera_3d()

func get_input():
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	if camera:
		var cam_transform = camera.global_transform.basis
		var cam_forward = cam_transform.z
		var cam_right = cam_transform.x

		cam_forward.y = 0
		cam_right.y = 0
		cam_forward = cam_forward.normalized()
		cam_right = cam_right.normalized()

		var direction = (cam_forward * input.y + cam_right * input.x).normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = -input.x * speed
		velocity.z = -input.y * speed

func rotate_toward_mouse():
	if not camera:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)

	var plane = Plane(Vector3.UP, 0.0)
	var intersection = plane.intersects_ray(ray_origin, ray_dir)

	if intersection != null:
		var look_dir = intersection - global_position
		look_dir.y = 0
		if look_dir.length_squared() > 0.001:
			look_at(global_position - look_dir, Vector3.UP)

func _physics_process(delta):
	velocity.y += -gravity * delta
	if SceneManager.control.get_current_player() == self:
		get_input()
		rotate_toward_mouse()
	move_and_slide()
