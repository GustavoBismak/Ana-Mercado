import sqlite3
import os

db_path = 'instance/ana_mercado_v6.db'
if not os.path.exists(db_path):
    db_path = 'ana_mercado_v6.db'

print(f"Migrando banco de dados: {db_path}")

try:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Adicionar a coluna budget
    cursor.execute("ALTER TABLE shopping_list ADD COLUMN budget FLOAT DEFAULT 0.0")
    
    conn.commit()
    conn.close()
    print("✅ Coluna 'budget' adicionada com sucesso!")
except sqlite3.OperationalError as e:
    if "duplicate column name" in str(e).lower():
        print("ℹ️ A coluna 'budget' já existe.")
    else:
        print(f"❌ Erro ao migrar: {e}")
except Exception as e:
    print(f"❌ Erro inesperado: {e}")
