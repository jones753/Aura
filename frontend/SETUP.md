# Personal Mentor App - Setup Guide

## Quick Start

### 1. Start the Backend
```bash
cd d:\Work\ProjectX\backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python app.py
```
The backend will run at `http://localhost:5000`

### 2. Run the Flutter Frontend
```bash
cd d:\Work\ProjectX\frontend
flutter pub get
flutter run
```

## What Was Created

### Frontend Structure
```
lib/
├── main.dart                    # App entry point & routing
├── services/                    # Business logic & API calls
│   ├── auth_service.dart       # Authentication, login, register
│   ├── api_service.dart        # Generic HTTP client
│   ├── routine_service.dart    # Routine CRUD operations
│   ├── daily_log_service.dart  # Daily log management
│   └── feedback_service.dart   # AI feedback retrieval
└── screens/                     # UI pages
    ├── auth/
    │   ├── login_screen.dart   # User login
    │   └── register_screen.dart # User registration
    └── home/
        ├── home_screen.dart     # Dashboard with navigation
        ├── routines_screen.dart # Manage routines
        ├── daily_log_screen.dart # Log daily activities
        └── profile_screen.dart  # User profile & settings
```

## Key Features Implemented

### Authentication
- ✅ User registration with mentor preferences
- ✅ Login with secure token storage
- ✅ JWT token validation
- ✅ Logout functionality

### Routines
- ✅ Create, read, update, delete routines
- ✅ Set difficulty, priority, duration
- ✅ Categorize routines
- ✅ Set frequency (daily, weekly, custom)

### Daily Logs
- ✅ Create daily logs with mood/energy/stress metrics
- ✅ Track routine completion
- ✅ Add notes, highlights, challenges
- ✅ View detailed log history

### Feedback
- ✅ Generate AI feedback for daily logs
- ✅ View compliance rates
- ✅ Get personalized suggestions

### Profile
- ✅ View user profile
- ✅ Edit profile information
- ✅ Manage mentor preferences (style & intensity)
- ✅ Update goals and bio

## Design Highlights

### Material Design 3
- Modern, responsive UI
- Light & Dark theme support
- Smooth animations
- Intuitive navigation

### User Experience
- Pull-to-refresh on all list screens
- Real-time error messages
- Loading indicators
- Smooth navigation between screens
- Form validation

### Data Flow
Services → API Calls → Backend → Database

## Testing the App

### Login Credentials
1. First, register a new user
2. Then login with those credentials

### Sample Workflow
1. **Login** with your credentials
2. **Create Routines** (e.g., "Morning Exercise", "Read", "Meditate")
3. **Create Daily Log** with mood/energy/stress
4. **Log Routine Entries** (mark them as completed/partial/skipped)
5. **Generate Feedback** - Get AI mentor's response
6. **View Profile** - Adjust mentor style and intensity
7. **Check Dashboard** - See your stats and recent logs

## Environment Configuration

If backend is not on localhost:5000, update:
1. `lib/services/auth_service.dart` - Line with `baseUrl`
2. `lib/services/api_service.dart` - Line with `baseUrl`

Change:
```dart
static const String baseUrl = 'http://localhost:5000/api';
```

To your backend URL.

## Dependencies Added

```yaml
dependencies:
  http: ^1.1.0              # HTTP requests
  flutter_secure_storage: ^9.0.0  # Token storage
```

## Troubleshooting

### App won't run
- Check Flutter is installed: `flutter doctor`
- Run `flutter pub get`
- Check emulator/device is running

### Can't connect to backend
- Ensure backend is running on port 5000
- Check `baseUrl` in services
- Verify no firewall blocking localhost

### Token errors
- Token might be expired, try logging in again
- Clear app data in settings

## Next Steps

To further enhance the app, consider:
1. Add push notifications
2. Implement offline support
3. Add data visualization charts
4. Create weekly/monthly reports
5. Add voice notes
6. Implement streak tracking
7. Add habit reminders
8. Create social features

## Notes

- All sensitive data (tokens) stored securely
- API calls are fully typed and error-handled
- All screens are responsive and work on different screen sizes
- Dark mode is automatically detected and applied
