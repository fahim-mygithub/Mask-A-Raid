extends Node
## RuleSystem autoload - manages active rules and devil evaluation.

## Signal when rules change
signal rules_changed(active_rules: Array)

## Currently active rules for this round
var active_rules: Array = []

## All available rule definitions (id -> metadata)
var all_rules: Dictionary = {}


func _ready() -> void:
	print("[RuleSystem] Initialized")
	_register_default_rules()


func _register_default_rules() -> void:
	## Register built-in visual rules with metadata
	## Only rules that can be implemented with current assets
	all_rules = {
		"striped_pattern": {
			"description": "Devils have STRIPED patterns",
			"difficulty": 1,
			"type": "visual",
		},
		"dotted_pattern": {
			"description": "Devils have DOTTED patterns",
			"difficulty": 1,
			"type": "visual",
		},
		"diamond_pattern": {
			"description": "Devils have DIAMOND patterns",
			"difficulty": 1,
			"type": "visual",
		},
		"triangle_pattern": {
			"description": "Devils have TRIANGLE patterns",
			"difficulty": 1,
			"type": "visual",
		},
		"circle_eyes": {
			"description": "Devils have CIRCLE EYES",
			"difficulty": 2,
			"type": "visual",
		},
		"slit_eyes": {
			"description": "Devils have SLIT EYES",
			"difficulty": 2,
			"type": "visual",
		},
	}
	print("[RuleSystem] Registered ", all_rules.size(), " visual rules")


## Evaluate a single rule against dancer data
## Note: With rule-aware mask generation, devils are assigned masks matching the rule
## This evaluation can be used for verification or behavioral rules
func _evaluate_rule(rule_id: String, dancer_data: Dictionary) -> bool:
	var pattern: String = dancer_data.get("pattern_name", "")

	match rule_id:
		"striped_pattern":
			return pattern.begins_with("Stripe")
		"dotted_pattern":
			return pattern.begins_with("Dot")
		"diamond_pattern":
			return pattern.begins_with("Diamond")
		"triangle_pattern":
			return pattern.begins_with("Triangle") or pattern == "Triangles"
		"circle_eyes":
			return pattern == "CircleEyes"
		"slit_eyes":
			return pattern == "SlitEyes"
		_:
			print("[RuleSystem] Unknown rule: ", rule_id)
			return false


## Get currently active rules
func get_active_rules() -> Array:
	return active_rules


## Get descriptions of active rules for display
func get_rule_descriptions() -> Array[String]:
	var descriptions: Array[String] = []
	for rule_id in active_rules:
		var rule_data: Dictionary = all_rules.get(rule_id, {})
		descriptions.append(rule_data.get("description", "Unknown rule"))
	return descriptions


## Evaluate if a dancer is a devil based on ALL active rules
## Returns true if dancer matches ALL active rule criteria
func is_devil_by_rules(dancer_data: Dictionary) -> bool:
	if active_rules.is_empty():
		print("[RuleSystem] Warning: No active rules, using is_devil flag")
		return dancer_data.get("is_devil", false)

	for rule_id in active_rules:
		if not _evaluate_rule(rule_id, dancer_data):
			return false

	return true


## Select rules for a given level
func select_rules_for_level(level: int) -> void:
	active_rules.clear()

	## Difficulty scaling:
	## Level 1-2: 1 easy rule (difficulty 1)
	## Level 3-5: 1-2 rules (difficulty 1-2)
	## Level 6+: 2-3 rules (difficulty 1-3)

	var max_difficulty: int = 1
	var rule_count: int = 1

	if level >= 6:
		max_difficulty = 3
		rule_count = mini(3, 1 + floori((level - 6) / 2.0))
	elif level >= 3:
		max_difficulty = 2
		rule_count = 1 + floori((level - 3) / 2.0)

	rule_count = mini(rule_count, 3)

	## Filter rules by difficulty
	var available_rules: Array = []
	for rule_id in all_rules.keys():
		var rule_data: Dictionary = all_rules[rule_id]
		if rule_data.get("difficulty", 1) <= max_difficulty:
			available_rules.append(rule_id)

	## Shuffle and select
	available_rules.shuffle()
	for i in range(mini(rule_count, available_rules.size())):
		active_rules.append(available_rules[i])

	print("[RuleSystem] Level ", level, " - Selected ", active_rules.size(), " rules:")
	for rule_id in active_rules:
		var rule_data: Dictionary = all_rules.get(rule_id, {})
		print("[RuleSystem]   - ", rule_data.get("description", "Unknown"))

	rules_changed.emit(active_rules)


## Add a custom rule
func register_rule(rule_id: String, description: String, difficulty: int, rule_type: String) -> void:
	all_rules[rule_id] = {
		"description": description,
		"difficulty": difficulty,
		"type": rule_type,
	}
	print("[RuleSystem] Registered custom rule: ", rule_id)


## Clear all active rules
func clear_rules() -> void:
	active_rules.clear()
	print("[RuleSystem] Cleared active rules")
	rules_changed.emit(active_rules)


## Get a specific rule by ID
func get_rule_by_id(rule_id: String) -> Dictionary:
	return all_rules.get(rule_id, {})


## Force set specific rules (for testing)
func set_rules(rule_ids: Array) -> void:
	active_rules.clear()
	for rule_id in rule_ids:
		if all_rules.has(rule_id):
			active_rules.append(rule_id)
	print("[RuleSystem] Force set rules: ", rule_ids)
	rules_changed.emit(active_rules)
