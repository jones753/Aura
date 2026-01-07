"""
Database migration script to remove start_time and end_time columns from routines table.
Run this script manually due to Python 3.13 compatibility issues with Flask-Migrate.
"""
import sqlite3
import os

def migrate():
    # Get the database path
    db_path = os.path.join(os.path.dirname(__file__), 'instance', 'mentor_app.db')
    
    if not os.path.exists(db_path):
        print(f"Database not found at {db_path}")
        return
    
    # Connect to the database
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        # Check if columns exist
        cursor.execute("PRAGMA table_info(routines)")
        columns = cursor.fetchall()
        column_names = [col[1] for col in columns]
        
        print("Current columns in routines table:", column_names)
        
        has_start_time = 'start_time' in column_names
        has_end_time = 'end_time' in column_names
        
        if not has_start_time and not has_end_time:
            print("Both start_time and end_time columns are already removed.")
            return
        
        # SQLite doesn't support DROP COLUMN directly, so we need to recreate the table
        print("\nCreating new routines table without time columns...")
        
        # Get current table schema (excluding start_time and end_time)
        cursor.execute("""
            CREATE TABLE routines_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name VARCHAR(200) NOT NULL,
                description TEXT,
                category VARCHAR(50),
                frequency VARCHAR(20) DEFAULT 'daily',
                selected_days VARCHAR(100),
                target_duration INTEGER,
                priority VARCHAR(20) DEFAULT 'medium',
                user_id INTEGER NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users (id)
            )
        """)
        
        # Copy data from old table to new table (excluding start_time and end_time)
        cursor.execute("""
            INSERT INTO routines_new (
                id, name, description, category, frequency, selected_days,
                target_duration, priority, user_id, created_at
            )
            SELECT 
                id, name, description, category, frequency, selected_days,
                target_duration, priority, user_id, created_at
            FROM routines
        """)
        
        # Drop old table
        cursor.execute("DROP TABLE routines")
        
        # Rename new table to original name
        cursor.execute("ALTER TABLE routines_new RENAME TO routines")
        
        # Commit changes
        conn.commit()
        print("Successfully removed start_time and end_time columns from routines table!")
        
        # Verify the migration
        cursor.execute("PRAGMA table_info(routines)")
        columns = cursor.fetchall()
        print("\nNew columns in routines table:", [col[1] for col in columns])
        
    except Exception as e:
        conn.rollback()
        print(f"Error during migration: {e}")
        raise
    finally:
        conn.close()

if __name__ == '__main__':
    print("Starting migration to remove start_time and end_time columns...")
    migrate()
    print("\nMigration complete!")
