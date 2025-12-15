from flask import Blueprint, request, jsonify
from models import db, Routine, User
from routes.auth import token_required
from datetime import datetime

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
            'target_duration': r.target_duration,
            'priority': r.priority,
            'difficulty': r.difficulty,
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
        target_duration=data.get('target_duration', 30),
        priority=data.get('priority', 5),
        difficulty=data.get('difficulty', 5),
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
            'target_duration': routine.target_duration,
            'priority': routine.priority,
            'difficulty': routine.difficulty,
            'is_active': routine.is_active,
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
        'target_duration': routine.target_duration,
        'priority': routine.priority,
        'difficulty': routine.difficulty,
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
    if 'target_duration' in data:
        routine.target_duration = data['target_duration']
    if 'priority' in data:
        routine.priority = data['priority']
    if 'difficulty' in data:
        routine.difficulty = data['difficulty']
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
            'target_duration': routine.target_duration,
            'priority': routine.priority,
            'difficulty': routine.difficulty,
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
