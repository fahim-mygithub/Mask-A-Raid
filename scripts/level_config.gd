extends RefCounted
class_name LevelConfig
## Static level configuration data for all 10 levels.

const LEVELS: Array[Dictionary] = [
	{}, # Index 0 unused (levels start at 1)
	# Level 1: Spot the Odd One
	{
		"name": "Spot the Odd One",
		"dancers": 5,
		"devils": 1,
		"speed": 0.8,
		"pattern_count": 1,
		"tell_type": "color",
		"tip": "One mask has a different COLOR!",
		"show_rule": false,
	},
	# Level 2: Pattern Recognition
	{
		"name": "Pattern Recognition",
		"dancers": 5,
		"devils": 1,
		"speed": 0.85,
		"pattern_count": 2,
		"tell_type": "pattern",
		"tip": "Look for a different PATTERN!",
		"show_rule": false,
	},
	# Level 3: Sharp Eyes
	{
		"name": "Sharp Eyes",
		"dancers": 6,
		"devils": 1,
		"speed": 1.0,
		"pattern_count": 3,
		"tell_type": "combo",
		"tip": "Find the UNIQUE combination!",
		"show_rule": false,
	},
	# Level 4: New Patterns
	{
		"name": "New Patterns",
		"dancers": 6,
		"devils": 1,
		"speed": 1.0,
		"pattern_count": 4,
		"tell_type": "category",
		"tip": "One uses a different pattern type!",
		"show_rule": false,
	},
	# Level 5: Combination Lock
	{
		"name": "Combination Lock",
		"dancers": 7,
		"devils": 1,
		"speed": 1.0,
		"pattern_count": 5,
		"tell_type": "unique",
		"tip": "Find the ONE unique attribute!",
		"show_rule": false,
	},
	# Level 6: Double Trouble
	{
		"name": "Double Trouble",
		"dancers": 8,
		"devils": 2,
		"speed": 1.0,
		"pattern_count": 6,
		"tell_type": "shared_triangles",
		"tip": "Both devils have TRIANGLE patterns!",
		"show_rule": true,
		"rule_text": "Devils have TRIANGLE patterns",
	},
	# Level 7: Trust Issues
	{
		"name": "Trust Issues",
		"dancers": 8,
		"devils": 2,
		"speed": 1.1,
		"pattern_count": 6,
		"tell_type": "shared_combo",
		"tip": "Devils share a color AND pattern!",
		"show_rule": true,
		"rule_text": "Devils share the same style",
	},
	# Level 8: Growing Crowd
	{
		"name": "Growing Crowd",
		"dancers": 9,
		"devils": 2,
		"speed": 1.1,
		"pattern_count": 7,
		"tell_type": "subtle",
		"tip": "Differences are getting subtle...",
		"show_rule": false,
	},
	# Level 9: Triple Threat
	{
		"name": "Triple Threat",
		"dancers": 9,
		"devils": 3,
		"speed": 1.15,
		"pattern_count": 8,
		"tell_type": "shared_color",
		"tip": "THREE devils with the same COLOR!",
		"show_rule": true,
		"rule_text": "Devils share the same COLOR",
	},
	# Level 10: The Final Dance
	{
		"name": "The Final Dance",
		"dancers": 10,
		"devils": 3,
		"speed": 1.2,
		"pattern_count": 24,
		"tell_type": "mixed",
		"tip": "Use everything you've learned!",
		"show_rule": true,
		"rule_text": "Devils have STRIPE patterns",
	},
]

const MAX_LEVEL: int = 10


static func get_level(level_num: int) -> Dictionary:
	if level_num < 1 or level_num > MAX_LEVEL:
		push_error("[LevelConfig] Invalid level: %d" % level_num)
		return LEVELS[1]
	return LEVELS[level_num]


static func get_level_name(level_num: int) -> String:
	return get_level(level_num).get("name", "Unknown")


static func is_final_level(level_num: int) -> bool:
	return level_num >= MAX_LEVEL
