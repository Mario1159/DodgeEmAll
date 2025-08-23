extends Node

@export var peer_id: int
var playback: AudioStreamGeneratorPlayback

func _ready():
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 44100
	$Output.stream = generator
	$Output.play()
	playback = $Output.get_stream_playback()

func _process(delta):
	if peer_id <= 0:
		return

	var manager = SceneManager.control.get_node("AudioManager")
	var frames = min(playback.get_frames_available(), 256)
	var samples = manager.consume_audio(peer_id, frames)

	for sample in samples:
		playback.push_frame(Vector2(sample, sample))
