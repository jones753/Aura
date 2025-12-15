from flask import Flask
from flask_cors import CORS
from models import db
from config import config
from routes.auth import auth_bp
from routes.routines import routines_bp
from routes.daily_logs import daily_logs_bp
from routes.feedback import feedback_bp
import os

def create_app(config_name=None):
    """Application factory"""
    if config_name is None:
        config_name = os.getenv('FLASK_ENV', 'development')
    
    app = Flask(__name__)
    app.config.from_object(config[config_name])
    
    # Initialize database
    db.init_app(app)
    
    # Enable CORS
    CORS(app)
    
    # Register blueprints
    app.register_blueprint(auth_bp)
    app.register_blueprint(routines_bp)
    app.register_blueprint(daily_logs_bp)
    app.register_blueprint(feedback_bp)
    
    with app.app_context():
        db.create_all()
    
    # Health check endpoint
    @app.route('/api/health', methods=['GET'])
    def health_check():
        return {'status': 'ok', 'message': 'Mentor app backend is running'}, 200
    
    return app

if __name__ == '__main__':
    app = create_app()
    app.run(debug=True, host='0.0.0.0', port=5000)
