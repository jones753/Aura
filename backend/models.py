from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

db = SQLAlchemy()

class User(db.Model):
    """User model"""
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False, index=True)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    
    # Mentor settings
    mentor_style = db.Column(db.String(50), default='balanced')  # 'strict', 'gentle', 'balanced', 'hilarious'
    mentor_intensity = db.Column(db.Integer, default=5)  # 1-10 scale
    
    # User profile
    first_name = db.Column(db.String(50))
    last_name = db.Column(db.String(50))
    bio = db.Column(db.Text)
    goals = db.Column(db.Text)  # User's life goals
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    routines = db.relationship('Routine', back_populates='user', cascade='all, delete-orphan')
    daily_logs = db.relationship('DailyLog', back_populates='user', cascade='all, delete-orphan')
    feedback_history = db.relationship('Feedback', back_populates='user', cascade='all, delete-orphan')

class Routine(db.Model):
    """Daily routine templates created for user"""
    __tablename__ = 'routines'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    name = db.Column(db.String(120), nullable=False)
    description = db.Column(db.Text)
    category = db.Column(db.String(50))  # 'health', 'work', 'personal', 'social', etc.
    
    # Expected frequency and target
    frequency = db.Column(db.String(50))  # 'daily', 'weekly', 'custom'
    target_duration = db.Column(db.Integer)  # minutes
    scheduled_time = db.Column(db.Time)  # preferred time of day (HH:MM:SS)
    
    # Priority and difficulty
    priority = db.Column(db.Integer, default=5)  # 1-10 scale
    difficulty = db.Column(db.Integer, default=5)  # 1-10 scale
    
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    user = db.relationship('User', back_populates='routines')
    daily_entries = db.relationship('RoutineEntry', back_populates='routine', cascade='all, delete-orphan')

class DailyLog(db.Model):
    """Daily log entry from user"""
    __tablename__ = 'daily_logs'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    log_date = db.Column(db.Date, nullable=False, index=True)
    
    # User's mood and overall feeling
    mood = db.Column(db.Integer)  # 1-10 scale
    energy_level = db.Column(db.Integer)  # 1-10 scale
    stress_level = db.Column(db.Integer)  # 1-10 scale
    
    # General notes
    notes = db.Column(db.Text)  # Anything noteworthy
    highlights = db.Column(db.Text)  # Good things that happened
    challenges = db.Column(db.Text)  # Challenges faced
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = db.relationship('User', back_populates='daily_logs')
    routine_entries = db.relationship('RoutineEntry', back_populates='daily_log', cascade='all, delete-orphan')
    feedback = db.relationship('Feedback', back_populates='daily_log', uselist=False, cascade='all, delete-orphan')

class RoutineEntry(db.Model):
    """User's performance on a specific routine for a specific day"""
    __tablename__ = 'routine_entries'
    
    id = db.Column(db.Integer, primary_key=True)
    routine_id = db.Column(db.Integer, db.ForeignKey('routines.id'), nullable=False, index=True)
    daily_log_id = db.Column(db.Integer, db.ForeignKey('daily_logs.id'), nullable=False, index=True)
    
    # Completion status
    status = db.Column(db.String(20), default='not_done')  # 'completed', 'partial', 'skipped', 'not_done'
    completion_percentage = db.Column(db.Integer, default=0)  # 0-100
    actual_duration = db.Column(db.Integer)  # minutes spent
    
    # Notes on this specific routine
    notes = db.Column(db.Text)
    difficulty_felt = db.Column(db.Integer)  # 1-10 how difficult it was
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    routine = db.relationship('Routine', back_populates='daily_entries')
    daily_log = db.relationship('DailyLog', back_populates='routine_entries')

class Feedback(db.Model):
    """AI-generated feedback for a daily log"""
    __tablename__ = 'feedback'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    daily_log_id = db.Column(db.Integer, db.ForeignKey('daily_logs.id'), nullable=False, unique=True)
    
    # Feedback content
    feedback_text = db.Column(db.Text, nullable=False)
    motivation_score = db.Column(db.Integer)  # 1-10 how motivating the feedback was
    
    # Analysis
    routine_compliance_rate = db.Column(db.Float)  # 0-100%
    top_performer = db.Column(db.String(120))  # Best routine of the day
    biggest_miss = db.Column(db.String(120))  # Worst routine of the day
    
    # Suggestions
    suggestions = db.Column(db.Text)  # AI suggestions for improvement
    
    is_read = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    user = db.relationship('User', back_populates='feedback_history')
    daily_log = db.relationship('DailyLog', back_populates='feedback')

class Notification(db.Model):
    """Notifications for user"""
    __tablename__ = 'notifications'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    
    # Notification details
    type = db.Column(db.String(50), nullable=False)  # 'routine_reminder', 'log_reminder', 'feedback_ready', etc.
    title = db.Column(db.String(200), nullable=False)
    message = db.Column(db.Text)
    
    # Status
    is_sent = db.Column(db.Boolean, default=False)
    is_read = db.Column(db.Boolean, default=False)
    sent_at = db.Column(db.DateTime)
    read_at = db.Column(db.DateTime)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    scheduled_for = db.Column(db.DateTime)  # When to send the notification
    
    # Relationships
    user_id_fk = db.Column(db.Integer, db.ForeignKey('users.id'))
