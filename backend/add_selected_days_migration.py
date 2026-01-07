import sqlite3

# Connect to database
conn = sqlite3.connect('instance/mentor_app.db')
cursor = conn.cursor()

try:
    # Add selected_days column
    cursor.execute("ALTER TABLE routines ADD COLUMN selected_days VARCHAR(100)")
    print("Column added successfully")
    
    # Set default value for existing routines
    cursor.execute("UPDATE routines SET selected_days = 'all' WHERE selected_days IS NULL")
    print(f"Updated {cursor.rowcount} existing routines")
    
    conn.commit()
    print("Migration completed successfully!")
    
except sqlite3.OperationalError as e:
    if "duplicate column name" in str(e):
        print("Column already exists, setting defaults...")
        cursor.execute("UPDATE routines SET selected_days = 'all' WHERE selected_days IS NULL")
        conn.commit()
        print("Defaults set successfully!")
    else:
        raise

finally:
    conn.close()
