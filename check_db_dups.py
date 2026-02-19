from app import db, ShoppingList, app
from collections import Counter

def check_duplicates():
    with app.app_context():
        all_lists = ShoppingList.query.all()
        print(f"Total de listas no banco: {len(all_lists)}")
        
        # Check for identical lists (same ID - impossible due to PK, but let's check names/users)
        id_counts = Counter([l.id for l in all_lists])
        id_dups = [item for item, count in id_counts.items() if count > 1]
        print(f"IDs duplicados: {id_dups}")
        
        # Check for lists with same name and user
        name_user_tuples = [(l.name, l.user_id, l.is_completed) for l in all_lists]
        tuple_counts = Counter(name_user_tuples)
        tuple_dups = {k: v for k, v in tuple_counts.items() if v > 1}
        print(f"Listas com mesmo nome/usuário/status: {tuple_dups}")
        
        for (name, user_id, status), count in tuple_dups.items():
            ids = [l.id for l in all_lists if l.name == name and l.user_id == user_id and l.is_completed == status]
            print(f"  - Lista '{name}' (User {user_id}): IDs {ids}")

if __name__ == "__main__":
    check_duplicates()
