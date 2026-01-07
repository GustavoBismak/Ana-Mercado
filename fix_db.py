from app import app, db
import os

print(f"DB URI: {app.config['SQLALCHEMY_DATABASE_URI']}")
db_path = os.path.join(app.instance_path, 'ana_mercado_v6.db')
print(f"Expected Instance DB Path: {db_path}")
print(f"Exists? {os.path.exists(db_path)}")

with app.app_context():
    try:
        print("Creating all tables...")
        db.create_all()
        print("Tables created.")
        
        # Verify
        from sqlalchemy import inspect
        inspector = inspect(db.engine)
        print("Tables in DB:", inspector.get_table_names())
        
    except Exception as e:
        print(f"Error: {e}")
