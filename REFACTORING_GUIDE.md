# Mazad Game - Project Structure Documentation

## Overview
The Mazad (Reverse Auction) game has been refactored from a monolithic 2060-line `main.dart` into a professional, modular architecture for better maintainability and team collaboration.

## Directory Structure

```
lib/
├── main.dart                          # Application entry point (40 lines)
├── firebase_options.dart              # Firebase configuration
├── auth_service.dart                  # (existing)
├── AuthService.dart                   # (existing)
├── globals.dart                       # (existing)
│
├── screens/                           # All UI screens
│   ├── tutorial_screen.dart          # Onboarding/tutorial flow
│   ├── team_names_screen.dart        # Team name input & home screen
│   ├── player_count_screen.dart      # Player count selection
│   ├── player_names_screen.dart      # Player names input
│   ├── final_settings_screen.dart    # Game configuration (fawra, categories)
│   ├── main_game_screen.dart         # Core gameplay (auction, bidding, scoring)
│   ├── random_setup_screen.dart      # Random team setup - step 1
│   ├── random_names_entry_screen.dart # Random team setup - step 2
│   └── show_teams_screen.dart        # Display randomly assigned teams
│
├── utils/                             # Reusable utilities
│   ├── game_audio.dart               # Audio playback management
│   └── party_styles.dart             # Theme colors and styles
│
└── services/                          # External services
    └── firestore_service.dart        # Firebase Firestore operations
```

## File Descriptions

### Core Files

**main.dart** (40 lines)
- Application entry point
- Firebase initialization
- Tutorial state management
- Theme configuration
- Minimal code, maximum readability

### Screens (9 files)

1. **tutorial_screen.dart**
   - PageView-based tutorial with 8 steps
   - Local preferences management
   - Skip and completion logic

2. **team_names_screen.dart**
   - Team name input fields
   - Settings dialog (volume, privacy)
   - Rules/help dialog
   - Navigation to two game modes
   - Exit dialog handling

3. **player_count_screen.dart**
   - Numeric slider for player count
   - Range validation (min 2)
   - Simple, focused responsibility

4. **player_names_screen.dart**
   - Dual team name input (for each player)
   - Controller management
   - Disposal patterns

5. **final_settings_screen.dart**
   - Fawra (win condition) selection
   - Category selection from Firestore
   - "Start Game" button

6. **main_game_screen.dart** (~800 lines)
   - Auction/bidding phase UI
   - Team selection UI
   - Active gameplay UI with timer
   - Score management
   - Deuce (tie-breaker) handling
   - Match history tracking
   - Victory dialog
   - Game menu (back button handling)
   - Settings & rules dialogs within game

7. **random_setup_screen.dart**
   - Total player count selection
   - First step of random assignment

8. **random_names_entry_screen.dart**
   - Player name inputs
   - Random shuffle logic
   - Team assignment

9. **show_teams_screen.dart**
   - Display final random teams
   - Proceed to settings

### Utilities

**game_audio.dart**
- Static audio playback management
- Global volume and mute controls
- Centralized sound effects management

**party_styles.dart**
- Color palette constants
- Theme definitions
- Gradient backgrounds
- Centralized styling

### Services

**firestore_service.dart**
- Firebase batch upload
- Initial data loading
- Isolated Firebase logic

## Benefits of This Structure

1. **Separation of Concerns**
   - Each screen is independent
   - Utilities are reusable
   - Services are isolated

2. **Scalability**
   - Easy to add new screens
   - Simple to extend functionality
   - Clear dependencies

3. **Team Collaboration**
   - Multiple developers can work on different screens
   - Minimal merge conflicts
   - Clear file organization

4. **Maintainability**
   - 40-line main.dart is easy to understand
   - Each file has a single responsibility
   - Easy to locate and modify code

5. **Testing**
   - Individual screens can be tested
   - Utilities can be unit tested
   - Services can be mocked

## Navigation Flow

```
main()
  ↓
MazadApp (checks seen_tutorial)
  ├─→ TutorialScreen (first time)
  │    └─→ TeamNamesScreen
  └─→ TeamNamesScreen (returning user)
       ├─→ PlayerCountScreen (Manual Setup)
       │    └─→ PlayerNamesScreen
       │         └─→ FinalSettingsScreen
       │              └─→ MainGameScreen
       │
       └─→ RandomSetupScreen (Random Setup)
            └─→ RandomNamesEntryScreen
                 └─→ ShowTeamsScreen
                      └─→ FinalSettingsScreen
                           └─→ MainGameScreen
```

## Key Improvements

### Before
- 2060 lines in single file
- Classes mixed with utilities
- Hard to navigate code
- Difficult for team collaboration
- High cognitive load

### After
- Modular structure
- 40-line main.dart
- Clear separation of concerns
- Easy team collaboration
- Each file focused on one purpose
- ~200-400 lines per screen file
- Centralized utilities and themes

## Development Guidelines

### Adding a New Screen
1. Create `lib/screens/new_screen.dart`
2. Implement StatefulWidget or StatelessWidget
3. Import necessary utilities from `utils/`
4. Use `PartyStyles` for theming
5. Use `GameAudio` for sounds
6. Update navigation in parent screen

### Modifying Styles
1. Edit `lib/utils/party_styles.dart`
2. Changes automatically propagate to all screens

### Adding Audio
1. Add sound file to `assets/sounds/`
2. Call `GameAudio.play('sound_name')` from any screen

### Firebase Operations
1. Add methods to `lib/services/firestore_service.dart`
2. Import and use from screens or other services

## Dependencies
- flutter
- firebase_core
- cloud_firestore
- shared_preferences
- audioplayers

## Future Enhancements
- Add state management (Provider/Riverpod/Bloc)
- Implement named routing
- Add more unit/integration tests
- Add analytics
- Implement app-wide error handling
- Add more reusable widgets in a `widgets/` folder

