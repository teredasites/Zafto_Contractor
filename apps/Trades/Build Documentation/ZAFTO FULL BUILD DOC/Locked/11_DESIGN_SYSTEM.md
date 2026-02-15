# ZAFTO Design System v2.6
## LOCKED - January 28, 2026 - DO NOT DEVIATE

> **Status:** ✅ APPROVED AND LOCKED
> **Philosophy:** Apple-crisp Silicon Valley Toolbox
> **Inspiration:** Linear, Arc Browser, Raycast, Stripe iOS, Apple Settings

---

# 🚨 CRITICAL RULES

1. **READ THIS ENTIRE DOCUMENT** before any UI work
2. **DO NOT DEVIATE** from these specifications
3. **USE EXACT HEX VALUES** - no approximations
4. **FOLLOW TOKEN ARCHITECTURE** - use semantic names, not raw colors
5. **ALL 10 THEMES** must be implemented

---

# LOGO: OFFSET ECHO Z

Type: Monochromatic animated Z mark with depth layers
Construction: Three Z-stroke layers with staggered offset (0,0), (3,3), (6,6)
Front layer: stroke-width 3.5, full opacity, subtle breathing animation
Middle layer: stroke-width 3, opacity 0.18, pulse animation (0.3s delay)
Back layer: stroke-width 3, opacity 0.08, pulse animation (no delay)
Filter: Subtle gaussian glow (stdDeviation 0.4)
Color: currentColor (inherits from parent, theme-aware)
Path: M-22,-22 L22,-22 L-22,22 L22,22 (Z letterform as connected strokes)

DO NOT USE: Signet/circle marks, bolt icon, yellow gradients, trade-specific imagery
RATIONALE: Must work across all verticals (Electrical, Plumbing, HVAC, Finance, Legal)
SOURCE OF TRUTH: web-portal/src/components/logo.tsx

---

# THEME ARCHITECTURE

All components use semantic tokens, NOT raw colors.
Adding a theme = adding ONE object. No code changes elsewhere.


---

# 10 THEME PROFILES

## LIGHT THEMES

### 1. Light (Clean and bright)
```
bg.base:      #F8F8FA
bg.elevated:  #FFFFFF
bg.inset:     #EFEFF4
text.primary:     rgba(0,0,0,0.88)
text.secondary:   rgba(0,0,0,0.60)
text.tertiary:    rgba(0,0,0,0.42)
text.quaternary:  rgba(0,0,0,0.28)
accent.primary:   #1A1A1A
accent.success:   #34C759
```

### 2. Warm (Easy on eyes - sepia/paper)
```
bg.base:      #F5F2EB
bg.elevated:  #FDFCF9
bg.inset:     #EBE7DE
text.primary:     rgba(28,25,23,0.92)
text.secondary:   rgba(28,25,23,0.65)
text.tertiary:    rgba(28,25,23,0.45)
text.quaternary:  rgba(28,25,23,0.30)
accent.primary:   #292524
accent.success:   #65A30D
```

### 3. Rosé (Soft pink tones)
```
bg.base:      #FDF4F5
bg.elevated:  #FFFAFA
bg.inset:     #F9E8EA
text.primary:     rgba(80,20,40,0.90)
text.secondary:   rgba(80,20,40,0.62)
accent.primary:   #9F1239
accent.success:   #059669
```

### 4. Mint (Fresh and calm)
```
bg.base:      #F0FAF6
bg.elevated:  #FAFFFC
bg.inset:     #E0F2EB
text.primary:     rgba(6,78,59,0.90)
text.secondary:   rgba(6,78,59,0.62)
accent.primary:   #047857
accent.success:   #059669
```


## DARK THEMES

### 5. Dark (Classic dark mode - DEFAULT FOR LCD)
```
bg.base:      #0A0A0B
bg.elevated:  #151516
bg.inset:     #050506
text.primary:     rgba(255,255,255,0.94)
text.secondary:   rgba(255,255,255,0.68)
text.tertiary:    rgba(255,255,255,0.48)
text.quaternary:  rgba(255,255,255,0.32)
accent.primary:   #FFFFFF
accent.success:   #32D74B
```

### 6. Midnight (Deep blue tones - VS Code vibes)
```
bg.base:      #0B0D14
bg.elevated:  #12151F
bg.inset:     #060810
text.primary:     rgba(230,235,255,0.94)
text.secondary:   rgba(200,210,235,0.70)
accent.primary:   #E8EDFF
accent.success:   #4ADE80
```

### 7. Nord (Arctic inspired)
```
bg.base:      #2E3440
bg.elevated:  #3B4252
bg.inset:     #272C36
text.primary:     rgba(236,239,244,0.95)
text.secondary:   rgba(216,222,233,0.75)
accent.primary:   #88C0D0
accent.success:   #A3BE8C
```

### 8. Forest (Deep green tones)
```
bg.base:      #0A100D
bg.elevated:  #131A15
bg.inset:     #060A08
text.primary:     rgba(220,252,231,0.94)
text.secondary:   rgba(187,247,208,0.70)
accent.primary:   #6EE7B7
accent.success:   #4ADE80
```


### 9. OLED Black (True black - DEFAULT FOR OLED SCREENS)
```
bg.base:      #000000
bg.elevated:  #0C0C0C
bg.inset:     #000000
text.primary:     rgba(255,255,255,0.94)
text.secondary:   rgba(255,255,255,0.68)
text.tertiary:    rgba(255,255,255,0.48)
text.quaternary:  rgba(255,255,255,0.32)
accent.primary:   #FFFFFF
accent.success:   #30D158
```

## ACCESSIBILITY

### 10. High Contrast (Maximum readability)
```
bg.base:      #000000
bg.elevated:  #000000
text.primary:     #FFFFFF
text.secondary:   #FFFFFF
accent.primary:   #FFFF00
accent.success:   #00FF00
border.default:   rgba(255,255,255,0.50)
```

---

# AUTO-DETECT LOGIC

```
if (OS prefers dark) {
  if (OLED screen detected) → OLED Black
  else → Dark
} else {
  → Light
}
```

User can override with any of the 10 themes in Settings.


---

# TYPOGRAPHY

Font Family: SF Pro Display (iOS), System UI fallback
All sizes in px, convert to Flutter logical pixels

| Level      | Size | Weight    | Use Case                    |
|------------|------|-----------|----------------------------|
| Display    | 20px | Bold 700  | Stats, large numbers       |
| Title      | 17px | Semi 600  | Card titles, section heads |
| Body       | 15px | Medium 500| Primary text, buttons      |
| Body 2     | 14px | Regular 400| Descriptions              |
| Caption    | 13px | Regular 400| Secondary info            |
| Label      | 11px | Semi 600  | Section headers (UPPERCASE)|
| Micro      | 10px | Medium 500| Nav labels, badges         |
| Tiny       | 9px  | Semi 600  | Stat labels (UPPERCASE)    |

Section Headers: 11px, semibold, UPPERCASE, letter-spacing 0.5px, text.tertiary

---

# SPACING SYSTEM

Base unit: 4px
All spacing must be multiples of 4px

| Token | Value | Use Case              |
|-------|-------|----------------------|
| xs    | 4px   | Tight gaps           |
| sm    | 8px   | Icon gaps            |
| md    | 12px  | Card internal padding|
| lg    | 16px  | Section gaps         |
| xl    | 20px  | Major sections       |
| 2xl   | 24px  | Screen padding       |

Screen horizontal padding: 24px (6 units)
Card padding: 16-20px
Card border-radius: 16px (rounded-2xl)
Button border-radius: 9999px (full rounded)


---

# COMPONENTS

## Cards
```
Background:    theme.bg.elevated
Border:        1px solid theme.border.subtle
Border-radius: 16px
Shadow:        Light themes: 0 1px 3px rgba(0,0,0,0.04)
               Dark themes: none
Padding:       16px default, 20px for featured cards
```

## Buttons - Primary
```
Background:    theme.accent.primary
Text color:    Dark themes: #000000 | Light themes: #FFFFFF
Font:          13px semibold
Padding:       10px 16px
Border-radius: 9999px (pill)
```

## Buttons - Secondary
```
Background:    theme.fill.default
Text color:    theme.text.primary
Border:        1px solid theme.border.subtle
```

## Search Bar
```
Height:        48px
Background:    theme.bg.inset
Border:        1px solid theme.border.subtle
Border-radius: 12px
Icon:          18px, text.quaternary
Placeholder:   15px, text.quaternary
```

## Bottom Navigation
```
Background:    theme.meta.navBg (with backdrop blur)
Border-top:    1px solid theme.border.subtle
Icon size:     24px
Label:         10px medium
Active:        theme.accent.primary, strokeWidth 2
Inactive:      theme.text.quaternary, strokeWidth 1.5
```

## List Items (Tools list)
```
Container:     Single card with items separated by borders
Item height:   Auto, padding 16px
Icon box:      40px, rounded-xl, theme.fill.default
Chevron:       20px, theme.text.quaternary
Divider:       1px solid theme.border.subtle
```


---

# UX PATTERNS

## Command Palette Search (⌘K)
- Raycast/Linear style
- Categories: Calculators, NEC Reference, Exam Prep, Actions, Recent
- Everything searchable in 3-4 keystrokes
- Keyboard hints in footer

## Behavioral Contextual Widgets
- NO onboarding questions asking user type
- Observe behavior, show relevant widgets:
  - Exam activity in last 7 days → Show study progress widget
  - Job scheduled today → Show active job widget
- Widgets appear/disappear based on usage patterns

## Navigation
- Same bottom nav for ALL users (no adaptive nav complexity)
- Home | Calc | Jobs | Invoices | More
- Smart widgets handle personalization, not nav structure

## Theme Settings
- Accessible via Settings icon (gear) in header
- Grid picker showing all 10 themes
- "Match System" toggle for auto-detection
- Modal dropdown alternative for quick switching

---

# HOME SCREEN LAYOUT

```
┌─────────────────────────────────────┐
│ [Signet] ZAFTO        [Bell] [Gear] │  Header
│          Electrical                  │
├─────────────────────────────────────┤
│ [🔍 Search                    ⌘K]   │  Search Bar
├─────────────────────────────────────┤
│ ● ACTIVE JOB           Today, 2 PM │  Contextual Widget
│ Panel Upgrade                       │  (if job today)
│ Michael Chen · 1847 Oak Street      │
│ $2,850              [View Job →]    │
├─────────────────────────────────────┤
│ [3 JOBS] [$4.5k REV] [2 PENDING]   │  Stats Row
├─────────────────────────────────────┤
│ QUICK ACCESS                        │  Section Header
│ [Volt] [Wire] [Box] [Conduit]      │  4-up Grid
├─────────────────────────────────────┤
│ AI SCAN                             │
│ Panel Analysis         [Camera]     │  Feature Card
│ Instant identification              │
│ [Open Scanner]    18 scans          │
├─────────────────────────────────────┤
│ TOOLS                               │
│ ┌─────────────────────────────────┐ │
│ │ Calculators · 35 NEC tools    > │ │  Grouped List
│ │ Code Reference · NEC 2023     > │ │
│ │ Exam Prep · 1,200+ questions  > │ │
│ │ Diagrams · 120+ wiring        > │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ RECENT                      See All │
│ ● #12 AWG @ 120V → 2.8% drop       │
│ ● 4" EMT Conduit → 38% fill        │
├─────────────────────────────────────┤
│  🏠    📱    💼    📄    ⚙️       │  Bottom Nav
│ Home  Calc  Jobs Invoice More      │
└─────────────────────────────────────┘
```


---

# CONTRAST REQUIREMENTS (WCAG)

Text opacity levels ensure readability across all themes:

| Level      | Opacity | Use Case                    |
|------------|---------|----------------------------|
| Primary    | 94-95%  | Headlines, titles          |
| Secondary  | 65-70%  | Body text, descriptions    |
| Tertiary   | 45-50%  | Labels, hints              |
| Quaternary | 28-35%  | Disabled, placeholders     |

NEVER go below 28% opacity for any visible text.

---

# ICONS

Library: Lucide React (Flutter equivalent: lucide_icons)
Default size: 18-20px
Stroke width: 1.5 (inactive), 2.0 (active)
Color: Use theme.text tokens, never hardcoded colors

---

# FLUTTER IMPLEMENTATION NOTES

1. Create ThemeData objects for each of the 10 themes
2. Use Provider or Riverpod for theme state management
3. Store user preference in SharedPreferences
4. Implement OLED detection via device_info_plus
5. All colors via Theme.of(context).extension<ZaftoColors>()
6. No hardcoded colors anywhere in widget code

---

# REFERENCE FILES

Primary mockup: zafto-v2.6-full-themes.jsx
Contains: All 10 themes, Settings UI, Theme picker modal, Home screen

Location: Built in Claude artifacts session Jan 28, 2026
Copy to: Project assets folder for dev reference

---

# VERSION HISTORY

- v1.0: Initial yellow bolt design (DEPRECATED)
- v2.0: Monochrome + bolt logo
- v2.1: Refined contrast, removed yellow
- v2.2: Command palette + behavioral widgets
- v2.3: Theme system (Dark/Light/OLED)
- v2.4: Auto-detect + refined light mode
- v2.5: Extended to 5 themes
- v2.6: CURRENT - 10 themes + Settings UI ✅ LOCKED

---

# APPROVAL

Design approved by: Project Owner
Date: January 28, 2026
Status: LOCKED - Ready for Flutter implementation

DO NOT MODIFY without explicit approval.
All new sessions must READ THIS DOCUMENT FIRST.
