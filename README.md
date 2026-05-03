# Stillspace

A mental wellness companion app built with Flutter, designed to help users build consistent mindfulness habits through meditation, journaling, and mood tracking.

## Features

### Core Features
- **Guided Meditation Sessions** - 5 to 30 minute sessions with breathing animation
- **Ambient Sounds** - 2.5 Hz binaural beats for focus, brown noise for relaxation
- **Bell Sounds** - Gentle bell at session start and end
- **Mood Tracking** - 5-point emoji-based mood check-in with 2-hour intervals
- **Reflective Journaling** - Guided prompts or free writing with mood tagging
- **Streak System** - Daily consistency tracking with freeze protection

### Extended Features
- **Smart Recommendations** - Context-aware session suggestions based on mood, streak, time of day, and goal proximity
- **Cloud Backup** - Google Sign-In with automatic Firestore sync
- **Data Visualization** - 30-day streak calendar and 7-day mood trend chart
- **Daily Wisdom** - 30 curated practical life insights
- **Notification System** - Daily reminders with follow-ups
- **App Walkthrough** - Interactive tutorial for new users

## Screenshots

| Home | Meditation | Journal | Profile |
|------|------------|---------|---------|
| ![Home](screenshots/home.png) | ![Session](screenshots/session.png) | ![Journal](screenshots/journal.png) | ![Profile](screenshots/profile.png) |

## Tech Stack

- **Framework**: Flutter (Android)
- **State Management**: Provider
- **Local Storage**: Hive (offline-first)
- **Authentication**: Firebase Auth (Google Sign-In)
- **Cloud Database**: Cloud Firestore
- **Notifications**: flutter_local_notifications
- **Charts**: fl_chart
- **Audio**: just_audio

## Architecture

```
lib/
├── core/
│   ├── constants/      # App constants, prompts
│   ├── theme/          # Colors, text styles, theme
│   └── utils/          # Recommendation engine, date utils
├── features/
│   ├── home/           # Main dashboard
│   ├── journal/        # Journal entries
│   ├── mood/           # Mood check-in
│   ├── onboarding/     # First-time setup
│   ├── profile/        # User stats
│   ├── session/        # Meditation timer
│   ├── settings/       # App settings
│   └── walkthrough/    # App tutorial
├── providers/          # State management
│   ├── user_provider.dart
│   ├── mood_provider.dart
│   ├── journal_provider.dart
│   ├── session_provider.dart
│   └── streak_provider.dart
├── services/           # Business logic
│   ├── audio_service.dart
│   ├── firebase_service.dart
│   ├── hive_service.dart
│   └── notification_service.dart
├── widgets/            # Reusable components
└── main.dart
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.11.3+)
- Android Studio / VS Code
- Android device or emulator

### Installation

1. Clone the repository
```bash
git clone https://github.com/harshitpandita/stillspace.git
cd stillspace
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

4. Build release APK
```bash
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

## State Management

The app uses Provider for state management with 5 main providers:

| Provider | Purpose |
|----------|---------|
| UserProvider | User profile, onboarding state, settings |
| MoodProvider | Mood logs, daily averages, check-in logic |
| JournalProvider | Journal entries, CRUD operations |
| SessionProvider | Active session state |
| StreakProvider | Streak tracking, freeze system, completion dates |

All providers follow offline-first approach: write to Hive first, then sync to Firestore.

## Custom Logic: Recommendation Engine

The app includes a rule-based recommendation engine that suggests personalized sessions:

**Priority Order:**
1. Goal proximity (≤3 days left) - Urgent focus session
2. Missed yesterday - Short calming session to restart
3. Low mood (≤2) - Gentle 5-min calming session
4. High mood + strong streak - Longer focus session
5. Evening time - Wind-down session
6. Morning time - Energizing session
7. Default - Standard mindfulness session

## Testing

Run tests:
```bash
flutter test
```

**Test Coverage:**
- 6 widget tests (PrimaryActionButton)
- 11 unit tests (RecommendationEngine)

## License

This project is for educational purposes.

## Author

Harshit Pandita
