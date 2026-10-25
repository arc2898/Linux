# EVERLUMEN design system

## Intent
Soft alien bioluminescence: organic petal forms, orbital geometry, dark atmospheric surfaces, and calm luminous accents. Avoid conventional hard-edged cyberpunk styling.

## Tokens
| Token | Value | Purpose |
|---|---|---|
| Abyss | `#0b1020` | Primary background |
| Night glass | `#151c2e` | Raised surfaces |
| Cloud text | `#e8f4f4` | Primary text |
| Orbit mint | `#8fffd8` | Active/focus |
| Lunar lilac | `#c6a7ff` | Secondary accent |
| Petal pink | `#ffb6d9` | Warm accent |
| Quiet slate | `#9aabc1` | Secondary text |

## Shape and motion
- Rounded panel corners: approximately 16–28 px depending on component.
- Thin, translucent borders communicate active state without harsh contrast.
- Favor eased, short transitions; avoid constant high-frequency animation.
- Blur and transparency are optional and should be reduced on low-power GPUs.

## Accessibility
Keep text contrast readable, do not use color as the only status signal, and allow users to disable blur/glow. Keep focus indicators visible.
