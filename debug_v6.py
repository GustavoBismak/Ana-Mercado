import sqlite3
import os

db_path = 'ana_mercado_v6.db'

if not os.path.exists(db_path):
    print(f"Error: Database file {db_path} not found.")
else:
    print(f"--- Checking {db_path} ---")
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Check if table exists
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='user';")
        if not cursor.fetchone():
             print("Table 'user' does not exist.")
        else:
             cursor.execute("SELECT id, username, password_hash, api_token FROM user")
             users = cursor.fetchall()
             if not users:
                 print("No users found in 'user' table.")
             for user in users:
                 print(f"ID: {user[0]}, Username: {user[1]}, Token: {user[3]}")
                 # Not printing hash for security, just confirming it exists
        conn.close()
    except Exception as e:
        print(f"Error reading {db_path}: {e}")
