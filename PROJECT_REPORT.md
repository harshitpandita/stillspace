# Stillspace - Project Report

## Mental Wellness Companion App

**Author:** Harshit Pandita  
**Date:** May 2026  
**Platform:** Android (Flutter)

---

## 1. Problem Understanding

### 1.1 Problem Statement
Design a mobile application to promote mental wellness with features like guided meditations, breathing exercises, mood tracking, and journaling prompts. Include goal setting, reminders, and progress celebration using Provider for state management.

### 1.2 Target Users
- Individuals seeking to build a daily mindfulness habit
- Users who want to track their emotional patterns
- People looking for a simple, non-overwhelming wellness app

### 1.3 Core Challenges Addressed
1. **Consistency** - Users often start wellness apps but abandon them. Solution: Streak system with freeze protection and contextual reminders.
2. **Personalization** - Generic recommendations don't engage users. Solution: Rule-based recommendation engine that adapts to mood, time, and progress.
3. **Offline Access** - Meditation should work without internet. Solution: Hive local storage with optional cloud sync.

---

## 2. Feature Justification

### 2.1 Core Features

| Feature | Requirement | Justification |
|---------|-------------|---------------|
| Meditation Timer | Guided meditations | Timer with breathing animation helps users focus; ambient sounds enhance the experience |
| Mood Check-in | Mood tracking | 5-point emoji scale is quick and intuitive; 2-hour cooldown prevents over-tracking |
| Journal | Journaling prompts | Prompted writing reduces blank-page anxiety; mood tagging links emotions to reflections |
| Streak System | Celebrating progress | Gamification increases retention; freeze protects against discouragement from missed days |

### 2.2 Extended Features

| Feature | Justification |
|---------|---------------|
| Recommendation Engine | Personalizes experience based on user state - a user feeling low gets different suggestions than one on a 14-day streak |
| Cloud Backup | Prevents data loss; enables device switching without losing progress |
| Daily Wisdom | Provides value even on days users don't meditate; practical advice over spiritual quotes |
| Walkthrough | Reduces friction for new users; explains features without overwhelming |
| Bell Sounds | Traditional meditation bells signal transitions; helps users enter/exit mindful state |

---

## 3. Architecture

### 3.1 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        UI LAYER                              │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌────────┐│
│  │  Home   │ │ Session │ │ Journal │ │ Profile │ │Settings││
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └───┬────┘│
└───────┼──────────┼──────────┼──────────┼───────────┼───────┘
        │          │          │          │           │
┌───────┴──────────┴──────────┴──────────┴───────────┴───────┐
│                    PROVIDER LAYER                           │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │   User   │ │   Mood   │ │ Journal  │ │  Streak  │       │
│  │ Provider │ │ Provider │ │ Provider │ │ Provider │       │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘       │
└───────┼────────────┼────────────┼────────────┼─────────────┘
        │            │            │            │
┌───────┴────────────┴────────────┴────────────┴─────────────┐
│                    SERVICE LAYER                            │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌────────────┐  │
│  │  Firebase │ │   Hive    │ │   Audio   │ │Notification│  │
│  │  Service  │ │  Service  │ │  Service  │ │  Service   │  │
│  └─────┬─────┘ └─────┬─────┘ └───────────┘ └────────────┘  │
└────────┼─────────────┼─────────────────────────────────────┘
         │             │
    ┌────┴────┐   ┌────┴────┐
    │Firestore│   │  Hive   │
    │ (Cloud) │   │ (Local) │
    └─────────┘   └─────────┘
```

### 3.2 Data Flow
1. User interaction triggers UI event
2. UI calls Provider method
3. Provider updates local state
4. Provider calls Service to persist data
5. Service writes to Hive (immediate)
6. Service syncs to Firestore (background, if signed in)
7. Provider notifies listeners
8. UI rebuilds with new state

---

## 4. State Management

### 4.1 Provider Architecture

The app uses 5 ChangeNotifier providers:

**UserProvider**
- Manages: name, goal days, notification time, onboarding state, walkthrough state
- Persistence: Hive `user_profile` box

**MoodProvider**
- Manages: mood logs list, today's mood, daily averages
- Logic: `shouldShowMoodCheckIn` checks 2-hour rule
- Persistence: Hive `mood_logs` box

**JournalProvider**
- Manages: journal entries list
- Operations: add, get recent entries
- Persistence: Hive `journal_entries` box

**StreakProvider**
- Manages: current streak, longest streak, completed dates, freeze count
- Logic: `incrementStreak()` handles date-based streak calculation
- Persistence: Hive `streak_data` box

**SessionProvider**
- Manages: active session state (used minimally, timer in UI)

### 4.2 Why Provider?
- Simple and lightweight for this app's complexity
- Direct integration with Flutter's widget tree
- Easy to understand and maintain
- Sufficient for the app's state requirements

---

## 5. Custom Logic: Recommendation Engine

### 5.1 Design
The recommendation engine uses a priority-based rule system to suggest personalized meditation sessions.

### 5.2 Input Parameters
- `moodScore`: 1-5 (nullable if not logged today)
- `currentStreak`: consecutive days completed
- `daysLeftToGoal`: days remaining to reach user's goal
- `missedYesterday`: boolean flag

### 5.3 Priority Rules

```
Priority 1: daysLeftToGoal <= 3
  → 10-min focus session
  → "Only X days to go. You're so close!"
  
Priority 2: missedYesterday == true
  → 5-min calming session
  → "Welcome back. A short session can restart your momentum."
  
Priority 3: moodScore <= 2
  → 5-min calming session
  → "Be gentle with yourself."
  
Priority 4: moodScore >= 4 AND streak >= 7
  → 15-min focus session
  → "You're in a great flow. Ready for a deeper session?"
  
Priority 5: Time is evening (20:00+)
  → 10-min wind-down session
  → "End your day with calm."
  
Priority 6: Time is morning (before 10:00)
  → 10-min energizing session
  → "Start your day with intention."
  
Default:
  → 10-min standard session
  → Streak-based message
```

### 5.4 Output
- `sessionDuration`: suggested minutes
- `sessionType`: calming/energizing/focus/windDown/standard
- `promptMessage`: contextual encouragement
- `journalPrompt`: optional journal suggestion
- `urgency`: low/medium/high

---

## 6. Data Visualization

### 6.1 Streak Calendar
- **Type**: 30-day grid
- **Encoding**: Green = completed, Gray = missed, Ice blue outline = freeze used, Border = today
- **Insight**: "Your consistency at a glance"
- **User Value**: Helps users see patterns in their practice and feel accomplishment

### 6.2 Mood Chart
- **Type**: 7-day line chart (fl_chart)
- **X-axis**: Last 7 days
- **Y-axis**: Mood score 1-5
- **Insight**: "Your emotional trend this week"
- **User Value**: Helps users identify emotional patterns and correlate with life events

---

## 7. Challenges Faced

### 7.1 Timer Synchronization
**Problem**: Initial timer implementation used async/await for audio, causing delayed start.
**Solution**: Fire-and-forget pattern for audio; timer starts synchronously.

### 7.2 Notification Crashes in Release
**Problem**: `zonedSchedule` with exact alarms crashed on some Android 12+ devices.
**Solution**: Added try-catch wrappers; test notification uses simple `show()` with `Future.delayed`.

### 7.3 Offline-First Data Sync
**Problem**: Needed data to work offline but sync when online.
**Solution**: Always write to Hive first, then attempt Firestore sync with error handling.

### 7.4 Foreground Day Change
**Problem**: App didn't refresh data when left open past midnight.
**Solution**: Added `WidgetsBindingObserver` to detect app resume and refresh if new day.

---

## 8. AI Usage Disclosure

### 8.1 Tools Used
- **Claude (Anthropic)**: Primary development assistant

### 8.2 AI-Assisted Areas
- Initial project structure and boilerplate
- Provider setup patterns
- Firebase integration code
- Widget implementation
- Bug identification and fixes

### 8.3 Manual Modifications
- **Recommendation engine logic**: Rules designed based on wellness app research
- **UI/UX decisions**: Color scheme, layout hierarchy, interaction patterns
- **Feature prioritization**: Decided which features to include based on DOD requirements
- **Daily wisdom content**: Curated and edited for practical, non-spiritual tone
- **Bug fixes**: Debugged release-specific issues (notifications, timer)
- **Architecture decisions**: Chose Provider over Bloc, Hive over SharedPreferences

### 8.4 Original Contributions
- Streak freeze mechanic (inspired by Duolingo but implemented independently)
- Recommendation priority system
- 2-hour mood check-in cooldown logic
- Context-aware notification messaging

---

## 9. Testing

### 9.1 Automated Tests
- **Widget Tests (6)**: PrimaryActionButton rendering, interaction, states
- **Unit Tests (11)**: RecommendationEngine all priority paths

### 9.2 Manual Test Scenarios

| Scenario | Steps | Expected Result |
|----------|-------|-----------------|
| First launch | Install, open app | Onboarding appears |
| Complete onboarding | Enter name, select goal, set time | Walkthrough appears, then home |
| Meditation flow | Start session, wait for completion | Bell sounds, streak increments |
| Journal entry | Write entry, save | Entry appears in list, streak increments |
| Mood check-in | Log mood, return home | Mood reflected in recommendations |
| Offline usage | Disable internet, use app | All features work, data persists |
| Cloud sync | Sign in, make changes, sign out/in | Data restored from cloud |

---

## 10. Deployment

### 10.1 Build Configuration
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)
- **App Icon**: Custom icon with adaptive foreground
- **Splash Screen**: Dark background with logo

### 10.2 APK Generation
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk` (~96 MB)

---

## 11. Future Improvements

1. **Guided Audio**: Pre-recorded meditation guidance
2. **Insights Page**: Weekly/monthly summaries with actionable insights
3. **Widget**: Home screen widget showing streak
4. **Apple Watch/Wear OS**: Quick meditation start from watch
5. **Social Features**: Optional accountability partners

---

## 12. Conclusion

Stillspace successfully implements all required features for a mental wellness companion while adding meaningful extensions that enhance user engagement. The app demonstrates:

- Clean architecture with clear separation of concerns
- Effective use of Provider for state management
- Custom logic system (recommendation engine) that personalizes the experience
- Data visualization that provides actionable insights
- Comprehensive offline-first data handling
- Professional UI that doesn't look template-generated

The project meets all DOD requirements and provides genuine value to users seeking to build consistent mindfulness habits.
