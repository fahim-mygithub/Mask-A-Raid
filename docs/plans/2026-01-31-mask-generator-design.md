# Mask Generator Enhancement Design

## Overview

Rule-aware mask generation system where devils are identified by visual clues matching active rules, rather than obvious markers.

## Implementation

### Level 1: Spot the Difference
- 5 dancers total (4 innocents + 1 imposter)
- All dancers share the same mask pattern
- Imposter has a distinct **colored** pattern (RED, BLUE, GREEN, ORANGE, PURPLE, or CYAN)
- Innocents have WHITE patterns
- No rule hints displayed - pure visual identification

### Level 2+: Rule-Based Identification
- Rules determine which pattern category devils use
- Devils match the rule criteria, innocents don't
- Rule card displays the active rule

## Pattern Categories

| Category | Patterns |
|----------|----------|
| Stripes | Stripe1-8 |
| Dots | Dot1-4 |
| Diamonds | Diamond1-4 |
| Triangles | Triangle1-4, Triangles |
| Eyes | CircleEyes, SlitEyes, Cross Eyes |

## Visual Rules

1. `striped_pattern` - Devils have STRIPED patterns
2. `dotted_pattern` - Devils have DOTTED patterns
3. `diamond_pattern` - Devils have DIAMOND patterns
4. `triangle_pattern` - Devils have TRIANGLE patterns
5. `circle_eyes` - Devils have CIRCLE EYES
6. `slit_eyes` - Devils have SLIT EYES

## Files Modified

- `scripts/mask_generator.gd` - Rule-aware generation, pattern categories
- `scripts/autoload/rule_system.gd` - Visual rule definitions
- `scripts/main.gd` - Level 1 logic, dynamic viewport handling
- `resources/mask_data.gd` - Added pattern_color property
- `scenes/dancer.tscn` - Scaled dancer sprites
- `scenes/main.tscn` - Dynamic game area positioning
- `project.godot` - Windowed mode, viewport settings

## Gameplay Flow

```
Level 1:
  - All masks identical pattern
  - Imposter has colored pattern (e.g., RED dots)
  - Innocents have white pattern
  - No rules shown

Level 2+:
  - Rule displayed: "Devils have STRIPED patterns"
  - Devils get stripe patterns
  - Innocents get non-stripe patterns
```
