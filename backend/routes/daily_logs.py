from flask import Blueprint, request, jsonify
from models import db, DailyLog, RoutineEntry, Routine, User
from routes.auth import token_required
from datetime import datetime, date

daily_logs_bp = Blueprint('daily_logs', __name__, url_prefix='/api/daily-logs')

@daily_logs_bp.route('', methods=['GET'])
@token_required
def get_daily_logs(current_user):
    """Get all daily logs for current user"""
    logs = DailyLog.query.filter_by(user_id=current_user.id).order_by(DailyLog.log_date.desc()).all()
    
    return jsonify({
        'logs': [{
            'id': log.id,
            'log_date': log.log_date.isoformat(),
            'mood': log.mood,
            'energy_level': log.energy_level,
            'stress_level': log.stress_level,
            'notes': log.notes,
            'highlights': log.highlights,
            'challenges': log.challenges,
            'created_at': log.created_at.isoformat(),
            'routine_entries_count': len(log.routine_entries)
        } for log in logs]
    }), 200

@daily_logs_bp.route('/date/<date_str>', methods=['GET'])
@token_required
def get_daily_log_by_date(current_user, date_str):
    """Get daily log for specific date"""
    try:
        log_date = datetime.fromisoformat(date_str).date()
    except ValueError:
        return jsonify({'message': 'Invalid date format (use YYYY-MM-DD)'}), 400
    
    log = DailyLog.query.filter_by(user_id=current_user.id, log_date=log_date).first()
    
    if not log:
        return jsonify({'message': 'Daily log not found for this date'}), 404
    
    routine_entries = [{
        'id': entry.id,
        'routine_id': entry.routine_id,
        'routine_name': entry.routine.name,
        'status': entry.status,
        'completion_percentage': entry.completion_percentage,
        'actual_duration': entry.actual_duration,
        'difficulty_felt': entry.difficulty_felt,
        'notes': entry.notes
    } for entry in log.routine_entries]
    
    return jsonify({
        'log': {
            'id': log.id,
            'log_date': log.log_date.isoformat(),
            'mood': log.mood,
            'energy_level': log.energy_level,
            'stress_level': log.stress_level,
            'notes': log.notes,
            'highlights': log.highlights,
            'challenges': log.challenges,
            'routine_entries': routine_entries,
            'created_at': log.created_at.isoformat()
        }
    }), 200

@daily_logs_bp.route('', methods=['POST'])
@token_required
def create_daily_log(current_user):
    """Create a new daily log"""
    data = request.get_json()
    
    # Get or create log for today
    today = date.today()
    existing_log = DailyLog.query.filter_by(user_id=current_user.id, log_date=today).first()
    
    if existing_log:
        return jsonify({
            'message': 'Daily log already exists for today',
            'log_id': existing_log.id
        }), 409
    
    log = DailyLog(
        user_id=current_user.id,
        log_date=today,
        mood=data.get('mood'),
        energy_level=data.get('energy_level'),
        stress_level=data.get('stress_level'),
        notes=data.get('notes', ''),
        highlights=data.get('highlights', ''),
        challenges=data.get('challenges', '')
    )
    
    db.session.add(log)
    db.session.commit()
    
    return jsonify({
        'message': 'Daily log created successfully',
        'log_id': log.id,
        'log_date': log.log_date.isoformat()
    }), 201

@daily_logs_bp.route('/<int:log_id>', methods=['PUT'])
@token_required
def update_daily_log(current_user, log_id):
    """Update a daily log"""
    log = DailyLog.query.filter_by(id=log_id, user_id=current_user.id).first()
    
    if not log:
        return jsonify({'message': 'Daily log not found'}), 404
    
    data = request.get_json()
    
    if 'mood' in data:
        log.mood = data['mood']
    if 'energy_level' in data:
        log.energy_level = data['energy_level']
    if 'stress_level' in data:
        log.stress_level = data['stress_level']
    if 'notes' in data:
        log.notes = data['notes']
    if 'highlights' in data:
        log.highlights = data['highlights']
    if 'challenges' in data:
        log.challenges = data['challenges']
    
    log.updated_at = datetime.utcnow()
    db.session.commit()
    
    return jsonify({
        'message': 'Daily log updated successfully',
        'log_id': log.id
    }), 200

@daily_logs_bp.route('/<int:log_id>/routine-entry', methods=['POST'])
@token_required
def add_routine_entry(current_user, log_id):
    """Add a routine entry to daily log"""
    log = DailyLog.query.filter_by(id=log_id, user_id=current_user.id).first()
    
    if not log:
        return jsonify({'message': 'Daily log not found'}), 404
    
    data = request.get_json()
    
    if not data or not data.get('routine_id'):
        return jsonify({'message': 'routine_id is required'}), 400
    
    # Verify routine belongs to user
    routine = Routine.query.filter_by(id=data['routine_id'], user_id=current_user.id).first()
    if not routine:
        return jsonify({'message': 'Routine not found'}), 404
    
    # Check if entry already exists
    existing = RoutineEntry.query.filter_by(routine_id=data['routine_id'], daily_log_id=log_id).first()
    if existing:
        return jsonify({'message': 'Routine entry already exists for this day'}), 409
    
    entry = RoutineEntry(
        routine_id=data['routine_id'],
        daily_log_id=log_id,
        status=data.get('status', 'not_done'),
        completion_percentage=data.get('completion_percentage', 0),
        actual_duration=data.get('actual_duration'),
        difficulty_felt=data.get('difficulty_felt'),
        notes=data.get('notes', '')
    )
    
    db.session.add(entry)
    db.session.commit()
    
    return jsonify({
        'message': 'Routine entry added successfully',
        'entry_id': entry.id
    }), 201

@daily_logs_bp.route('/routine-entry/<int:entry_id>', methods=['PUT'])
@token_required
def update_routine_entry(current_user, entry_id):
    """Update a routine entry"""
    entry = RoutineEntry.query.join(DailyLog).filter(
        RoutineEntry.id == entry_id,
        DailyLog.user_id == current_user.id
    ).first()
    
    if not entry:
        return jsonify({'message': 'Routine entry not found'}), 404
    
    data = request.get_json()
    
    if 'status' in data:
        entry.status = data['status']
    if 'completion_percentage' in data:
        entry.completion_percentage = data['completion_percentage']
    if 'actual_duration' in data:
        entry.actual_duration = data['actual_duration']
    if 'difficulty_felt' in data:
        entry.difficulty_felt = data['difficulty_felt']
    if 'notes' in data:
        entry.notes = data['notes']
    
    db.session.commit()
    
    return jsonify({
        'message': 'Routine entry updated successfully',
        'entry_id': entry.id
    }), 200
