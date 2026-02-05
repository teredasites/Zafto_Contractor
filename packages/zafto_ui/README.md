# zafto_ui

**Design System v2.6 Package**

## Purpose

Shared UI components, theme system, and screens that ALL ZAFTO apps share.

## Status

🔴 **NOT YET EXTRACTED** - Code currently lives in apps/electrical/

## What Will Live Here

```
zafto_ui/
├── lib/
│   ├── theme/
│   │   ├── zafto_colors.dart       # Token class with semantic colors
│   │   ├── zafto_themes.dart       # 10 theme definitions
│   │   ├── theme_provider.dart     # Riverpod theme state
│   │   └── zafto_theme_builder.dart# ThemeData builder
│   │
│   ├── widgets/
│   │   ├── zafto_card.dart         # Standard card component
│   │   ├── zafto_button.dart       # Button variants
│   │   ├── zafto_text_field.dart   # Input fields
│   │   ├── zafto_bottom_nav.dart   # Bottom navigation
│   │   └── ...                     # Other shared widgets
│   │
│   └── screens/
│       ├── settings/               # Settings screen (theme picker)
│       ├── profile/                # User profile
│       ├── jobs/                   # Job screens (hub, create, detail)
│       ├── invoices/               # Invoice screens
│       └── customers/              # Customer screens
│
├── pubspec.yaml
└── README.md
```

## Design System v2.6 - LOCKED

**DO NOT DEVIATE FROM THESE SPECS**

See: `apps/electrical/Build Documentation/11_DESIGN_SYSTEM.md`

### Themes (10 total)
- Light, Warm, Rosé, Mint
- Dark, Midnight, Nord, Forest
- OLED Black, High Contrast

### Logo
- Signet mark: Z in circle
- Monochromatic (adapts to theme)
- No trade-specific imagery

### Architecture
- Token-based semantic colors
- ZaftoColors class with theme-aware values
- ConsumerStatefulWidget pattern with Riverpod

## When to Extract

Extract when building the SECOND app. Until then, code lives in electrical app but follows these patterns exactly.

## Current Location

- `apps/electrical/lib/theme/`
- `apps/electrical/lib/screens/` (shared screens)
