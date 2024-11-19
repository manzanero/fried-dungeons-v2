class_name Audio
extends AudioStreamPlayer


@export var file_path: String :
	set(value):
		file_path = value
		if not FileAccess.file_exists(file_path):
			return
			
		if file_path.to_lower().ends_with(".ogg"):
			stream = AudioStreamOggVorbis.load_from_file(file_path)
		if file_path.to_lower().ends_with(".mp3"):
			stream = AudioStreamMP3.new()
			var file := FileAccess.open(file_path, FileAccess.READ)
			if not file:
				return
				
			stream.data = file.get_buffer(file.get_length())


var sound_position: float :
	set(value):
		play(sound_position)
	get:
		return get_playback_position()
