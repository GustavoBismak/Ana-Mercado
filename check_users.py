from app import db, User, ShoppingList, app

def check_users_and_lists():
    with app.app_context():
        users = User.query.all()
        for u in users:
            lists = ShoppingList.query.filter_by(user_id=u.id).all()
            print(f"User {u.id} ({u.username}): {len(lists)} listas")
            for l in lists:
                print(f"  - ID {l.id}: {l.name} (Status: {l.is_completed})")

if __name__ == "__main__":
    check_users_and_lists()
