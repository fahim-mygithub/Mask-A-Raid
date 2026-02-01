extends Node
## AudioManager autoload - handles music, SFX, and audio intensity.

## Music intensity levels
enum MusicIntensity { CALM, TENSE }

## Current music state
var current_intensity: MusicIntensity = MusicIntensity.CALM
var music_enabled: bool = true
var sfx_enabled: bool = true

## Volume settings (in dB)
@export var music_volume: float = 0.0
@export var sfx_volume: float = 10.0  ## Boosted for audibility

## Music ducking settings (lower music when SFX plays)
@export var duck_volume: float = -12.0  ## How much to lower music during SFX
@export var duck_duration: float = 0.15  ## Fade down time
@export var duck_recovery: float = 0.5  ## Fade back up time
var duck_tween: Tween

## Audio players (created dynamically)
var music_calm: AudioStreamPlayer
var music_tense: AudioStreamPlayer
var music_menu: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer

## Looping sound players
var fire_loop_player: AudioStreamPlayer
var nervous_loop_player: AudioStreamPlayer

## Crossfade settings
@export var crossfade_duration: float = 1.0
var crossfade_tween: Tween


func _ready() -> void:
	print("[AudioManager] Initialized")
	_create_audio_players()


func _create_audio_players() -> void:
	## Create music players
	music_calm = AudioStreamPlayer.new()
	music_calm.name = "MusicCalm"
	music_calm.bus = "Master"
	add_child(music_calm)

	music_tense = AudioStreamPlayer.new()
	music_tense.name = "MusicTense"
	music_tense.bus = "Master"
	music_tense.volume_db = -80.0  ## Start silent
	add_child(music_tense)

	music_menu = AudioStreamPlayer.new()
	music_menu.name = "MusicMenu"
	music_menu.bus = "Master"
	add_child(music_menu)

	## Create SFX player
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = "Master"
	add_child(sfx_player)

	## Create ambient player
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.bus = "Master"
	add_child(ambient_player)

	## Create fire loop player
	fire_loop_player = AudioStreamPlayer.new()
	fire_loop_player.name = "FireLoopPlayer"
	fire_loop_player.bus = "Master"
	fire_loop_player.volume_db = -6.0  ## Subtle background
	add_child(fire_loop_player)

	## Create nervous loop player
	nervous_loop_player = AudioStreamPlayer.new()
	nervous_loop_player.name = "NervousLoopPlayer"
	nervous_loop_player.bus = "Master"
	nervous_loop_player.volume_db = 0.0
	add_child(nervous_loop_player)

	print("[AudioManager] Audio players created")


## Play a sound effect by name (from res://audio/sfx/)
func play_sfx(sfx_name: String) -> void:
	if not sfx_enabled:
		print("[AudioManager] SFX disabled, skipping: ", sfx_name)
		return

	var sfx_path := "res://audio/sfx/" + sfx_name + ".wav"
	var sfx_stream := load(sfx_path) as AudioStream

	if sfx_stream:
		sfx_player.stream = sfx_stream
		sfx_player.volume_db = sfx_volume
		sfx_player.play()
		print("[AudioManager] Playing SFX: ", sfx_name)
	else:
		print("[AudioManager] SFX not found: ", sfx_path)


## Play a sound effect from a full resource path
func play_sfx_from_path(sfx_path: String, duck_music: bool = true) -> void:
	if not sfx_enabled:
		print("[AudioManager] SFX disabled, skipping: ", sfx_path)
		return

	var sfx_stream := load(sfx_path) as AudioStream

	if sfx_stream:
		if duck_music:
			_duck_music()

		var player := AudioStreamPlayer.new()
		player.stream = sfx_stream
		player.volume_db = sfx_volume
		player.bus = "Master"
		add_child(player)
		player.finished.connect(player.queue_free)
		player.play()
		print("[AudioManager] Playing SFX: ", sfx_path)
	else:
		print("[AudioManager] SFX not found: ", sfx_path)


## Play multiple sound effects simultaneously (layered)
func play_sfx_layered(sound_paths: Array, duck_music: bool = true) -> void:
	if not sfx_enabled:
		print("[AudioManager] SFX disabled, skipping layered sounds")
		return

	if duck_music:
		_duck_music()

	for path in sound_paths:
		var sfx_stream := load(path) as AudioStream
		if sfx_stream:
			var player := AudioStreamPlayer.new()
			player.stream = sfx_stream
			player.volume_db = sfx_volume
			player.bus = "Master"
			add_child(player)
			player.finished.connect(player.queue_free)
			player.play()
			print("[AudioManager] Playing layered SFX: ", path)
		else:
			print("[AudioManager] Layered SFX not found: ", path)


## Duck music volume temporarily when SFX plays
func _duck_music() -> void:
	if not music_enabled:
		return

	## Cancel existing duck tween
	if duck_tween and duck_tween.is_valid():
		duck_tween.kill()

	## Get the active music player
	var active_music: AudioStreamPlayer = null
	if music_menu.playing:
		active_music = music_menu
	elif current_intensity == MusicIntensity.CALM and music_calm.playing:
		active_music = music_calm
	elif current_intensity == MusicIntensity.TENSE and music_tense.playing:
		active_music = music_tense

	if not active_music:
		return

	var original_volume := music_volume
	var ducked_volume := music_volume + duck_volume

	duck_tween = create_tween()
	## Quick duck down
	duck_tween.tween_property(active_music, "volume_db", ducked_volume, duck_duration)
	## Hold briefly
	duck_tween.tween_interval(0.2)
	## Slower recovery back to normal
	duck_tween.tween_property(active_music, "volume_db", original_volume, duck_recovery)


## Set music intensity with crossfade
func set_music_intensity(intensity: MusicIntensity) -> void:
	if intensity == current_intensity:
		return

	print("[AudioManager] Music intensity: ", MusicIntensity.keys()[current_intensity], " -> ", MusicIntensity.keys()[intensity])
	current_intensity = intensity

	if not music_enabled:
		return

	_crossfade_music(intensity)


func _crossfade_music(intensity: MusicIntensity) -> void:
	## Cancel existing crossfade
	if crossfade_tween and crossfade_tween.is_valid():
		crossfade_tween.kill()

	crossfade_tween = create_tween()
	crossfade_tween.set_parallel(true)

	if intensity == MusicIntensity.TENSE:
		## Fade in tense, fade out calm
		crossfade_tween.tween_property(music_tense, "volume_db", music_volume, crossfade_duration)
		crossfade_tween.tween_property(music_calm, "volume_db", -80.0, crossfade_duration)
	else:
		## Fade in calm, fade out tense
		crossfade_tween.tween_property(music_calm, "volume_db", music_volume, crossfade_duration)
		crossfade_tween.tween_property(music_tense, "volume_db", -80.0, crossfade_duration)


## Start playing music
func play_music() -> void:
	if not music_enabled:
		print("[AudioManager] Music disabled")
		return

	## Check for music files and play if they exist
	var calm_path := "res://audio/music/music_calm.ogg"
	var tense_path := "res://audio/music/music_tense.ogg"

	var calm_stream := load(calm_path) as AudioStream
	var tense_stream := load(tense_path) as AudioStream

	if calm_stream:
		music_calm.stream = calm_stream
		music_calm.volume_db = music_volume
		music_calm.play()
		print("[AudioManager] Playing calm music")
	else:
		print("[AudioManager] Calm music not found: ", calm_path)

	if tense_stream:
		music_tense.stream = tense_stream
		music_tense.volume_db = -80.0  ## Start silent
		music_tense.play()
		print("[AudioManager] Tense music loaded (silent)")
	else:
		print("[AudioManager] Tense music not found: ", tense_path)


## Play menu music (main menu theme)
func play_menu_music() -> void:
	if not music_enabled:
		print("[AudioManager] Music disabled")
		return

	## Stop gameplay music if playing
	stop_music()

	var menu_path := "res://assets/title_screen-assets/mainmenutheme-maskaraid.mp3"
	var menu_stream := load(menu_path) as AudioStream

	if menu_stream:
		music_menu.stream = menu_stream
		music_menu.volume_db = music_volume
		music_menu.play()
		print("[AudioManager] Playing menu music")
	else:
		print("[AudioManager] Menu music not found: ", menu_path)


## Stop menu music
func stop_menu_music() -> void:
	music_menu.stop()
	print("[AudioManager] Stopped menu music")


## Play ambient sounds (e.g., fire loop)
func play_ambient(ambient_name: String) -> void:
	var ambient_path := "res://audio/ambient/" + ambient_name + ".ogg"
	var ambient_stream := load(ambient_path) as AudioStream

	if ambient_stream:
		ambient_player.stream = ambient_stream
		ambient_player.play()
		print("[AudioManager] Playing ambient: ", ambient_name)
	else:
		print("[AudioManager] Ambient not found: ", ambient_path)


## Stop all audio
func stop_all() -> void:
	print("[AudioManager] Stopping all audio")
	music_calm.stop()
	music_tense.stop()
	music_menu.stop()
	sfx_player.stop()
	ambient_player.stop()
	fire_loop_player.stop()
	nervous_loop_player.stop()
	nervous_loop_player.stream = null

	if crossfade_tween and crossfade_tween.is_valid():
		crossfade_tween.kill()


## Stop music only
func stop_music() -> void:
	print("[AudioManager] Stopping music")
	music_calm.stop()
	music_tense.stop()


## Toggle music on/off
func toggle_music() -> void:
	music_enabled = not music_enabled
	print("[AudioManager] Music enabled: ", music_enabled)
	if not music_enabled:
		stop_music()


## Toggle SFX on/off
func toggle_sfx() -> void:
	sfx_enabled = not sfx_enabled
	print("[AudioManager] SFX enabled: ", sfx_enabled)


## Set master volume for music
func set_music_volume(volume_db: float) -> void:
	music_volume = volume_db
	music_calm.volume_db = volume_db if current_intensity == MusicIntensity.CALM else -80.0
	music_tense.volume_db = volume_db if current_intensity == MusicIntensity.TENSE else -80.0
	music_menu.volume_db = volume_db
	print("[AudioManager] Music volume set to: ", volume_db, " dB")


## Set master volume for SFX
func set_sfx_volume(volume_db: float) -> void:
	sfx_volume = volume_db
	print("[AudioManager] SFX volume set to: ", volume_db, " dB")


## ============== LOOPING SOUND EFFECTS ==============

## Start fire crackle ambient loop
func start_fire_ambient() -> void:
	if not sfx_enabled:
		return

	var fire_path := "res://assets/sound/misc_effects/firecracklesfx.wav"
	var fire_stream := load(fire_path) as AudioStream

	if fire_stream:
		fire_loop_player.stream = fire_stream
		fire_loop_player.play()
		## Connect to loop when finished
		if not fire_loop_player.finished.is_connected(_on_fire_loop_finished):
			fire_loop_player.finished.connect(_on_fire_loop_finished)
		print("[AudioManager] Fire ambient started")
	else:
		print("[AudioManager] Fire ambient not found: ", fire_path)


func _on_fire_loop_finished() -> void:
	## Restart the loop if still supposed to be playing
	if fire_loop_player.stream:
		fire_loop_player.play()


## Stop fire crackle ambient loop
func stop_fire_ambient() -> void:
	fire_loop_player.stop()
	print("[AudioManager] Fire ambient stopped")


## Start nervous targeting loop
func start_nervous_loop() -> void:
	if not sfx_enabled:
		return

	## Don't restart if already playing
	if nervous_loop_player.playing:
		return

	var nervous_path := "res://assets/sound/misc_effects/nervious.wav"
	var nervous_stream := load(nervous_path) as AudioStream

	if nervous_stream:
		nervous_loop_player.stream = nervous_stream
		nervous_loop_player.play()
		## Connect to loop when finished
		if not nervous_loop_player.finished.is_connected(_on_nervous_loop_finished):
			nervous_loop_player.finished.connect(_on_nervous_loop_finished)
		print("[AudioManager] Nervous loop started")
	else:
		print("[AudioManager] Nervous sound not found: ", nervous_path)


func _on_nervous_loop_finished() -> void:
	## Restart the loop if still supposed to be playing
	if nervous_loop_player.stream:
		nervous_loop_player.play()


## Stop nervous targeting loop
func stop_nervous_loop() -> void:
	nervous_loop_player.stop()
	nervous_loop_player.stream = null  ## Clear stream to prevent auto-restart
	print("[AudioManager] Nervous loop stopped")
