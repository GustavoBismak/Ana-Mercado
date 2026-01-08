from app import app, db, init_db, User

with app.app_context():
    print("Initializing DB...")
    init_db()
    print("DB Initialized.")
    
    users = User.query.all()
    if not users:
        print("No users found even after init.")
    else:
        for u in users:
            print(f"User: {u.username} | Token: {u.api_token}")
