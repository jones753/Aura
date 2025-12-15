# Mentor App - API Documentation

## Base URL
```
http://localhost:5000/api
```

## Authentication
Kaikki reitit (paitsi `/auth/register` ja `/auth/login`) vaativat JWT-tokenin Authorization-headerissa:
```
Authorization: Bearer <token>
```

---

## Authentication Routes

### Register User
**POST** `/auth/register`

Luo uuden käyttäjän.

**Request:**
```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "secure_password",
  "first_name": "John",
  "last_name": "Doe",
  "mentor_style": "hilarious",
  "mentor_intensity": 7
}
```

**Response:** `201 Created`
```json
{
  "message": "User registered successfully",
  "user_id": 1
}
```

### Login
**POST** `/auth/login`

Kirjautuu sisään ja saa JWT-tokenin.

**Request:**
```json
{
  "username": "john_doe",
  "password": "secure_password"
}
```

**Response:** `200 OK`
```json
{
  "message": "Login successful",
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user_id": 1,
  "username": "john_doe"
}
```

### Get Profile
**GET** `/auth/me`

Hakee nykyisen käyttäjän profiilin.

**Response:** `200 OK`
```json
{
  "user_id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "mentor_style": "hilarious",
  "mentor_intensity": 7,
  "goals": "Become a better person",
  "created_at": "2025-12-14T10:30:00"
}
```

### Update Profile
**PUT** `/auth/me`

Päivittää käyttäjän profiilia.

**Request:**
```json
{
  "first_name": "Jonathan",
  "mentor_style": "strict",
  "mentor_intensity": 8
}
```

**Response:** `200 OK`
```json
{
  "message": "Profile updated successfully",
  "user": { ... }
}
```

---

## Routines Routes

### Get All Routines
**GET** `/routines`

Hakee kaikki aktiiviset rutiinitavat.

**Response:** `200 OK`
```json
{
  "routines": [
    {
      "id": 1,
      "name": "Morning Exercise",
      "description": "30 min workout",
      "category": "health",
      "frequency": "daily",
      "target_duration": 30,
      "priority": 8,
      "difficulty": 6,
      "is_active": true,
      "created_at": "2025-12-14T10:00:00"
    }
  ]
}
```

### Create Routine
**POST** `/routines`

Luo uuden rutiinitavan.

**Request:**
```json
{
  "name": "Morning Meditation",
  "description": "Meditate for 10 minutes",
  "category": "wellness",
  "frequency": "daily",
  "target_duration": 10,
  "priority": 7,
  "difficulty": 3
}
```

**Response:** `201 Created`
```json
{
  "message": "Routine created successfully",
  "routine": { ... }
}
```

### Get Specific Routine
**GET** `/routines/<routine_id>`

### Update Routine
**PUT** `/routines/<routine_id>`

### Delete Routine
**DELETE** `/routines/<routine_id>`

Deaktivoi rutiinin (ei poista).

---

## Daily Logs Routes

### Get All Daily Logs
**GET** `/daily-logs`

Hakee kaikki päivittäiset kirjaukset (järjestettynä uusimmasta vanhimpaan).

**Response:** `200 OK`
```json
{
  "logs": [
    {
      "id": 1,
      "log_date": "2025-12-14",
      "mood": 7,
      "energy_level": 6,
      "stress_level": 4,
      "notes": "Good day overall",
      "highlights": "Finished project",
      "challenges": "Meetings were long",
      "created_at": "2025-12-14T20:00:00",
      "routine_entries_count": 4
    }
  ]
}
```

### Get Daily Log by Date
**GET** `/daily-logs/date/<date_str>`

Hakee tietyn päivän kirjauksen (muoto: `YYYY-MM-DD`).

**Response:** `200 OK`
```json
{
  "log": {
    "id": 1,
    "log_date": "2025-12-14",
    "mood": 7,
    "energy_level": 6,
    "stress_level": 4,
    "routine_entries": [
      {
        "id": 1,
        "routine_id": 1,
        "routine_name": "Morning Exercise",
        "status": "completed",
        "completion_percentage": 100,
        "actual_duration": 35,
        "difficulty_felt": 5,
        "notes": "Felt great"
      }
    ],
    "created_at": "2025-12-14T20:00:00"
  }
}
```

### Create Daily Log
**POST** `/daily-logs`

Luo uuden päivittäisen kirjauksen (vain kerran päivässä).

**Request:**
```json
{
  "mood": 7,
  "energy_level": 6,
  "stress_level": 4,
  "notes": "Good day overall",
  "highlights": "Finished project",
  "challenges": "Meetings were long"
}
```

**Response:** `201 Created`
```json
{
  "message": "Daily log created successfully",
  "log_id": 1,
  "log_date": "2025-12-14"
}
```

### Update Daily Log
**PUT** `/daily-logs/<log_id>`

Päivittää olemassa olevaa kirjausta.

### Add Routine Entry to Daily Log
**POST** `/daily-logs/<log_id>/routine-entry`

Lisää rutiinin merkinnän päivittäisen kirjauksen alle.

**Request:**
```json
{
  "routine_id": 1,
  "status": "completed",
  "completion_percentage": 100,
  "actual_duration": 35,
  "difficulty_felt": 5,
  "notes": "Felt great"
}
```

**Status values:** `completed`, `partial`, `skipped`, `not_done`

**Response:** `201 Created`

### Update Routine Entry
**PUT** `/daily-logs/routine-entry/<entry_id>`

Päivittää rutiinin merkintää.

---

## Feedback Routes

### Get Feedback for Daily Log
**GET** `/feedback/daily/<log_id>`

Hakee AI:n generoiman palautteen tietylle päivittäiselle kirjaukselle.

**Response:** `200 OK`
```json
{
  "feedback": {
    "id": 1,
    "feedback_text": "Nice work, John. You hit 75% compliance...",
    "routine_compliance_rate": 75,
    "top_performer": "Morning Exercise",
    "biggest_miss": "Evening Reading",
    "suggestions": "Consider breaking routines into smaller chunks.\nTry scheduling high-priority routines when you have most energy.",
    "created_at": "2025-12-14T20:30:00"
  }
}
```

### Generate Feedback
**POST** `/feedback/generate/<log_id>`

Generoi palautteen tietylle päivittäiselle kirjaukselle.

**Response:** `201 Created`
```json
{
  "message": "Feedback generated successfully",
  "feedback": { ... }
}
```

### Get All Feedback
**GET** `/feedback`

Hakee kaikki palautteet (järjestettynä uusimmasta vanhimpaan).

---

## Error Responses

### 400 Bad Request
```json
{
  "message": "Missing required fields"
}
```

### 401 Unauthorized
```json
{
  "message": "Token is missing"
}
```

### 404 Not Found
```json
{
  "message": "Daily log not found"
}
```

### 409 Conflict
```json
{
  "message": "Daily log already exists for today"
}
```

---

## Mentor Styles

Saatavissa olevat mentorin tyylit:
- `strict` - Suora ja vaativa palaute
- `gentle` - Kannustava ja tukeva
- `balanced` - Tasapainoinen (oletus)
- `hilarious` - Humoristinen ja suorasanainen

Mentor intensiteetti: `1-10` (oletus: `5`)

---

## Example Workflow

1. **Rekisteröinti**
   ```bash
   POST /api/auth/register
   ```

2. **Kirjautuminen**
   ```bash
   POST /api/auth/login
   ```

3. **Rutiinitapojen luonti**
   ```bash
   POST /api/routines
   POST /api/routines
   POST /api/routines
   ```

4. **Päivittäinen kirjaus**
   ```bash
   POST /api/daily-logs
   POST /api/daily-logs/<log_id>/routine-entry
   POST /api/daily-logs/<log_id>/routine-entry
   POST /api/daily-logs/<log_id>/routine-entry
   ```

5. **Palautteen generointi**
   ```bash
   POST /api/feedback/generate/<log_id>
   ```

6. **Palautteen lukeminen**
   ```bash
   GET /api/feedback/daily/<log_id>
   ```
