# zafto_exam

**Exam Preparation Engine Package**

## Purpose

Shared exam/quiz framework. The ENGINE is shared; the QUESTIONS are trade-specific.

## Status

🔴 **NOT YET EXTRACTED** - Code currently lives in apps/electrical/

## What Will Live Here

```
zafto_exam/
├── lib/
│   ├── models/
│   │   ├── question.dart         # Question model (text, options, answer)
│   │   ├── quiz.dart             # Quiz session (questions, score)
│   │   ├── topic.dart            # Topic/category
│   │   └── progress.dart         # User progress tracking
│   │
│   ├── services/
│   │   ├── question_loader.dart  # Load questions from JSON
│   │   ├── progress_tracker.dart # Track/save progress
│   │   ├── quiz_service.dart     # Quiz session management
│   │   └── scoring_service.dart  # Calculate scores, stats
│   │
│   └── screens/
│       ├── exam_hub_screen.dart       # Topic selection
│       ├── quiz_screen.dart           # Active quiz
│       ├── quiz_results_screen.dart   # Results after quiz
│       ├── progress_dashboard.dart    # Overall progress
│       └── question_explanation.dart  # Detailed explanations
│
├── pubspec.yaml
└── README.md
```

## Architecture

```
zafto_exam (shared engine)
        │
        ▼
┌───────────────────────────────────────────┐
│  Trade-Specific Questions (in each app)   │
├───────────────────────────────────────────┤
│  electrical/assets/exam_prep/questions/   │
│  plumbing/assets/exam_prep/questions/     │
│  hvac/assets/exam_prep/questions/         │
│  spellbook/assets/exam_prep/questions/    │
└───────────────────────────────────────────┘
```

The exam package provides:
- Question/Quiz/Progress models
- Loading service (reads JSON from app's assets)
- Progress tracking (saves to Hive)
- UI screens (themed via zafto_ui)

Each app provides:
- JSON question files in assets/
- Topic configuration
- Trade-specific images/diagrams

## Question Counts by Trade

| Trade | Questions | Source |
|-------|-----------|--------|
| Electrical | 1,200+ | NEC, Journeyman/Master exams |
| Plumbing | TBD | IPC, licensing exams |
| HVAC | TBD | ASHRAE, EPA 608/609 |
| Legal | TBD | Bar exam, specialty certs |

## Current Location

- `apps/electrical/lib/services/exam_prep/`
- `apps/electrical/lib/screens/exam_prep/`
- `apps/electrical/lib/data/exam_prep/`
- `apps/electrical/assets/exam_prep/questions/`
