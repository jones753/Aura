# Mentor App Backend

Backend for a personal mentor app that tracks daily routines, mood, and gives blunt or humorous AI feedback.

## Stack
- Flask (API)
- SQLAlchemy + Flask-SQLAlchemy (ORM)
- SQLite for local dev (PostgreSQL in production)
- Flask-Migrate (migrations)
- OpenAI API (planned) for feedback generation

## Data Models
- `User`: auth fields, mentor style (`strict`, `gentle`, `balanced`, `hilarious`), intensity, goals, bio
- `Routine`: user’s planned routines (category, frequency, priority, difficulty, active flag)
- `DailyLog`: per-day entry with mood, energy, stress, notes/highlights/challenges
- `RoutineEntry`: performance of a routine on a given day (status, completion %, duration, difficulty felt)
- `Feedback`: AI-generated daily feedback (compliance %, top performer, biggest miss, suggestions)
- `Notification`: reminders (type, title/message, sent/read flags, scheduled time)

## Setup
1) Copy `.env.example` → `.env` and set values (SQLite default works out of the box).
2) Install deps: `pip install -r requirements.txt`
3) Run the app: `python app.py`

Base URL: `http://localhost:5000/api`

## Endpoints

### Health
- `GET /api/health` – returns service status.

### Auth
- `POST /api/auth/register` – create a user. Body: `username`, `email`, `password`, optional `first_name`, `last_name`, `mentor_style`, `mentor_intensity`.
- `POST /api/auth/login` – returns JWT token. Body: `username`, `password`.
- `GET /api/auth/me` – current user profile. Requires `Authorization: Bearer <token>`.
- `PUT /api/auth/me` – update profile fields (`first_name`, `last_name`, `goals`, `mentor_style`, `mentor_intensity`). Requires auth.

### Routines
- `GET /api/routines` – list active routines for the user. Requires auth.
- `POST /api/routines` – create routine. Requires auth.
- `GET /api/routines/<id>` – get one. Requires auth.
- `PUT /api/routines/<id>` – update. Requires auth.
- `DELETE /api/routines/<id>` – deactivate routine. Requires auth.

### Daily Logs
- `GET /api/daily-logs` – list logs (newest first). Requires auth.
- `GET /api/daily-logs/date/<YYYY-MM-DD>` – get log by date. Requires auth.
- `POST /api/daily-logs` – create today’s log (one per day). Requires auth.
- `PUT /api/daily-logs/<log_id>` – update log fields. Requires auth.
- `POST /api/daily-logs/<log_id>/routine-entry` – add routine entry to that day. Requires auth.
- `PUT /api/daily-logs/routine-entry/<entry_id>` – update a routine entry. Requires auth.

### Feedback
- `GET /api/feedback/daily/<log_id>` – get feedback for a log (marks read). Requires auth.
- `POST /api/feedback/generate/<log_id>` – generate feedback for a log (simple rule-based; AI hook ready). Requires auth.
- `GET /api/feedback` – list feedback history. Requires auth.

### Notes
- Auth-protected routes expect header: `Authorization: Bearer <token>`.
- Mentor styles: `strict`, `gentle`, `balanced`, `hilarious`. Intensity: 1–10.

## Quick Test (PowerShell)

Health check:
```powershell
curl http://localhost:5000/api/health
```

Register:
```powershell
$body = '{
	"username": "testuser",
	"email": "test@example.com",
	"password": "password123",
	"first_name": "Test",
	"mentor_style": "hilarious",
	"mentor_intensity": 8
}'

curl -X POST http://localhost:5000/api/auth/register `
	-ContentType "application/json" `
	-Body $body
```

Login (get token):
```powershell
$body = '{"username": "testuser", "password": "password123"}'
curl -X POST http://localhost:5000/api/auth/login `
	-ContentType "application/json" `
	-Body $body
```

Profile with token:
```powershell
$token = "<YOUR_TOKEN>"
curl -X GET http://localhost:5000/api/auth/me `
	-Headers @{"Authorization" = "Bearer $token"}
```

Create a routine:
```powershell
$body = '{
	"name": "Morning Exercise",
	"description": "30 min workout",
	"category": "health",
	"frequency": "daily",
	"target_duration": 30,
	"priority": 8,
	"difficulty": 6
}'

curl -X POST http://localhost:5000/api/routines `
	-Headers @{"Authorization" = "Bearer $token"} `
	-ContentType "application/json" `
	-Body $body
```

Create today’s log:
```powershell
$body = '{"mood":7,"energy_level":6,"stress_level":4,"notes":"Good day"}'
curl -X POST http://localhost:5000/api/daily-logs `
	-Headers @{"Authorization" = "Bearer $token"} `
	-ContentType "application/json" `
	-Body $body
```

Generate feedback for log `1`:
```powershell
curl -X POST http://localhost:5000/api/feedback/generate/1 `
	-Headers @{"Authorization" = "Bearer $token"}
```

## Workflow: Daily Log and Feedback

| Step | Operation | Method |
| --- | --- | --- |
| 1 | Log mood & routines | `POST /api/daily-logs` to create today’s log, then `POST /api/daily-logs/<log_id>/routine-entry` for each routine |
| 2 | Generate feedback | `POST /api/feedback/generate/<log_id>` |
| 3 | View feedback (first time) | `GET /api/feedback/daily/<log_id>` ✓ |
| 4 | View feedback (later) | `GET /api/feedback/daily/<log_id>` ✓ |
| 5 | View all feedback history | `GET /api/feedback` |

Notes:
- All methods under `/api` require `Authorization: Bearer <token>` unless explicitly public (e.g., health, register, login).
- Use `GET /api/daily-logs/date/<YYYY-MM-DD>` to retrieve the day’s `log_id` if needed.
