# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Personal Mentor App - A full-stack mobile application for tracking daily routines, logging moods, and receiving AI-powered personalized feedback from a customizable mentor.

**Tech Stack:**
- **Backend:** Flask 3.0, SQLAlchemy, SQLite (dev) / PostgreSQL (prod), JWT authentication
- **Frontend:** Flutter/Dart, Material Design 3, flutter_secure_storage for tokens

## Common Commands

### Backend
```bash
cd backend
python -m venv venv
venv\Scripts\activate          # Windows
pip install -r requirements.txt
python app.py                  # Runs on http://localhost:5000
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run                    # Default device
flutter run -d chrome          # Web browser
flutter run -d windows         # Windows desktop
flutter build apk              # Android release
```

### Database
```bash
cd backend
flask db migrate -m "description"
flask db upgrade
```

## Architecture

### Backend Structure
```
backend/
├── app.py              # Flask factory, blueprint registration
├── config.py           # Environment-based configuration
├── models.py           # SQLAlchemy ORM (users, routines, daily_logs, feedback)
├── prompts.py          # AI prompt templates for mentor feedback generation
└── routes/
    ├── auth.py         # JWT auth (register, login, profile)
    ├── routines.py     # Routine CRUD + AI generation
    ├── daily_logs.py   # Daily logs + routine entries
    └── feedback.py     # AI feedback with OpenAI (fallback to rules)
```

### Frontend Structure
```
frontend/lib/
├── main.dart           # App entry, theming, routing
├── services/           # API communication layer
│   ├── api_service.dart       # Generic HTTP client with auth headers
│   ├── auth_service.dart      # Auth operations
│   ├── routine_service.dart   # Routine CRUD
│   ├── daily_log_service.dart # Daily log operations
│   └── feedback_service.dart  # Feedback retrieval
└── screens/
    ├── auth/           # Login, register, mentor setup
    ├── home/           # Main app (dashboard, routines, daily log, profile)
    └── onboarding/     # Routine setup flow (manual or AI-assisted)
```

### Key Patterns
- **Service-based architecture:** Services handle API calls, screens handle UI
- **JWT authentication:** 24-hour token expiration, stored in flutter_secure_storage
- **FutureBuilder pattern:** Async data loading in Flutter screens
- **Mentor personalization:** 4 styles (strict/gentle/balanced/hilarious) + intensity (1-10)

## Database Schema

- **users:** Authentication + mentor preferences (style, intensity) + profile info
- **routines:** Templates with scheduling (frequency, target_duration, scheduled_time)
- **daily_logs:** Daily entries with mood/energy/stress (1-10 scale)
- **routine_entries:** Performance tracking per routine per day
- **feedback:** AI-generated feedback with compliance metrics

## API Endpoints

Base URL: `http://localhost:5000/api`

| Category | Key Endpoints |
|----------|---------------|
| Auth | POST /auth/register, /auth/login; GET/PUT /auth/me |
| Routines | GET/POST /routines; POST /routines/generate-ai |
| Daily Logs | POST /daily-logs; GET /daily-logs/date/YYYY-MM-DD |
| Feedback | POST /feedback/daily/{log_id}; GET /feedback |

Full API documentation: `backend/API_DOCUMENTATION.md`

## Configuration

- Backend environment: `backend/.env` (OpenAI API key, database URL)
- API base URL: `frontend/lib/services/api_config.dart`
- Database file: `backend/instance/mentor_app.db`

## AI Integration

OpenAI integration is optional. If OPENAI_API_KEY is not set in `.env`, the app falls back to rule-based feedback generation. The AI generates:
- Routine suggestions based on user goals
- Daily feedback based on mentor style and intensity
