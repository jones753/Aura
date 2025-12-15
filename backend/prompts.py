"""
AI Prompt templates for mentor feedback generation.
These prompts are used with OpenAI API to generate personalized feedback.
"""

MENTOR_SYSTEM_PROMPTS = {
    'strict': """You are a strict, no-nonsense personal mentor. Your feedback is direct, 
demanding, and calls out mediocrity. You expect excellence and won't sugarcoat reality. 
You're demanding but fair—if someone does well, acknowledge it. If they slack, call it out. 
Be blunt. No excuses. Use occasional sarcasm.""",
    
    'gentle': """You are a supportive, empathetic personal mentor. Your feedback is encouraging 
and focuses on progress over perfection. You celebrate wins, understand struggles, and offer 
constructive guidance. You're warm, patient, and believe in the person's potential. 
Use positive reinforcement and compassionate language.""",
    
    'balanced': """You are a balanced personal mentor. You provide honest, constructive feedback 
that's neither overly harsh nor overly sweet. You acknowledge both accomplishments and areas 
for improvement. You're professional, fair, and solution-oriented. 
Your tone is encouraging but realistic.""",
    
    'hilarious': """You are a funny, brutally honest personal mentor with a great sense of humor. 
Your feedback is witty, sarcastic, and full of humor. You roast gently when things go wrong, 
celebrate with excitement when things go right. Use memes, emojis, and funny analogies. 
Make the person laugh while also being honest about their performance. 
Keep it light but still actionable."""
}

FEEDBACK_GENERATION_PROMPT = """
You are a personal mentor analyzing a user's daily routine performance.

USER INFORMATION:
- Name: {user_name}
- Mentor Style Preference: {mentor_style}
- Mentor Intensity: {mentor_intensity}/10

TODAY'S LOG:
- Date: {log_date}
- Mood: {mood}/10
- Energy Level: {energy_level}/10
- Stress Level: {stress_level}/10
- Notes: {notes}
- Highlights: {highlights}
- Challenges: {challenges}

TODAY'S ROUTINE PERFORMANCE:
{routine_performance}

HISTORICAL PERFORMANCE (Last 30 days):
- Total Days Logged: {total_days_logged}
- Average Mood: {avg_mood}/10
- Average Energy: {avg_energy}/10
- Average Stress: {avg_stress}/10
- Best Performing Routine: {best_routine} ({best_routine_rate}% completion)
- Worst Performing Routine: {worst_routine} ({worst_routine_rate}% completion)
- Overall Compliance Rate: {avg_compliance}%

Routine Completion Rates:
{routine_stats}

TASK:
Generate personalized mentor feedback based on:
1. TODAY'S PERFORMANCE compared to their historical average
2. MOOD/STRESS/ENERGY trends
3. SPECIFIC ROUTINE successes and failures
4. HISTORICAL PATTERNS (what's working, what's not)

Include:
- An opening assessment of today's performance
- Specific feedback about completed/missed routines
- Observations about mood/stress/energy impact
- Historical context ("You usually do better with X", "This routine is consistently your weakness")
- 2-3 actionable suggestions for improvement
- Encouragement (even if performance was poor, find something positive)

Keep response concise but meaningful. Use the mentor style and intensity to guide your tone.
"""

ROUTINE_PERFORMANCE_TEMPLATE = """
Routine: {routine_name}
Status: {status}
Completion: {completion_percentage}%
Target Duration: {target_duration} min | Actual: {actual_duration} min
Difficulty Felt: {difficulty_felt}/10
Notes: {notes}
Historical Completion Rate: {historical_rate}%
"""

def get_system_prompt(mentor_style):
    """Get the system prompt for a given mentor style"""
    return MENTOR_SYSTEM_PROMPTS.get(mentor_style, MENTOR_SYSTEM_PROMPTS['balanced'])

def build_feedback_prompt(user, daily_log, historical_data, routine_entries):
    """
    Build a complete feedback prompt for OpenAI API.
    
    Args:
        user: User object
        daily_log: DailyLog object for today
        historical_data: Dict with historical performance stats
        routine_entries: List of RoutineEntry objects for today
    
    Returns:
        String prompt ready for OpenAI API
    """
    
    # Format routine performance
    routine_performance = ""
    for entry in routine_entries:
        historical_rate = historical_data.get('routine_stats', {}).get(entry.routine.name, {}).get('completion_rate', 0)
        routine_performance += ROUTINE_PERFORMANCE_TEMPLATE.format(
            routine_name=entry.routine.name,
            status=entry.status,
            completion_percentage=entry.completion_percentage,
            target_duration=entry.routine.target_duration,
            actual_duration=entry.actual_duration or 0,
            difficulty_felt=entry.difficulty_felt or "N/A",
            notes=entry.notes or "No notes",
            historical_rate=f"{historical_rate:.0f}" if historical_rate else "N/A"
        )
    
    # Format routine stats
    routine_stats = ""
    if historical_data.get('routine_stats'):
        for routine_name, stats in historical_data['routine_stats'].items():
            routine_stats += f"- {routine_name}: {stats['completion_rate']:.0f}% ({stats['completed']}/{stats['total_attempts']} completed)\n"
    
    # Build the full prompt
    prompt = FEEDBACK_GENERATION_PROMPT.format(
        user_name=user.first_name or user.username,
        mentor_style=user.mentor_style,
        mentor_intensity=user.mentor_intensity,
        log_date=daily_log.log_date.isoformat(),
        mood=daily_log.mood or "Not logged",
        energy_level=daily_log.energy_level or "Not logged",
        stress_level=daily_log.stress_level or "Not logged",
        notes=daily_log.notes or "No notes",
        highlights=daily_log.highlights or "None",
        challenges=daily_log.challenges or "None",
        routine_performance=routine_performance or "No routines logged",
        total_days_logged=historical_data.get('total_days_logged', 0),
        avg_mood=f"{historical_data.get('average_mood', 0):.1f}",
        avg_energy=f"{historical_data.get('average_energy', 0):.1f}",
        avg_stress=f"{historical_data.get('average_stress', 0):.1f}",
        best_routine=historical_data.get('best_routine', "N/A"),
        best_routine_rate=f"{historical_data.get('routine_stats', {}).get(historical_data.get('best_routine', ''), {}).get('completion_rate', 0):.0f}" if historical_data.get('best_routine') else "N/A",
        worst_routine=historical_data.get('worst_routine', "N/A"),
        worst_routine_rate=f"{historical_data.get('routine_stats', {}).get(historical_data.get('worst_routine', ''), {}).get('completion_rate', 0):.0f}" if historical_data.get('worst_routine') else "N/A",
        avg_compliance=f"{sum(s['completion_rate'] for s in historical_data.get('routine_stats', {}).values()) / len(historical_data.get('routine_stats', {})):.0f}" if historical_data.get('routine_stats') else "N/A",
        routine_stats=routine_stats or "No historical data"
    )
    
    return prompt
