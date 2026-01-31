# Level Progression Design (Levels 1-10)

**Status:** Implemented

## Overview

10-level progression system with pattern-based visual tells, level transitions, and a win screen.

## Level Configuration

| Level | Name | Dancers | Devils | Speed | Patterns | Tell Type |
|-------|------|---------|--------|-------|----------|-----------|
| 1 | Spot the Odd One | 5 | 1 | 0.8x | 1 | Color only |
| 2 | Pattern Recognition | 5 | 1 | 0.85x | 2 | Pattern only |
| 3 | Sharp Eyes | 6 | 1 | 1.0x | 3 | Unique combo |
| 4 | New Patterns | 6 | 1 | 1.0x | 4 | Pattern category |
| 5 | Combination Lock | 7 | 1 | 1.0x | 5 | Any unique attribute |
| 6 | Double Trouble | 8 | 2 | 1.0x | 6 | Shared tell (triangles) |
| 7 | Trust Issues | 8 | 2 | 1.1x | 6 | Color + pattern combo |
| 8 | Growing Crowd | 9 | 2 | 1.1x | 7 | Subtle differences |
| 9 | Triple Threat | 9 | 3 | 1.15x | 8 | First 3-devil level |
| 10 | The Final Dance | 10 | 3 | 1.2x | All | Mixed tells |

## Tell Mechanics Per Level

- **Level 1**: All same pattern, imposter has RED/BLUE/GREEN color
- **Level 2**: All same color (white), imposter has different pattern category
- **Level 3**: Mix of 2-3 colors + 2 patterns, imposter has unique combination
- **Level 4**: Introduce new pattern category, imposter is only one with it
- **Level 5**: Full variety, imposter has ONE attribute no one else has
- **Level 6**: Two devils both share TRIANGLE patterns (rule displayed)
- **Level 7**: Two devils share a color+pattern combo
- **Level 8**: Subtle differences, more visual noise
- **Level 9**: Three devils share a common tell
- **Level 10**: Final challenge with all mechanics

## Transition Flow

```
GAMEPLAY → Round Win
         ↓
┌─────────────────────────────────────┐
│         LEVEL COMPLETE!             │
│      ✓ Devils Found: X/X            │
│      ⏱️ Time Bonus: +XXX            │
│      🎯 Score: +X,XXX               │
│         [CONTINUE]                  │
└─────────────────────────────────────┘
         ↓ (click or 3 sec auto)
┌─────────────────────────────────────┐
│          LEVEL X                    │
│       "Level Name"                  │
│      🎯 Find: X imposters           │
│      👥 Dancers: X                  │
│      💡 Tip text                    │
│         [START]                     │
└─────────────────────────────────────┘
         ↓ (click START)
┌─────────────────────────────────────┐
│           3...2...1...              │
└─────────────────────────────────────┘
         ↓ (3 seconds)
        GAMEPLAY BEGINS
```

## Win Screen (After Level 10)

```
┌─────────────────────────────────────┐
│         🎉 YOU WIN! 🎉              │
│     The tribe is safe!              │
│     All devils unmasked!            │
│     Final Score: XX,XXX             │
│     Levels Completed: 10            │
│      [PLAY AGAIN]  [MENU]           │
└─────────────────────────────────────┘
```

## Files to Create/Modify

### New Files
- `scripts/level_config.gd` - Level data configuration
- `scripts/level_manager.gd` - Handles level state and transitions
- `scenes/level_transition.tscn` - Transition overlay UI
- `scenes/level_intro.tscn` - Level intro UI
- `scenes/you_win.tscn` - Victory screen

### Modified Files
- `scripts/main.gd` - Integrate with LevelManager
- `scripts/mask_generator.gd` - Support pattern variety limits
- `scripts/autoload/game_manager.gd` - Track level progression
