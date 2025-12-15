# Personal Mentor - Flutter Frontend

A beautiful and comprehensive Flutter mobile application for the Personal Mentor app. This app helps users track daily routines, log their moods, and receive AI-powered feedback from their personal mentor.

## Features

### 🔐 Authentication
- User registration with mentor preferences
- Login with JWT token-based authentication
- Secure token storage using Flutter Secure Storage
- Profile management and preferences

### 📊 Dashboard
- Home screen with quick statistics
- Display of total routines and daily logs
- Recent daily logs overview
- Quick navigation to all features

### ✅ Routine Management
- Create custom daily routines
- Set difficulty levels and target durations
- Categorize routines (health, work, personal, social)
- Edit and delete routines
- Track routine frequency (daily, weekly, custom)

### 📝 Daily Logging
- Create daily logs with mood, energy, and stress metrics (1-10 scale)
- Add notes about your day
- Track highlights and challenges
- Log completion status for each routine
- Track actual duration vs target duration
- Add difficulty ratings for routines

### 🤖 AI Mentor Feedback
- Receive AI-generated feedback based on daily logs
- View routine compliance rates
- Get insights on top performers and biggest misses
- Receive personalized suggestions for improvement
- Adjustable mentor style (strict, gentle, balanced, hilarious)
- Customizable mentor intensity (1-10 scale)

### 👤 Profile Management
- View and edit user profile
- Manage mentor preferences
- Set personal goals
- Add bio information
- Track account creation date

## Getting Started

### Prerequisites
- Flutter SDK 3.10.4 or higher
- Dart SDK
- Backend server running at `http://localhost:5000`

### Installation

1. **Install dependencies:**
```bash
flutter pub get
```

2. **Run the app:**
```bash
flutter run
```

## Dependencies

- **http**: HTTP client for API communication
- **flutter_secure_storage**: Secure storage for authentication tokens
- **flutter**: Core Flutter framework

## Architecture

The app uses a service-based architecture:
- **Services**: Handle all API communication and business logic
- **Screens**: Display UI and manage user interactions
- **Models**: Data classes for type safety

## API Integration

The app connects to endpoints at `http://localhost:5000/api` with JWT authentication.
