"""
AI Prompt templates for mentor feedback generation and routine generation.
These prompts are used with OpenAI API to generate personalized content.
"""

# Single default system prompt for feedback generation
DEFAULT_FEEDBACK_SYSTEM_PROMPT = """You are a balanced, supportive personal mentor.
You provide honest, constructive feedback that acknowledges both accomplishments and areas
for improvement. You're encouraging but realistic, professional, and solution-oriented.
You celebrate wins while offering practical guidance for challenges."""

FEEDBACK_GENERATION_PROMPT = """
You are a personal mentor analyzing a user's daily routine performance.

USER INFORMATION:
- Name: {user_name}

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

Keep response concise but meaningful. Maintain a balanced, supportive tone.
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

# ---------------------- Routine Generation Prompts ----------------------

# Single default system prompt for routine generation
DEFAULT_ROUTINE_SYSTEM_PROMPT = """You are a helpful coach who designs realistic daily routines
aligned with user goals. Create routines with time ranges (start_time and end_time in HH:MM format)
and flexible frequency descriptions (e.g., '3x per week', 'daily'). Always return strictly valid
JSON following the requested schema."""

def build_routine_generation_user_prompt(user, goals: str, challenges: str, unavailable_times: str, desired_routines: str):
    return f"""
User Information:
- Name: {user.first_name or user.username}

User Inputs:
- Goals: {goals or 'None provided'}
- Challenges: {challenges or 'None provided'}
- Unavailable Times: {unavailable_times or 'None provided'}
- Desired Routines: {desired_routines or 'None provided'}

Task:
Design a set of 4-7 daily routines tailored to the user's goals and constraints. Respect unavailable times when scheduling. Prefer names that are short and conventional. Keep durations realistic and sustainable.

Output Requirements:
- Return a single JSON object with a top-level key "routines".
- The value of "routines" must be an array of 4-7 routine objects.
- Each routine must be an object with fields:
    - name: string (short, conventional name)
    - description: string (one sentence)
    - category: one of ["health", "work", "personal", "social"]
    - frequency: string (e.g., "daily", "3x per week", "weekly")
    - target_duration: integer minutes (5 to 120)
    - priority: integer 1–10 (higher means more important)
    - start_time: string in 24-hour HH:MM format (start of time window)
    - end_time: string in 24-hour HH:MM format (end of time window)

Constraints:
- Avoid duplicates by name.
- Keep JSON strictly valid; do not include comments or extra text.
- If desired routines are specified, try to include them where appropriate.
- Choose time windows that do not overlap the listed unavailable time ranges.
- Make time windows realistic (e.g., "07:00" to "09:00" for morning routine).
- Frequency should be flexible - not all routines need to be daily.
"""

ROUTINE_SUMMARY_SYSTEM_PROMPT = (
    "You are a concise, empathetic coach. Write a short, 5-7 sentence summary "
    "about the user's current life situation (as implied by goals/challenges) and "
    "the set of proposed routines and why they fit. Maintain a balanced, supportive tone."
)

def build_routine_summary_user_prompt(user, goals: str, challenges: str, unavailable_times: str, desired_routines: str, routines: list[dict]):
    routines_lines = []
    for r in routines:
        st = r.get('start_time')
        et = r.get('end_time')
        time_part = f" {st}-{et}" if st and et else (f" at {st}" if st else "")
        routines_lines.append(f"- {r.get('name')} ({r.get('category')}, {r.get('target_duration')} min, {r.get('frequency')}, priority {r.get('priority')}{time_part}) — {r.get('description')}")
    routines_block = "\n".join(routines_lines)

    return f"""
User Information:
- Name: {user.first_name or user.username}
- Goals: {goals or 'None provided'}
- Challenges: {challenges or 'None provided'}
- Unavailable Times: {unavailable_times or 'None provided'}
- Desired Routines: {desired_routines or 'None provided'}

Proposed Routines:
{routines_block}

Task:
Write a short summary (5–7 sentences) that:
- Reflects the user's situation and constraints.
- Explains why these routines were chosen and how they support the goals.
- Maintains a balanced, encouraging tone.
- Is direct and scannable; no lists, just a cohesive paragraph.
"""

