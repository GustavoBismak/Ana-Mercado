import sqlite3

def check_users(db_name):
    print(f"--- Checking {db_name} ---")
    try:
        conn = sqlite3.connect(db_name)
        cursor = conn.cursor()
        cursor.execute("SELECT id, username, password FROM user")
        users = cursor.fetchall()
        if not users:
            print("No users found.")
        for user in users:
            print(f"ID: {user[0]}, Username: {user[1]}, Password Hash: {user[2]}")
        conn.close()
    except Exception as e:
        print(f"Error reading {db_name}: {e}")

check_users('ana_mercado.db')
check_users('ana_mercado_v6.db')
check_users('instance/ana_mercado.sqlite') # Flask sometimes uses instance folder
