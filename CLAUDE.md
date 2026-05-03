# Stillspace — Flutter Mental Wellness App

CRITICAL RULE — add this to your memory permanently:

Never write, edit, or touch any file outside of C:/stillspace/
All app code lives under C:/stillspace/lib/ only.
If you ever need to create a file, verify the full path starts with C:/stillspace/
Flutter SDK at C:/flutter/ is read-only — never modify anything there.
Before creating any file, print the full absolute path and confirm it is inside C:/stillspace/
## Project Overview
A dark-themed mental wellness app focused on daily consistency through meditation and journaling. Inspired by Medito (calm), Let's Meditate (simple UI), Duolingo (streak/gamification), and Gratitude (journaling).

## CRITICAL PATH RULE
NEVER write to any path outside C:/stillspace/
All files must be under C:/stillspace/lib/
C:/flutter/ is READ-ONLY — never modify SDK files
Always verify absolute path before creating any file

## Tech Stack
- **Framework**: Flutter (Android target)
- **State Management**: Provider
- **Local Storage**: Hive + hive_flutter (offline-first, primary)
- **Auth**: Firebase Auth — Google Sign-In
- **Cloud**: Cloud Firestore (backup + sync)
- **Notifications**: flutter_local_notifications
- **Charts**: fl_chart
- **Audio**: just_audio (local assets: 2.5 Hz binaural, brown noise, bell)

## Design System
- **Theme**: Dark ONLY — no light mode
- **Background**: #0D0D0D (near-black)
- **Surface/Cards**: #1A1A1A
- **Primary Accent**: #A8F0C6 (icy green)
- **Secondary Accent**: #6DD5A8
- **Error**: #FF6B6B
- **Text Primary**: #F5F5F5
- **Text Secondary**: #8A8A8A
- **Feel**: Medito calm + Duolingo gamified energy + Stoic minimal
- **No gradients, no heavy shadows — flat and clean**

## Folder Structure
lib/
core/
theme/
app_colors.dart
app_text_styles.dart
app_theme.dart
constants/
app_constants.dart
utils/
date_utils.dart
recommendation_engine.dart
features/
onboarding/
screens/
onboarding_screen.dart
home/
screens/
home_screen.dart
mood/
screens/
mood_checkin_screen.dart
models/
mood_log.dart
session/
screens/
session_screen.dart
meditate_screen.dart
models/
session_model.dart
journal/
screens/
journal_screen.dart
journal_entry_screen.dart
models/
journal_entry.dart
profile/
screens/
profile_screen.dart
stats/
widgets/
streak_calendar.dart
mood_chart.dart
providers/
mood_provider.dart
session_provider.dart
streak_provider.dart
user_provider.dart
services/
firebase_service.dart
notification_service.dart
hive_service.dart
audio_service.dart
widgets/
mood_selector_widget.dart
primary_action_button.dart
session_card.dart
main.dart

## Navigation
- Bottom nav bar: **Home**, **Journal**, **Profile**
- Onboarding shown once on first launch (4 steps, Duolingo-style full screen each):
  - Step 1: Enter name
  - Step 2: Choose goal (7, 14, 21, or 30 days) — tap to select card
  - Step 3: Set notification reminder time
  - Step 4: Welcome/done screen with CTA
- Mood check-in: full screen pushed with animated transition
  - Triggered if: no check-in today OR 2+ hours since last log
- Session screen: pushed from Home

## Data Models

### MoodLog
```dart
id: String
userId: String
score: int // 1-5
timestamp: DateTime
note: String? // optional
```

### JournalEntry
```dart
id: String
userId: String
prompt: String
content: String
moodScore: int
timestamp: DateTime
```

### StreakData
```dart
userId: String
currentStreak: int
longestStreak: int
lastCompletedDate: DateTime?
freezesUsedThisWeek: int
lastFreezeDate: DateTime?
goalDays: int
goalStartDate: DateTime
```

### UserProfile
```dart
uid: String
name: String
goalDays: int
notificationTime: String // "HH:mm"
createdAt: DateTime
```

## Hive Boxes
- `mood_logs`
- `journal_entries`
- `streak_data`
- `user_profile`

## Firebase Collections
- `users/{uid}/mood_logs`
- `users/{uid}/journal_entries`
- `users/{uid}/streak_data`

## Core Logic Rules

### Streak System (StreakProvider)
- Streak +1 ONLY when: session completed OR journal entry saved
- Mood logging does NOT affect streak
- Track: currentStreak, longestStreak, lastCompletedDate
- Freeze system: 1 freeze available per week
  - If missed day + freeze available → streak continues, show "Freeze used" toast, decrement freeze
  - If missed day + no freeze → streak resets to 0
- Check streak status on every app open

### Mood System (MoodProvider)
- Trigger check-in if: no log today OR last log was 2+ hours ago
- 5 mood states (1=very low, 5=very high), emoji-based UI
- Save to Hive immediately, attempt Firestore sync if online

### Recommendation Engine (core/utils/recommendation_engine.dart)
Inputs: moodScore, currentStreak, timeOfDay, daysLeftToGoal, missedYesterday

Rules (in priority order):
1. daysLeftToGoal <= 3 → "You're so close! Don't break now." + urgent session suggestion
2. missedYesterday == true → urgent nudge copy + short session suggestion
3. moodScore <= 2 → suggest 5-min calming session + gentle journal prompt
4. moodScore >= 4 && currentStreak >= 7 → suggest 10-15 min session
5. timeOfDay == evening (after 20:00) → wind-down prompt
6. timeOfDay == morning (before 10:00) → energising prompt
7. default → standard 10-min session suggestion

Output: { sessionDuration, sessionType, promptMessage, notificationUrgency }

### Notification System (NotificationService)
- 1 main reminder at user-set time daily
- Follow-up 1: +2 hours after main if not completed
- Follow-up 2: +4 hours after main if still not completed
- Notification copy tone scales with: streak risk, goal proximity, missedYesterday flag
- Cancel all follow-ups once session or journal is completed for the day

## State Providers

### UserProvider
- Holds: UserProfile, isOnboardingComplete
- Persists to Hive box `user_profile`
- Syncs to Firestore `users/{uid}`

### MoodProvider
- Holds: List<MoodLog>, lastLogTime, todaysMood
- shouldShowMoodCheckIn getter (checks 2hr rule)
- Persists to Hive box `mood_logs`
- Syncs to Firestore

### SessionProvider
- Holds: isSessionActive, selectedDuration, elapsedSeconds, isComplete
- Timer logic lives here — NOT in UI
- On complete: notifies StreakProvider

### StreakProvider
- Holds: StreakData
- checkAndUpdateStreak() called on app open
- applyFreeze() method
- Persists to Hive, syncs to Firestore

## Custom Widgets (Reusable — not one-off)
1. **MoodSelectorWidget** — 5 emoji options, animated scale on selection, returns int score
2. **PrimaryActionButton** — branded icy-green CTA, takes label + onPressed, used app-wide
3. **SessionCard** — shows session type, duration chip, start button, used on Home

## Data Visualization (Profile Screen)
1. **Streak Calendar** — 30-day horizontal grid
   - Green filled = completed day
   - Grey = missed day
   - Ice blue outline = freeze used
   - Today = highlighted border
   - Insight label: "Your consistency at a glance"
2. **Mood Chart** — 7-day line chart (fl_chart)
   - X axis: last 7 days
   - Y axis: mood score 1-5
   - Icy green line, dot per day
   - Insight label: "Your emotional trend this week"

## DOD Compliance Checklist
- [x] Custom theme (colors, typography) — not default Flutter
- [x] 3 custom reusable widgets (MoodSelectorWidget, PrimaryActionButton, SessionCard)
- [x] Responsive layout
- [x] 2+ micro-interactions (breathing animation, screen transitions, bell sounds)
- [x] Provider architecture — clean separation UI/logic/data
- [x] No setState misuse
- [x] Firebase Auth + Firestore integrated
- [x] Structured data models
- [x] Offline handling via Hive
- [x] Custom logic system (recommendation engine)
- [x] Data visualization with insight labels
- [x] 2 widget tests minimum (17 tests)
- [x] Edge cases: empty states, no internet, invalid input, first-time user
- [x] APK build
- [x] App icon + splash screen

## Coding Rules (ALWAYS follow)
- All logic in providers — UI only calls provider methods and listens to state
- No unnecessary setState — use Consumer or context.watch
- Every file gets a top comment explaining its purpose
- Meaningful commit messages (e.g. "implement streak freeze logic" not "update")
- Handle null safety properly — no ! unless absolutely certain
- Every screen handles its empty state
- Offline first: always write to Hive first, then attempt Firebase sync
- Clean folder structure — never dump files in lib/ root except main.dart

## Current Build Status
- [x] Foundation (theme, main.dart, folder structure)
- [x] Firebase initialization working
- [x] Onboarding flow (4 steps complete)
- [x] MainScreen with bottom nav (Home, Journal, Profile)
- [x] PrimaryActionButton widget
- [x] SessionCard widget
- [x] Home screen (greeting, streak card, mood prompt, session cards)
- [x] Mood check-in screen (5 emoji selector, saves to provider)
- [x] Session screen (timer with breathing animation, streak increment)
- [x] Journal screen (list view, empty state, entry cards)
- [x] Journal entry screen (prompt selector, content input, mood tag, saves + streak)
- [x] JournalProvider (Hive persistence)
- [x] Profile screen (user header, stats row, goal progress)
- [x] StreakCalendar widget (30-day grid with completion status)
- [x] MoodChart widget (7-day line chart using fl_chart)
- [x] StreakProvider updated (Hive persistence, completed dates tracking)
- [x] MoodProvider updated (Hive persistence, daily averages for chart)
- [x] Notification system (daily reminders, follow-ups, context-aware messages)
- [x] Settings screen (notification toggle, reminder time, goal edit, about)
- [x] Firebase Auth + Firestore sync (Google Sign-In, auto-sync on data change)
- [x] Recommendation engine (context-aware session suggestions on Home)
- [x] Testing (17 tests: PrimaryActionButton widget + RecommendationEngine unit)
- [x] Audio service (local assets: 2.5 Hz focus, brown noise, bell sound)
- [x] MeditateScreen (session selection: duration + ambient sound)
- [x] Home screen redesign (recommended session, custom session, daily wisdom, journey path)
- [x] Bell sound at session start (1.5s delay) and end
- [x] Foreground day refresh (quotes/calendar update on new day)
- [x] Streak explanation modal (how streaks work)
- [x] Polish + APK (app-release.apk built)

## Testing Onboarding
To reset and test onboarding again, uncomment the Hive clear lines in main.dart (around line 48-52)

## Firebase Configuration
- Firebase initialized with explicit FirebaseOptions in main.dart (NOT from google-services.json resource)
- DO NOT change Firebase initialization back to Firebase.initializeApp() without options
- google-services.json is in android/app/ but we use explicit options due to resource loading issues

## Git Rules (STRICT — never violate)
- NEVER run any git commands automatically
- NEVER push, commit, add, or init git on your own
- When a logical checkpoint is reached (feature complete, foundation done, etc), STOP and tell me:
  "📌 Git checkpoint: [what was just built]. Run these commands when ready:"
  Then show the exact commands to run, like:
git add .
git commit -m "meaningful message here"
- I will run all git commands myself manually
- Never suggest `git push` unless I explicitly ask about pushing to remote
