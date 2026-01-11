import sqlite3
from werkzeug.security import generate_password_hash, check_password_hash

def fix_user_password(db_name):
    print(f"\n--- Checking {db_name} ---")
    try:
        conn = sqlite3.connect(db_name)
        cursor = conn.cursor()
        
        target_user = 'bismakgustavo3@gmail.com'
        target_pass = 'Bismak2006@'
        
        # Check if user exists
        cursor.execute("SELECT id, username, password FROM user WHERE username = ?", (target_user,))
        user = cursor.fetchone()
        
        if not user:
            print(f"❌ User {target_user} NOT found!")
            # Create user if missing
            print(f"🛠️ Creating user {target_user}...")
            hashed_pw = generate_password_hash(target_pass)
            cursor.execute("INSERT INTO user (username, password, display_name) VALUES (?, ?, ?)", 
                          (target_user, hashed_pw, 'Gustavo'))
            conn.commit()
            print("✅ User created successfully.")
            
        else:
            print(f"✅ User {target_user} found (ID: {user[0]}).")
            # Verify Password
            if check_password_hash(user[2], target_pass):
                print("✅ Password is CORRECT.")
            else:
                print("❌ Password is INCORRECT.")
                print("🛠️ Resetting password to 'Bismak2006@'...")
                new_hash = generate_password_hash(target_pass)
                cursor.execute("UPDATE user SET password = ? WHERE id = ?", (new_hash, user[0]))
                conn.commit()
                print("✅ Password reset successfully.")

        conn.close()
    except Exception as e:
        print(f"⚠️ Error with {db_name}: {e}")

# Run for both potential DB files
fix_user_password('ana_mercado.db')
fix_user_password('ana_mercado_v6.db')
