extends Node

@onready var input : AudioStreamPlayer = $Input
var effect : AudioEffectCapture
var input_threshold = 0.005

var voip_buffers := {}

func _ready():
	setup_audio()

func setup_audio():
	input.stream = AudioStreamMicrophone.new()
	input.play()
	var idx = AudioServer.get_bus_index("Record")
	effect = AudioServer.get_bus_effect(idx, 0)

func _process(delta):
	process_mic()

func process_mic():
	var stereo_buffer = effect.get_buffer(effect.get_frames_available())
	if stereo_buffer.size() == 0:
		return

	var data = PackedFloat32Array()
	data.resize(stereo_buffer.size())
	var max_amp = 0.0

	for i in range(stereo_buffer.size()):
		var value = (stereo_buffer[i].x + stereo_buffer[i].y) * 0.5
		data[i] = value
		max_amp = max(max_amp, abs(value))

	if max_amp < input_threshold:
		return

	rpc("_receive_audio_data", data)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _receive_audio_data(data: PackedFloat32Array):
	var sender_id = multiplayer.get_remote_sender_id()
	if not voip_buffers.has(sender_id):
		voip_buffers[sender_id] = PackedFloat32Array()
	voip_buffers[sender_id].append_array(data)

func consume_audio(peer_id: int, frames: int) -> PackedFloat32Array:
	if not voip_buffers.has(peer_id):
		return PackedFloat32Array()
	var buf = voip_buffers[peer_id]
	var n = min(frames, buf.size())
	var out = buf.slice(0, n)
	voip_buffers[peer_id] = buf.slice(n)
	return out
