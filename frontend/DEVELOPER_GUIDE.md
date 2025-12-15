# Flutter Frontend - Developer Quick Reference

## Project Overview
A complete Flutter mobile app for the Personal Mentor application. Fully integrated with Flask backend API.

**Status**: ✅ Complete and Ready to Run
**Build Target**: iOS & Android
**Min SDK**: Flutter 3.10.4

## Quick Commands

```bash
# Setup
cd frontend
flutter pub get

# Run
flutter run                    # Default device
flutter run -d chrome         # Web
flutter run -d emulator-5554  # Specific device

# Build
flutter build apk             # Android
flutter build ios             # iOS
flutter build web             # Web

# Clean
flutter clean
flutter pub get
```

## File Quick Reference

### Services (API & Business Logic)

| File | Purpose | Key Methods |
|------|---------|------------|
| `auth_service.dart` | User auth & profile | register(), login(), getProfile(), updateProfile() |
| `api_service.dart` | HTTP client | get(), post(), put(), delete() |
| `routine_service.dart` | Routines CRUD | getRoutines(), createRoutine(), updateRoutine(), deleteRoutine() |
| `daily_log_service.dart` | Daily logs CRUD | getDailyLogs(), getDailyLogByDate(), createDailyLog(), addRoutineEntry() |
| `feedback_service.dart` | AI feedback | getFeedbackForLog(), generateFeedback(), getAllFeedback() |

### Screens (UI Pages)

| File | Purpose | Key Features |
|------|---------|------------|
| `login_screen.dart` | User login | Form validation, error handling |
| `register_screen.dart` | User registration | Mentor preferences, field validation |
| `home_screen.dart` | Dashboard | Stats, navigation, recent logs |
| `routines_screen.dart` | Routine management | CRUD operations, cards, dialogs |
| `daily_log_screen.dart` | Daily logging | Log creation, routine entries, feedback |
| `profile_screen.dart` | Profile management | Edit profile, mentor settings, account info |

## Key Classes & Models

### auth_service.dart
```dart
AuthService()
  - register({...}) → Future<Map>
  - login({...}) → Future<Map>
  - getProfile() → Future<Map>
  - updateProfile({...}) → Future<Map>
  - getToken() → Future<String?>
  - isLoggedIn() → Future<bool>
  - logout() → Future<void>
```

### routine_service.dart
```dart
class Routine {
  int id, targetDuration, priority, difficulty
  String name, description, category, frequency
  bool isActive
  DateTime createdAt
}

RoutineService()
  - getRoutines() → Future<List<Routine>>
  - createRoutine({...}) → Future<Routine>
  - updateRoutine({...}) → Future<Routine>
  - deleteRoutine(id) → Future<void>
```

### daily_log_service.dart
```dart
class DailyLog {
  int id, mood, energyLevel, stressLevel, routineEntriesCount
  String notes, highlights, challenges
  DateTime logDate, createdAt
}

class RoutineEntry {
  int id, routineId, completionPercentage, actualDuration
  String status, routineName, notes
}

DailyLogService()
  - getDailyLogs() → Future<List<DailyLog>>
  - getDailyLogByDate(DateTime) → Future<DailyLogDetail>
  - createDailyLog({...}) → Future<DailyLog>
  - addRoutineEntry({...}) → Future<void>
```

### feedback_service.dart
```dart
class Feedback {
  int id, routineComplianceRate
  String feedbackText, topPerformer, biggestMiss, suggestions
  DateTime createdAt
}

FeedbackService()
  - getFeedbackForLog(logId) → Future<Feedback>
  - generateFeedback(logId) → Future<Feedback>
  - getAllFeedback() → Future<List<Feedback>>
```

## API Configuration

**Base URL**: `http://localhost:5000/api`

**To change**: Update `baseUrl` in:
- `lib/services/auth_service.dart` (line ~10)
- `lib/services/api_service.dart` (line ~4)

```dart
static const String baseUrl = 'http://your-backend:port/api';
```

## Authentication Flow

```
1. User Registration
   ↓
   POST /auth/register
   ↓
   Account created
   
2. User Login
   ↓
   POST /auth/login
   ↓
   Receive JWT token
   ↓
   Store token securely
   ↓
   Navigate to home
   
3. All Requests
   ↓
   Include: Authorization: Bearer <token>
   ↓
   If 401 → Logout user
   
4. Logout
   ↓
   Delete stored token
   ↓
   Navigate to login
```

## State Management Pattern

```dart
// In screens:
late Future<Type> _dataFuture;

@override
void initState() {
  _dataFuture = Service.getData();
}

// In build:
FutureBuilder<Type>(
  future: _dataFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    if (snapshot.hasError) {
      return ErrorWidget();
    }
    return ContentWidget(snapshot.data);
  },
)

// Refresh:
onRefresh: () async {
  setState(() {
    _dataFuture = Service.getData();
  });
}
```

## Common UI Patterns

### Dialog (Create/Edit)
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Title'),
    content: SingleChildScrollView(child: Form(...)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
      ElevatedButton(onPressed: _submit, child: Text('Submit')),
    ],
  ),
);
```

### List with Refresh
```dart
RefreshIndicator(
  onRefresh: _refresh,
  child: FutureBuilder(
    future: _dataFuture,
    builder: (context, snapshot) {
      if (snapshot.hasError) return ErrorWidget();
      if (snapshot.connectionState == ConnectionState.waiting) return Loading();
      return ListView.builder(...);
    },
  ),
)
```

### Error Handling
```dart
try {
  final result = await Service.operation();
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

## Debugging Tips

### Check API Connection
```dart
// In any service method
print('API URL: $baseUrl$endpoint');
print('Response: $response');
```

### Check Token
```dart
final token = await AuthService().getToken();
print('Token: $token');
```

### Check Stored Data
```dart
final isLoggedIn = await AuthService().isLoggedIn();
print('Logged In: $isLoggedIn');
```

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Can't connect to backend | Check backend is running, verify baseUrl |
| Token errors | Re-login, check backend SECRET_KEY matches |
| Data not loading | Check network, refresh screen, verify endpoint |
| Build errors | Run `flutter clean`, then `flutter pub get` |
| Widget errors | Check dispose() methods, avoid setState in dispose |

## Code Style Guidelines

```dart
// Naming
- Classes: PascalCase (MyClass)
- Methods/Variables: camelCase (myMethod)
- Constants: camelCase (myConstant)

// Format
- 2 space indentation
- 80 char line limit (try)
- Group imports
- Use const constructors
- Proper null safety (?)

// Comments
- Use /// for public APIs
- Use // for inline comments
- Keep comments up to date
```

## Performance Tips

1. **Use const constructors** where possible
2. **Dispose resources** properly
3. **Use FutureBuilder** for async operations
4. **Limit rebuilds** with proper widget structure
5. **Cache data** when appropriate
6. **Lazy load** lists with pagination

## Testing Scenarios

1. **Auth Flow**: Register → Login → View Profile → Logout
2. **Routines**: Create → Edit → Delete → View List
3. **Daily Log**: Create → Add Entries → View Feedback
4. **Profile**: Edit → Change Mentor Settings → Save
5. **Errors**: Bad credentials, network issues, server errors

## File Size Reference

- `main.dart`: ~60 lines
- Service files: ~150-250 lines each
- Screen files: ~400-800 lines each
- Total: ~4,000 lines of code

## Dependencies Summary

| Package | Version | Use |
|---------|---------|-----|
| http | ^1.1.0 | HTTP requests |
| flutter_secure_storage | ^9.0.0 | Secure token storage |
| flutter | SDK | Framework |

## Useful Links

- [Flutter Docs](https://flutter.dev/docs)
- [Material Design 3](https://material.io/design)
- [HTTP Package](https://pub.dev/packages/http)
- [Secure Storage](https://pub.dev/packages/flutter_secure_storage)

## Next Developer Steps

1. Read `README.md` for user documentation
2. Read `SETUP.md` for setup instructions
3. Review `main.dart` to understand app structure
4. Check `services/` for API integration patterns
5. Review `screens/` for UI implementation
6. Run the app and test all features
7. Modify as needed for your use case

---
**Last Updated**: December 16, 2025
**Status**: Production Ready
