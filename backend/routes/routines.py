from flask import Blueprint, request, jsonify, current_app
from models import db, Routine, User
from routes.auth import token_required
from datetime import datetime
from datetime import time as dt_time
import re
import os
import json

try:
    from openai import OpenAI
except Exception:
    OpenAI = None

from prompts import (
    build_routine_generation_user_prompt,
    DEFAULT_ROUTINE_SYSTEM_PROMPT,
    build_routine_summary_user_prompt,
    ROUTINE_SUMMARY_SYSTEM_PROMPT,
)

routines_bp = Blueprint('routines', __name__, url_prefix='/api/routines')

@routines_bp.route('', methods=['GET'])
@token_required
def get_routines(current_user):
    """Get all routines for current user"""
    routines = Routine.query.filter_by(user_id=current_user.id, is_active=True).all()
    
    return jsonify({
        'routines': [{
            'id': r.id,
            'name': r.name,
            'description': r.description,
            'category': r.category,
            'frequency': r.frequency,
            'selected_days': r.selected_days,
            'target_duration': r.target_duration,
            'priority': r.priority,
            'is_active': r.is_active,
            'created_at': r.created_at.isoformat()
        } for r in routines]
    }), 200

@routines_bp.route('', methods=['POST'])
@token_required
def create_routine(current_user):
    """Create a new routine"""
    data = request.get_json()
    
    if not data or not data.get('name'):
        return jsonify({'message': 'Routine name is required'}), 400

    routine = Routine(
        user_id=current_user.id,
        name=data['name'],
        description=data.get('description', ''),
        category=data.get('category', 'general'),
        frequency=data.get('frequency', 'daily'),
        selected_days=data.get('selected_days', 'all'),
        target_duration=data.get('target_duration', 30),
        priority=data.get('priority', 5),
        is_active=data.get('is_active', True)
    )
    
    db.session.add(routine)
    db.session.commit()
    
    return jsonify({
        'message': 'Routine created successfully',
        'routine': {
            'id': routine.id,
            'name': routine.name,
            'description': routine.description,
            'category': routine.category,
            'frequency': routine.frequency,
            'selected_days': routine.selected_days,
            'target_duration': routine.target_duration,
            'priority': routine.priority,
            'is_active': routine.is_active,
            'start_time': routine.start_time.strftime('%H:%M') if routine.start_time else None,
            'end_time': routine.end_time.strftime('%H:%M') if routine.end_time else None,
            'created_at': routine.created_at.isoformat()
        }
    }), 201

@routines_bp.route('/<int:routine_id>', methods=['GET'])
@token_required
def get_routine(current_user, routine_id):
    """Get specific routine"""
    routine = Routine.query.filter_by(id=routine_id, user_id=current_user.id).first()
    
    if not routine:
        return jsonify({'message': 'Routine not found'}), 404
    
    return jsonify({
        'id': routine.id,
        'name': routine.name,
        'description': routine.description,
        'category': routine.category,
        'frequency': routine.frequency,
        'selected_days': routine.selected_days,
        'target_duration': routine.target_duration,
        'priority': routine.priority,
        'is_active': routine.is_active,
        'created_at': routine.created_at.isoformat()
    }), 200

@routines_bp.route('/<int:routine_id>', methods=['PUT'])
@token_required
def update_routine(current_user, routine_id):
    """Update a routine"""
    routine = Routine.query.filter_by(id=routine_id, user_id=current_user.id).first()
    
    if not routine:
        return jsonify({'message': 'Routine not found'}), 404
    
    data = request.get_json()
    
    if 'name' in data:
        routine.name = data['name']
    if 'description' in data:
        routine.description = data['description']
    if 'category' in data:
        routine.category = data['category']
    if 'frequency' in data:
        routine.frequency = data['frequency']
    if 'selected_days' in data:
        routine.selected_days = data['selected_days']
    if 'target_duration' in data:
        routine.target_duration = data['target_duration']
    if 'priority' in data:
        routine.priority = data['priority']
    if 'is_active' in data:
        routine.is_active = data['is_active']
    
    db.session.commit()
    
    return jsonify({
        'message': 'Routine updated successfully',
        'routine': {
            'id': routine.id,
            'name': routine.name,
            'description': routine.description,
            'category': routine.category,
            'frequency': routine.frequency,
            'selected_days': routine.selected_days,
            'target_duration': routine.target_duration,
            'priority': routine.priority,
            'is_active': routine.is_active,
            'created_at': routine.created_at.isoformat()
        }
    }), 200

@routines_bp.route('/<int:routine_id>', methods=['DELETE'])
@token_required
def delete_routine(current_user, routine_id):
    """Delete (deactivate) a routine"""
    routine = Routine.query.filter_by(id=routine_id, user_id=current_user.id).first()
    
    if not routine:
        return jsonify({'message': 'Routine not found'}), 404
    
    routine.is_active = False
    db.session.commit()
    
    return jsonify({'message': 'Routine deactivated successfully'}), 200


@routines_bp.route('/generate-ai', methods=['POST'])
@token_required
def generate_ai_routines(current_user):
    """Generate a set of starter routines based on user responses.
    Primary path uses LLM; falls back to rule-based heuristics if unavailable.
    Request body can include:
    - goals: str
    - challenges: str
    - unavailable_times: str (comma-separated)
    - desired_routines: str (comma-separated or free text)
    """
    data = request.get_json() or {}

    goals = (data.get('goals') or '').lower()
    challenges = (data.get('challenges') or '').lower()
    desired = (data.get('desired_routines') or '').lower()
    unavailable_times = (data.get('unavailable_times') or '').strip()

    # Try LLM-driven generation first if configured
    suggestions = []
    used_llm_generation = False

    api_key = os.getenv('OPENAI_API_KEY')
    model = os.getenv('OPENAI_MODEL', 'gpt-4o-mini')
    base_url = os.getenv('OPENAI_BASE_URL')

    def _normalize_routine_obj(obj):
        # Parse HH:MM times if present
        start_str = (obj.get('start_time') or '').strip() if isinstance(obj, dict) else ''
        end_str = (obj.get('end_time') or '').strip() if isinstance(obj, dict) else ''
        start_time = None
        end_time = None

        if start_str:
            try:
                hh, mm = start_str.split(':')[:2]
                start_time = dt_time(int(hh), int(mm))
            except Exception:
                start_time = None

        if end_str:
            try:
                hh, mm = end_str.split(':')[:2]
                end_time = dt_time(int(hh), int(mm))
            except Exception:
                end_time = None

        return {
            'name': str(obj.get('name', '')).strip()[:120],
            'description': str(obj.get('description', '')).strip(),
            'category': (obj.get('category') or 'personal'),
            'frequency': obj.get('frequency', 'daily'),
            'target_duration': int(max(5, min(120, int(obj.get('target_duration') or 20)))),
            'priority': int(max(1, min(10, int(obj.get('priority') or 5)))),
            'start_time': start_time,
            'end_time': end_time,
        }

    if api_key and OpenAI is not None:
        try:
            client = OpenAI(api_key=api_key, base_url=base_url) if base_url else OpenAI(api_key=api_key)
            user_prompt = build_routine_generation_user_prompt(
                current_user,
                goals,
                challenges,
                unavailable_times,
                desired,
            )
            # Request JSON object with key "routines"
            completion = client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": DEFAULT_ROUTINE_SYSTEM_PROMPT},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=0.6,
            )

            content = completion.choices[0].message.content if completion.choices else None
            if content:
                # Strip triple-backtick fences if present
                txt = content.strip()
                if txt.startswith('```'):
                    # remove first fence line and trailing fence
                    lines = [line for line in txt.splitlines() if not line.strip().startswith('```')]
                    txt = "\n".join(lines).strip()
                parsed = json.loads(txt)
                routines_list = parsed.get('routines', []) if isinstance(parsed, dict) else []
                for r in routines_list:
                    norm = _normalize_routine_obj(r)
                    # Clamp category
                    if norm['category'] not in ('health', 'work', 'personal'):
                        norm['category'] = 'personal'
                    # Ensure frequency is daily
                    norm['frequency'] = 'daily'
                    suggestions.append(norm)
                if suggestions:
                    used_llm_generation = True
        except Exception as e:
            # Fall back to heuristics silently
            current_app.logger.info(f"AI routine generation fallback due to error: {e}")
            suggestions = []

    # Basic time-slot helper using coarse preferences by category
    def _blocked_ranges(unavail: str):
        # Expected format examples: "5-7 AM", "1-3 PM", comma-separated
        blocks = []
        if not unavail:
            return blocks
        parts = [p.strip() for p in unavail.split(',') if p.strip()]
        for p in parts:
            try:
                span, mer = p.split(' ')
                start_s, end_s = span.split('-')
                mer = mer.upper()
                def to_24(h):
                    h = int(h)
                    if mer == 'AM':
                        return 0 if h == 12 else h
                    else:
                        return 12 if h == 12 else h + 12
                start_h = to_24(start_s)
                end_h = to_24(end_s)
                blocks.append((start_h, end_h))
            except Exception:
                continue
        return blocks

    def _pick_time(category: str, unavail: str, duration: int = 60):
        """Pick a time range for a routine. Returns (start_time, end_time) tuple."""
        prefs = {
            'health': [6, 7, 18],
            'work': [9, 10, 14],
            'personal': [20, 21, 19],
        }
        options = prefs.get(category, [8, 18, 20])
        blocks = _blocked_ranges(unavail)

        def allowed(h):
            for b in blocks:
                if b[0] <= h < b[1]:
                    return False
            return True

        # Pick start hour
        start_hour = options[0]
        for h in options:
            if allowed(h):
                start_hour = h
                break

        # Calculate end hour (add duration minutes to start)
        end_hour = start_hour + (duration // 60)
        end_minute = duration % 60

        return (dt_time(start_hour, 0), dt_time(end_hour, end_minute))

    def add(name, description, category, duration, priority, start_time=None, end_time=None):
        if start_time is None or end_time is None:
            start_time, end_time = _pick_time(category, unavailable_times, duration)

        suggestions.append({
            'name': name,
            'description': description,
            'category': category,
            'frequency': 'daily',
            'target_duration': duration,
            'priority': priority,
            'start_time': start_time,
            'end_time': end_time,
        })

    # If LLM unavailable or returned nothing, use heuristics fallback
    if not suggestions:
        current_app.logger.info("AI routine generation using heuristics fallback (no LLM suggestions)")
        # Heuristics from goals
        if re.search(r'fit|health|exercise|workout|run|gym', goals):
            add('Morning Exercise', 'Start your day with movement', 'health', 30, 8)
            add('Evening Walk', 'Light walk to unwind', 'health', 20, 6)

        if re.search(r'read|learn|study|course|language', goals):
            add('Reading', 'Read non-fiction or fiction', 'personal', 30, 7)
            add('Learning Session', 'Progress on a course or skill', 'personal', 45, 8)

        if re.search(r'productiv|work|career|focus|deep work', goals):
            add('Deep Work Session', 'Focused work without distractions', 'work', 60, 9)
            add('Plan Tomorrow', 'Plan tasks for the next day', 'work', 15, 8)

        if re.search(r'mind|meditat|stress|mindful|mental', goals):
            add('Mindfulness', 'Short mindfulness or breathing session', 'personal', 10, 7)

        # Heuristics from challenges
        if re.search(r'motivat|consisten|procrastinat', challenges):
            add('Daily Journaling', 'Two-minute reflection to build consistency', 'personal', 5, 7)

        if re.search(r'time|busy|schedule', challenges):
            add('Time Blocking', 'Block a chunk for focused work', 'work', 45, 8)

        # Heuristics from desired routine keywords
        if desired:
            if re.search(r'strength|gym|weights', desired):
                add('Strength Training', 'Full-body strength routine', 'health', 40, 8)
            if re.search(r'yoga', desired):
                add('Yoga', 'Stretching and flexibility', 'health', 25, 6)
            if re.search(r'language|spanish|french|german|japanese|english', desired):
                add('Language Practice', 'Vocabulary + speaking drills', 'personal', 20, 7)
            if re.search(r'mindful|meditat', desired):
                add('Meditation', 'Mindfulness/meditation session', 'personal', 10, 7)

        # If still empty, add balanced defaults
        if not suggestions:
            add('Morning Exercise', 'Start your day with movement', 'health', 20, 7)
            add('Reading', 'Read for personal growth', 'personal', 20, 6)
            add('Deep Work Session', 'Focused work without distractions', 'work', 45, 8)

    # Deduplicate by name
    unique = {}
    for s in suggestions:
        unique[s['name'].lower()] = s
    suggestions = list(unique.values())

    # Create routines if not already present for this user
    created = []
    for s in suggestions:
        existing = Routine.query.filter_by(user_id=current_user.id, name=s['name']).first()
        if existing and existing.is_active:
            continue
        if existing and not existing.is_active:
            # Reactivate and update basics
            existing.description = s['description']
            existing.category = s['category']
            existing.frequency = s['frequency']
            existing.target_duration = s['target_duration']
            existing.priority = s['priority']
            existing.is_active = True
            created.append(existing)
        else:
            routine = Routine(
                user_id=current_user.id,
                name=s['name'],
                description=s['description'],
                category=s['category'],
                frequency=s['frequency'],
                target_duration=s['target_duration'],
                priority=s['priority'],
                is_active=True,
            )
            db.session.add(routine)
            created.append(routine)

    db.session.commit()

    # Build a concise LLM summary about the user's situation and why these routines
    summary_text = None
    used_llm_summary = False
    try:
        if api_key and OpenAI is not None and created:
            client = OpenAI(api_key=api_key, base_url=base_url) if base_url else OpenAI(api_key=api_key)
            # Represent the created routines as dicts for the prompt
            created_dicts = [{
                'name': r.name,
                'description': r.description,
                'category': r.category,
                'frequency': r.frequency,
                'target_duration': r.target_duration,
                'priority': r.priority,
                'start_time': r.start_time.strftime('%H:%M') if r.start_time else None,
                'end_time': r.end_time.strftime('%H:%M') if r.end_time else None,
            } for r in created]
            summary_user_prompt = build_routine_summary_user_prompt(
                current_user,
                goals,
                challenges,
                unavailable_times,
                desired,
                created_dicts,
            )
            completion = client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": ROUTINE_SUMMARY_SYSTEM_PROMPT},
                    {"role": "user", "content": summary_user_prompt},
                ],
                temperature=0.7,
            )
            content = completion.choices[0].message.content if completion.choices else None
            if content:
                txt = content.strip()
                if txt.startswith('```'):
                    lines = [line for line in txt.splitlines() if not line.strip().startswith('```')]
                    txt = "\n".join(lines).strip()
                summary_text = txt
                used_llm_summary = True
    except Exception:
        summary_text = None

    # Fallback deterministic summary if LLM unavailable
    if not summary_text:
        # Build a compact paragraph
        routine_names = ', '.join([r.name for r in created][:5])
        more = '' if len(created) <= 5 else f", plus {len(created)-5} more"
        summary_text = (
            f"Based on your goals and challenges, I've proposed routines like {routine_names}{more}. "
            f"These aim to fit your constraints (unavailable: {unavailable_times or 'none'}) and support your objectives. "
            f"The plan is balanced and realistic to help you build sustainable momentum."
        )

    return jsonify({
        'message': 'AI routines generated successfully',
        'summary': summary_text,
        'used_llm_generation': used_llm_generation,
        'used_llm_summary': used_llm_summary,
        'routines': [{
            'id': r.id,
            'name': r.name,
            'description': r.description,
            'category': r.category,
            'frequency': r.frequency,
            'target_duration': r.target_duration,
            'priority': r.priority,
            'is_active': r.is_active,
            'created_at': r.created_at.isoformat(),
        } for r in created]
    }), 201
