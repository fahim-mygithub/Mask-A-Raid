extends Node
## GameManager autoload - handles game state, scoring, and timer.

## Signals
signal round_started
signal timer_tick(time_remaining: float)
signal score_changed(new_score: int)
signal time_penalty_applied(penalty: float, new_time: float)
signal round_won
signal game_over
signal timer_expired

## Game states
enum State { MENU, PLAYING, PAUSED, GAME_OVER }

## Current game state
var current_state: State = State.MENU

## Timer configuration
@export var round_duration: float = 60.0  ## Default round time in seconds
var time_remaining: float = 0.0
var timer_active: bool = false

## Custom cursor textures
var cursor_normal: Texture2D
var cursor_hover: Texture2D
var cursor_hotspot: Vector2 = Vector2(16, 16)  ## Center of 32x32 cursor

## Scoring configuration
const SCORE_CORRECT: int = 100
const SCORE_WRONG: int = -50
var score: int = 0

## Time penalty configuration
@export var time_penalty: float = 5.0  ## Seconds lost on wrong guess

## Level tracking
var current_level: int = 1

## Valid state transitions
const VALID_TRANSITIONS: Dictionary = {
	State.MENU: [State.PLAYING],
	State.PLAYING: [State.PAUSED, State.GAME_OVER],
	State.PAUSED: [State.PLAYING, State.MENU],
	State.GAME_OVER: [State.MENU],
}


func _ready() -> void:
	print("[GameManager] Initialized")
	print("[GameManager] Initial state: ", State.keys()[current_state])
	_load_custom_cursors()


func _load_custom_cursors() -> void:
	cursor_normal = load("res://assets/cursor_asset/Target_Cursor.png")
	cursor_hover = load("res://assets/cursor_asset/Target_Cursor_Outlined.png")

	if cursor_normal:
		## Set hotspot to center of cursor (assuming 32x32 cursor)
		cursor_hotspot = Vector2(cursor_normal.get_width() / 2.0, cursor_normal.get_height() / 2.0)
		Input.set_custom_mouse_cursor(cursor_normal, Input.CURSOR_ARROW, cursor_hotspot)
		print("[GameManager] Custom cursor loaded: ", cursor_normal.get_size())
	else:
		push_warning("[GameManager] Failed to load custom cursor")

	## Connect to scene tree to auto-setup buttons (for future nodes)
	get_tree().node_added.connect(_on_node_added)

	## Scan existing buttons after a frame (scene is loaded)
	await get_tree().process_frame
	_scan_all_buttons()


func _scan_all_buttons() -> void:
	## Find and setup all existing buttons in the scene tree
	var buttons := _find_all_buttons(get_tree().root)
	for button in buttons:
		_setup_button_cursor(button)
	print("[GameManager] Connected cursor to %d buttons" % buttons.size())


func _find_all_buttons(node: Node) -> Array[BaseButton]:
	var buttons: Array[BaseButton] = []
	if node is BaseButton:
		buttons.append(node as BaseButton)
	for child in node.get_children():
		buttons.append_array(_find_all_buttons(child))
	return buttons


func _on_node_added(node: Node) -> void:
	## Auto-connect cursor hover for buttons
	if node is BaseButton:
		_setup_button_cursor(node as BaseButton)


func _setup_button_cursor(button: BaseButton) -> void:
	## Connect mouse enter/exit signals for cursor change
	if not button.mouse_entered.is_connected(_on_button_mouse_entered):
		button.mouse_entered.connect(_on_button_mouse_entered)
	if not button.mouse_exited.is_connected(_on_button_mouse_exited):
		button.mouse_exited.connect(_on_button_mouse_exited)


func _on_button_mouse_entered() -> void:
	set_cursor_hover()


func _on_button_mouse_exited() -> void:
	set_cursor_normal()


## Cursor management
func set_cursor_normal() -> void:
	if cursor_normal:
		Input.set_custom_mouse_cursor(cursor_normal, Input.CURSOR_ARROW, cursor_hotspot)


func set_cursor_hover() -> void:
	if cursor_hover:
		Input.set_custom_mouse_cursor(cursor_hover, Input.CURSOR_ARROW, cursor_hotspot)


func _process(delta: float) -> void:
	if not timer_active or current_state != State.PLAYING:
		return

	time_remaining -= delta
	timer_tick.emit(time_remaining)

	if time_remaining <= 0.0:
		time_remaining = 0.0
		timer_active = false
		print("[GameManager] Timer expired!")
		timer_expired.emit()


## Changes game state with validation and logging
func change_state(new_state: State) -> bool:
	if new_state == current_state:
		print("[GameManager] Already in state: ", State.keys()[new_state])
		return false

	if not _is_valid_transition(new_state):
		print("[GameManager] Invalid transition: ", State.keys()[current_state], " -> ", State.keys()[new_state])
		return false

	var old_state := current_state
	current_state = new_state
	print("[GameManager] State change: ", State.keys()[old_state], " -> ", State.keys()[new_state])
	return true


## Checks if transition to new_state is valid from current state
func _is_valid_transition(new_state: State) -> bool:
	var valid_targets: Array = VALID_TRANSITIONS.get(current_state, [])
	return new_state in valid_targets


## Convenience methods for state changes
func start_game() -> bool:
	print("[GameManager] start_game() called")
	return change_state(State.PLAYING)


func pause_game() -> bool:
	print("[GameManager] pause_game() called")
	return change_state(State.PAUSED)


func resume_game() -> bool:
	print("[GameManager] resume_game() called")
	return change_state(State.PLAYING)


func end_game() -> bool:
	print("[GameManager] end_game() called")
	return change_state(State.GAME_OVER)


func return_to_menu() -> bool:
	print("[GameManager] return_to_menu() called")
	return change_state(State.MENU)


## Returns true if currently in the given state
func is_state(state: State) -> bool:
	return current_state == state


## Signal emission helpers with logging
func emit_round_started() -> void:
	print("[GameManager] Signal: round_started")
	round_started.emit()


func emit_timer_tick(remaining: float) -> void:
	print("[GameManager] Signal: timer_tick(", remaining, ")")
	timer_tick.emit(remaining)


func emit_score_changed(new_score: int) -> void:
	print("[GameManager] Signal: score_changed(", new_score, ")")
	score_changed.emit(new_score)


func emit_time_penalty(penalty: float, new_time: float) -> void:
	print("[GameManager] Signal: time_penalty_applied(", penalty, ", ", new_time, ")")
	time_penalty_applied.emit(penalty, new_time)


func emit_round_won() -> void:
	print("[GameManager] Signal: round_won")
	round_won.emit()


func emit_game_over() -> void:
	print("[GameManager] Signal: game_over")
	game_over.emit()


## Timer control methods
func start_timer(duration: float = -1.0) -> void:
	if duration > 0.0:
		round_duration = duration
	time_remaining = round_duration
	timer_active = true
	print("[GameManager] Timer started: ", round_duration, " seconds")


func stop_timer() -> void:
	timer_active = false
	print("[GameManager] Timer stopped at: ", time_remaining, " seconds remaining")


func reset_timer() -> void:
	time_remaining = round_duration
	timer_active = false
	print("[GameManager] Timer reset to: ", round_duration, " seconds")


func get_timer_progress() -> float:
	## Returns 0.0 to 1.0 representing time elapsed (useful for progress bars)
	if round_duration <= 0.0:
		return 0.0
	return 1.0 - (time_remaining / round_duration)


## Scoring methods
func add_score(amount: int = SCORE_CORRECT) -> void:
	score += amount
	print("[GameManager] Score +", amount, " = ", score)
	score_changed.emit(score)


func subtract_score(amount: int = abs(SCORE_WRONG)) -> void:
	score = max(0, score - amount)
	print("[GameManager] Score -", amount, " = ", score)
	score_changed.emit(score)


func on_correct_guess() -> void:
	add_score(SCORE_CORRECT)
	print("[GameManager] Correct guess!")


func on_wrong_guess() -> void:
	subtract_score(abs(SCORE_WRONG))
	apply_time_penalty()
	print("[GameManager] Wrong guess!")


func reset_score() -> void:
	score = 0
	print("[GameManager] Score reset to 0")
	score_changed.emit(score)


## Time penalty methods
func apply_time_penalty(penalty: float = -1.0) -> void:
	if penalty < 0.0:
		penalty = time_penalty
	time_remaining = max(0.0, time_remaining - penalty)
	print("[GameManager] Time penalty: -", penalty, "s, remaining: ", time_remaining)
	time_penalty_applied.emit(penalty, time_remaining)

	## Check if timer ran out from penalty
	if time_remaining <= 0.0:
		timer_active = false
		print("[GameManager] Timer expired from penalty!")
		timer_expired.emit()


func set_time_penalty(penalty: float) -> void:
	time_penalty = penalty
	print("[GameManager] Time penalty set to: ", penalty, " seconds")


## Game session management
func start_new_game() -> void:
	print("[GameManager] Starting new game...")
	reset_score()
	current_level = 1
	if start_game():
		emit_round_started()


func advance_level() -> void:
	current_level += 1
	print("[GameManager] Advanced to level ", current_level)
	round_won.emit()
