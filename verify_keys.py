import os
import requests
from dotenv import load_dotenv

load_dotenv()
api_key = os.environ.get('BREVO_API_KEY')

if not api_key:
    print("BREVO_API_KEY não encontrada no .env")
else:
    print(f"Verificando chave Brevo: {api_key[:10]}...")
    url = "https://api.brevo.com/v3/account"
    headers = {
        "accept": "application/json",
        "api-key": api_key
    }
    
    try:
        response = requests.get(url, headers=headers)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            print("✅ Chave válida!")
            print(f"Conta: {response.json().get('email')}")
        else:
            print(f"❌ Chave inválida ou erro: {response.text}")
    except Exception as e:
        print(f"Erro na requisição: {e}")
