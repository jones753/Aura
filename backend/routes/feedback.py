from flask import Blueprint, request, jsonify
from models import db, Feedback, DailyLog, RoutineEntry, Routine
from routes.auth import token_required
from datetime import datetime
from prompts import DEFAULT_FEEDBACK_SYSTEM_PROMPT, build_feedback_prompt
import os

feedback_bp = Blueprint('feedback', __name__, url_prefix='/api/feedback')

# Placeholder for AI feedback generator (will implement with OpenAI)
def generate_ai_feedback(user, daily_log):
    """
    Generate AI feedback based on today's log, all user routines, and historical performance.
    Uses OpenAI API if available, falls back to rule-based generation.
    """
    routine_entries = daily_log.routine_entries
    all_user_logs = DailyLog.query.filter_by(user_id=user.id).all()
    historical_data = analyze_historical_performance(user, all_user_logs)
    
    # Try to use OpenAI API if key is set
    openai_key = os.getenv('OPENAI_API_KEY')
    if openai_key and openai_key != 'your-api-key-here':
        return generate_ai_feedback_openai(user, daily_log, historical_data, routine_entries, openai_key)
    else:
        # Fall back to rule-based generation
        return generate_ai_feedback_rule_based(user, daily_log, historical_data, routine_entries)

def generate_ai_feedback_openai(user, daily_log, historical_data, routine_entries, openai_key):
    """
    Generate feedback using OpenAI API.
    Requires OPENAI_API_KEY environment variable.
    """
    try:
        import openai
        openai.api_key = openai_key
        
        # Build the prompt
        system_prompt = DEFAULT_FEEDBACK_SYSTEM_PROMPT
        user_prompt = build_feedback_prompt(user, daily_log, historical_data, routine_entries)
        
        # Call OpenAI
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0.7,
            max_tokens=500
        )
        
        feedback_text = response.choices[0].message.content
        
        return {
            'feedback_text': feedback_text,
            'routine_compliance_rate': calculate_compliance_rate(routine_entries),
            'top_performer': get_top_performer(routine_entries),
            'biggest_miss': get_biggest_miss(routine_entries),
            'suggestions': generate_suggestions(
                calculate_compliance_rate(routine_entries),
                daily_log.energy_level or 5,
                daily_log.stress_level or 5,
                routine_entries,
                historical_data
            ),
            'ai_generated': True
        }
    
    except Exception as e:
        print(f"OpenAI API error: {e}")
        # Fall back to rule-based if API fails
        return generate_ai_feedback_rule_based(user, daily_log, historical_data, routine_entries)

def generate_ai_feedback_rule_based(user, daily_log, historical_data, routine_entries):
    """
    Rule-based feedback generation (fallback when OpenAI unavailable).
    """
    compliance_rate = calculate_compliance_rate(routine_entries)
    top_performer = get_top_performer(routine_entries)
    biggest_miss = get_biggest_miss(routine_entries)
    # Enrich feedback with historical context
    feedback_data = {
        'feedback_text': None,
        'routine_compliance_rate': compliance_rate,
        'top_performer': top_performer,
        'biggest_miss': biggest_miss,
        'suggestions': [],
        'historical_patterns': historical_data,
        'ai_generated': False
    }
    
    # Generate feedback text based on historical context
    mood = daily_log.mood or 5
    energy = daily_log.energy_level or 5
    stress = daily_log.stress_level or 5

    feedback_text = generate_mentor_feedback(
        compliance_rate=compliance_rate,
        mood=mood,
        energy=energy,
        stress=stress,
        top_performer=top_performer,
        biggest_miss=biggest_miss,
        user_name=user.first_name or user.username,
        historical_data=historical_data
    )
    
    feedback_data['feedback_text'] = feedback_text
    feedback_data['suggestions'] = generate_suggestions(compliance_rate, energy, stress, routine_entries, historical_data)
    
    return feedback_data

def calculate_compliance_rate(routine_entries):
    """Calculate today's routine compliance rate"""
    if not routine_entries:
        return 0
    completed = len([e for e in routine_entries if e.status == 'completed'])
    return (completed / len(routine_entries)) * 100

def get_top_performer(routine_entries):
    """Get best completed routine"""
    completed = [e for e in routine_entries if e.status == 'completed']
    if not completed:
        return None
    return max(completed, key=lambda e: e.routine.priority).routine.name

def get_biggest_miss(routine_entries):
    """Get highest priority missed routine"""
    missed = [e for e in routine_entries if e.status in ['skipped', 'not_done']]
    if not missed:
        return None
    return max(missed, key=lambda e: e.routine.priority).routine.name

def analyze_historical_performance(user, all_logs):
    """
    Analyze user's performance across all logged days.
    Returns patterns like: streak routines, weak routines, mood trends, etc.
    """
    if not all_logs:
        return {}
    
    # Track routine completion rates across all logs
    routine_stats = {}
    all_routines = Routine.query.filter_by(user_id=user.id).all()
    
    for routine in all_routines:
        entries = RoutineEntry.query.filter_by(routine_id=routine.id).all()
        if entries:
            completed = len([e for e in entries if e.status == 'completed'])
            completion_rate = (completed / len(entries)) * 100
            routine_stats[routine.name] = {
                'completion_rate': completion_rate,
                'total_attempts': len(entries),
                'completed': completed
            }
    
    # Calculate mood and stress trends
    moods = [log.mood for log in all_logs if log.mood]
    stresses = [log.stress_level for log in all_logs if log.stress_level]
    energies = [log.energy_level for log in all_logs if log.energy_level]
    
    return {
        'routine_stats': routine_stats,
        'average_mood': sum(moods) / len(moods) if moods else None,
        'average_stress': sum(stresses) / len(stresses) if stresses else None,
        'average_energy': sum(energies) / len(energies) if energies else None,
        'total_days_logged': len(all_logs),
        'best_routine': max(routine_stats.items(), key=lambda x: x[1]['completion_rate'])[0] if routine_stats else None,
        'worst_routine': min(routine_stats.items(), key=lambda x: x[1]['completion_rate'])[0] if routine_stats else None
    }

def generate_mentor_feedback(compliance_rate, mood, energy, stress,
                            top_performer, biggest_miss, user_name, historical_data=None):
    """Generate balanced mentor feedback based on historical context"""

    feedback_parts = []
    historical_data = historical_data or {}

    # Opening based on today's compliance
    if compliance_rate >= 80:
        feedback_parts.append(f"Great work, {user_name}! You achieved {compliance_rate:.0f}% compliance today.")
    elif compliance_rate >= 50:
        feedback_parts.append(f"You're at {compliance_rate:.0f}% compliance, {user_name}. There's room to improve.")
    else:
        feedback_parts.append(f"You're at {compliance_rate:.0f}% compliance. Let's figure out what got in the way.")
    
    # Add observations from today
    if mood <= 3:
        feedback_parts.append(f"I notice your mood is low today. This might be affecting your routines.")
    
    if stress >= 8:
        feedback_parts.append(f"Your stress is high. Remember, perfect execution when stressed is still an achievement.")
    
    if energy <= 3:
        feedback_parts.append(f"Your energy is low. Rest is also important. Don't burn out.")
    
    # Add historical context
    if historical_data:
        best_routine = historical_data.get('best_routine')
        worst_routine = historical_data.get('worst_routine')
        avg_compliance = None
        
        if historical_data.get('routine_stats'):
            all_rates = [stats['completion_rate'] for stats in historical_data['routine_stats'].values()]
            avg_compliance = sum(all_rates) / len(all_rates) if all_rates else None
        
        if best_routine and best_routine != top_performer:
            feedback_parts.append(f"Historically, '{best_routine}' is your strongest routine (high completion rate)—keep up that momentum!")
        
        if worst_routine and worst_routine != biggest_miss:
            feedback_parts.append(f"'{worst_routine}' has been a struggle historically. Consider breaking it into smaller chunks or scheduling it at peak energy times.")
        
        if avg_compliance:
            trend = "improving 📈" if compliance_rate > avg_compliance else "dipping 📉" if compliance_rate < avg_compliance else "consistent"
            feedback_parts.append(f"Your average compliance is {avg_compliance:.0f}%, and today you're {trend}.")
    
    # Highlight top performer today
    if top_performer and compliance_rate >= 50:
        feedback_parts.append(f"Good: You crushed '{top_performer}' today.")
    
    # Address biggest miss
    if biggest_miss and compliance_rate < 80:
        feedback_parts.append(f"You missed '{biggest_miss}' today. What got in the way?")
    
    return " ".join(feedback_parts)

def generate_suggestions(compliance_rate, energy, stress, routine_entries, historical_data=None):
    """Generate actionable suggestions based on today and history"""
    suggestions = []
    historical_data = historical_data or {}
    
    if compliance_rate < 50:
        suggestions.append("Consider breaking routines into smaller, more manageable chunks.")
        suggestions.append("Try scheduling your highest-priority routines when you have the most energy.")
    
    if energy <= 3:
        suggestions.append("You might be overcommitted. Consider temporarily reducing routine difficulty.")
        suggestions.append("Prioritize sleep and nutrition—these fuel everything else.")
    
    if stress >= 8:
        suggestions.append("Consider adding a stress-relief routine like meditation or a walk.")
        suggestions.append("You might benefit from talking about what's causing the stress.")
    
    # Historical insights
    if historical_data:
        routine_stats = historical_data.get('routine_stats', {})
        worst_routine = historical_data.get('worst_routine')
        
        if worst_routine and worst_routine in routine_stats:
            stats = routine_stats[worst_routine]
            if stats['completion_rate'] < 50:
                suggestions.append(f"'{worst_routine}' has low completion ({stats['completion_rate']:.0f}%). Maybe it's too ambitious—adjust expectations or timing.")
    
    if not suggestions:
        suggestions.append("Keep up the good work! Consider adding one new routine to your arsenal.")
        suggestions.append("Reflect on what made today successful and replicate it tomorrow.")
    
    return suggestions

@feedback_bp.route('/daily/<int:log_id>', methods=['GET'])
@token_required
def get_feedback(current_user, log_id):
    """Get feedback for a daily log"""
    log = DailyLog.query.filter_by(id=log_id, user_id=current_user.id).first()
    
    if not log:
        return jsonify({'message': 'Daily log not found'}), 404
    
    feedback = Feedback.query.filter_by(daily_log_id=log_id).first()
    
    if not feedback:
        return jsonify({'message': 'No feedback generated yet for this log'}), 404
    
    feedback.is_read = True
    db.session.commit()
    
    return jsonify({
        'feedback': {
            'id': feedback.id,
            'feedback_text': feedback.feedback_text,
            'routine_compliance_rate': feedback.routine_compliance_rate,
            'top_performer': feedback.top_performer,
            'biggest_miss': feedback.biggest_miss,
            'suggestions': feedback.suggestions,
            'created_at': feedback.created_at.isoformat()
        }
    }), 200

@feedback_bp.route('/generate/<int:log_id>', methods=['POST'])
@token_required
def generate_feedback(current_user, log_id):
    """Generate feedback for a daily log"""
    log = DailyLog.query.filter_by(id=log_id, user_id=current_user.id).first()
    
    if not log:
        return jsonify({'message': 'Daily log not found'}), 404
    
    # Check if feedback already exists
    existing_feedback = Feedback.query.filter_by(daily_log_id=log_id).first()
    if existing_feedback:
        return jsonify({
            'message': 'Feedback already exists for this log',
            'feedback': {
                'id': existing_feedback.id,
                'feedback_text': existing_feedback.feedback_text,
                'routine_compliance_rate': existing_feedback.routine_compliance_rate,
                'top_performer': existing_feedback.top_performer,
                'biggest_miss': existing_feedback.biggest_miss,
                'suggestions': existing_feedback.suggestions,
                'created_at': existing_feedback.created_at.isoformat()
            }
        }), 200
    
    # Generate feedback
    feedback_data = generate_ai_feedback(current_user, log)
    
    feedback = Feedback(
        user_id=current_user.id,
        daily_log_id=log_id,
        feedback_text=feedback_data['feedback_text'],
        routine_compliance_rate=feedback_data['routine_compliance_rate'],
        top_performer=feedback_data['top_performer'],
        biggest_miss=feedback_data['biggest_miss'],
        suggestions='\n'.join(feedback_data['suggestions']) if isinstance(feedback_data['suggestions'], list) else feedback_data['suggestions']
    )
    
    db.session.add(feedback)
    db.session.commit()
    
    return jsonify({
        'message': 'Feedback generated successfully',
        'feedback': {
            'id': feedback.id,
            'feedback_text': feedback.feedback_text,
            'routine_compliance_rate': feedback.routine_compliance_rate,
            'top_performer': feedback.top_performer,
            'biggest_miss': feedback.biggest_miss,
            'suggestions': feedback.suggestions,
            'created_at': feedback.created_at.isoformat()
        }
    }), 201

@feedback_bp.route('', methods=['GET'])
@token_required
def get_all_feedback(current_user):
    """Get all feedback for current user"""
    feedbacks = Feedback.query.filter_by(user_id=current_user.id).order_by(Feedback.created_at.desc()).all()
    
    return jsonify({
        'feedback_history': [{
            'id': f.id,
            'log_date': f.daily_log.log_date.isoformat(),
            'feedback_text': f.feedback_text,
            'routine_compliance_rate': f.routine_compliance_rate,
            'top_performer': f.top_performer,
            'biggest_miss': f.biggest_miss,
            'is_read': f.is_read,
            'created_at': f.created_at.isoformat()
        } for f in feedbacks]
    }), 200
