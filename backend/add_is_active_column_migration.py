"""
Database migration script to add is_active column to routines table.
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
        # Check if column already exists
        cursor.execute("PRAGMA table_info(routines)")
        columns = cursor.fetchall()
        column_names = [col[1] for col in columns]
        
        print("Current columns in routines table:", column_names)
        
        if 'is_active' in column_names:
            print("Column is_active already exists.")
            return
        
        # Add is_active column with default value of 1 (True)
        print("\nAdding is_active column...")
        cursor.execute("""
            ALTER TABLE routines 
            ADD COLUMN is_active BOOLEAN DEFAULT 1
        """)
        
        # Set all existing routines to active
        cursor.execute("""
            UPDATE routines 
            SET is_active = 1 
            WHERE is_active IS NULL
        """)
        
        # Commit changes
        conn.commit()
        print("Successfully added is_active column to routines table!")
        
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
    print("Starting migration to add is_active column...")
    migrate()
    print("\nMigration complete!")
