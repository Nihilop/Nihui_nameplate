# Nihui NP - Nameplates

**Version:** 1.1
**Author:** nihil (based on rnxmUI)

Enhanced nameplates with visual effects, animations, and extensive customization options.

## Features

### Visual Enhancements

#### Custom Borders
- **Stylish Frames:** Apply custom border textures around nameplate health bars
- **Configurable:**
  - Texture path
  - Color and alpha
  - Edge size
  - Offset from health bar
  - Blend mode

#### Glass Overlay
- **Depth Effect:** Semi-transparent glass texture overlay on health bars
- **Customizable:**
  - Texture path
  - Alpha transparency
  - Blend mode
- **Professional Look:** Adds visual polish to nameplates

#### Target Highlighting
- **Bright Indicator:** Clear visual marker for your current target
- **Options:**
  - Custom highlight color (default: yellow)
  - Additive blend mode for extra brightness
  - Remove Blizzard default highlight
  - Optional pulse animation

#### Custom Statusbar Texture
- **Modern Appearance:** Replace default health bar texture
- **Smooth Gradient:** Clean, professional look
- **Consistent Style:** Match other Nihui addons

### Health Loss Animations
- **Smooth Transitions:** Animated health decrease effect
- **Performance Optimized:**
  - Distance-based rendering (default: 60 yards)
  - Maximum concurrent animations limit (default: 10)
  - Efficient texture reuse
- **Selective Filtering:**
  - Enable for player
  - Enable for friendly units
  - Enable for enemy units
  - Enable for neutral units
  - Combat-only mode option

### Cast Bar Enhancement
- **Optional Nameplate Castbars:** Show enemy cast bars on nameplates
- **Features:**
  - Spell icon display
  - Spell name text
  - Cast timer countdown
  - Interrupt detection
- **Selective Display:**
  - Enable for player (typically disabled)
  - Enable for friendly units
  - Enable for enemy units (recommended)
  - Enable for neutral units
- **Positioning:** Adjustable Y offset from nameplate
- **Hide Blizzard Default:** Option to disable Blizzard's castbar

### Scaling System (Optional)
- **Dynamic Sizing:** Make target nameplate larger
- **Settings:**
  - Normal width/height scale (1.0 = 100%)
  - Target width/height scale (e.g., 1.2 = 120%)

## Installation

1. Extract the `Nihui_np` folder to:
   ```
   World of Warcraft\_retail_\Interface\AddOns\
   ```
2. Restart World of Warcraft or type `/reload`

## Configuration

Open the settings GUI:
```
/nihuinp
```

### Quick Setup

1. Type `/nihuinp` to open the configuration panel
2. Enable desired visual effects (borders, glass, animations)
3. Configure health loss animation filters (player, friendly, enemy, neutral)
4. Adjust target highlighting preferences
5. Enable/disable cast bars as needed
6. Changes apply immediately

### Recommended Settings

**For PvP:**
- Health Loss Animations: Enabled for enemy units only
- Combat Only: Enabled
- Target Highlighting: Bright yellow with additive mode
- Cast Bars: Enabled for enemy units

**For PvE:**
- Health Loss Animations: Enabled for all units
- Combat Only: Disabled
- Max Distance: 60 yards
- Cast Bars: Enabled for enemy and neutral units

**For Performance:**
- Max Concurrent Animations: 5-8
- Max Distance: 40 yards
- Combat Only: Enabled
- Scaling: Disabled

### Health Loss Animation Settings

- **Enabled:** Master toggle for health loss animations
- **Max Distance:** Units beyond this range won't show animations (30-80 yards recommended)
- **Max Concurrent:** Limit simultaneous animations (5-15 recommended)
- **Combat Only:** Only show animations during combat
- **Enable for Player:** Show on player's nameplate
- **Enable for Friendly Units:** Show on party/raid members
- **Enable for Enemy Units:** Show on hostile targets
- **Enable for Neutral Units:** Show on neutral NPCs

### Border Settings

- **Enabled:** Show custom borders
- **Texture:** Path to border texture file
- **Color:** RGBA color values
- **Edge Size:** Border thickness in pixels
- **Offset:** Distance from health bar edge
- **Blend Mode:** `BLEND` or `ADD`

### Glass Overlay Settings

- **Enabled:** Show glass effect
- **Texture:** Path to glass texture file
- **Alpha:** Transparency (0.0 = invisible, 1.0 = opaque)
- **Blend Mode:** `BLEND` or `ADD`

### Target Highlight Settings

- **Enabled:** Highlight current target
- **Color:** RGBA highlight color
- **Use Additive:** Brighter highlight with additive blending
- **Remove Default:** Hide Blizzard's default highlight
- **Enable Pulse:** Animated pulse effect (may impact performance)

### Cast Bar Settings

- **Enabled:** Master toggle for nameplate castbars
- **Y Offset:** Vertical position from nameplate (pixels)
- **Hide Blizzard Castbar:** Remove default UI castbar
- **Enable for Player/Friendly/Enemy/Neutral:** Selective display
- **Show Icon:** Display spell icon
- **Show Text:** Display spell name
- **Show Timer:** Display cast time

### Scaling Settings (Optional)

- **Enabled:** Enable dynamic scaling for target
- **Normal Width/Height:** Scale for non-targeted nameplates (1.0 = normal)
- **Target Width/Height:** Scale for your current target (1.2 = 20% larger)

### Reset to Defaults

Return to default configuration:
```
/nihuinp reset
```

## Compatibility

- **Game Version:** Retail (The War Within - 11.0.2+)
- **Conflicts:** Disable other nameplate addons (Plater, KUI Nameplates, TidyPlates)
- **CVars:** May modify some nameplate CVars for optimal appearance

## Performance

- **Efficient Rendering:** Distance-based culling for animations
- **Concurrent Limit:** Prevents FPS drops in large battles
- **Smart Updates:** Only update visible nameplates
- **Texture Pooling:** Reuse animation textures efficiently

## Saved Variables

Settings stored per character:
```
WTF\Account\<ACCOUNT>\<SERVER>\<CHARACTER>\SavedVariables\NihuiNameplatesDB.lua
```

## Troubleshooting

**Q: Nameplates look different than before**
A: Type `/nihuinp reset` to restore defaults, then customize from there

**Q: Health loss animations not showing**
A: Check that animations are enabled and the unit type filter is enabled (enemy, friendly, etc.)

**Q: FPS drops with many nameplates**
A: Lower "Max Concurrent Animations" and reduce "Max Distance"

**Q: Borders not visible**
A: Ensure borders are enabled and check the texture path is correct

**Q: Target highlight not showing**
A: Enable target highlighting and make sure "Remove Default" is enabled

**Q: Cast bars appearing twice**
A: Enable "Hide Blizzard Castbar" option to remove the default UI castbar

**Q: Glass effect too strong/weak**
A: Adjust the alpha value (lower = more transparent)

## Commands

- `/nihuinp` - Open settings GUI
- `/nihuinp reset` - Reset to default settings
- `/reload` - Reload UI after major changes

## Tips

1. **Combat Performance:** Enable "Combat Only" to reduce overhead out of combat
2. **Visual Clarity:** Use bright target highlighting in raids to easily spot your target
3. **Cast Tracking:** Enable enemy castbars to track interrupt opportunities
4. **Distance Tuning:** Adjust max distance based on your typical engagement range
5. **Color Coordination:** Match border colors to your UI theme

## Technical Details

### Animation System
- Texture: Overlays on health bar during damage
- Smoothing: Framerate-independent animation
- Pooling: Efficient memory usage
- Culling: Distance and visibility checks

### Event Handling
- `NAME_PLATE_UNIT_ADDED` - Initialize new nameplates
- `NAME_PLATE_UNIT_REMOVED` - Cleanup removed nameplates
- `UNIT_HEALTH` - Trigger health loss animations
- `PLAYER_TARGET_CHANGED` - Update target highlighting

## Credits

**Author:** nihil
**Based on:** rnxmUI nameplate system

Part of the **Nihui UI Suite**

---

*Beautiful nameplates, exceptional clarity*
