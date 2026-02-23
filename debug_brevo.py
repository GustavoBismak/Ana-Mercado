import os
import requests
from dotenv import load_dotenv

load_dotenv()
api_key = os.environ.get('BREVO_API_KEY')

print(f"Testing Brevo Key: {api_key[:10]}...")

url = "https://api.brevo.com/v3/smtp/email"
headers = {
    "accept": "application/json",
    "content-type": "application/json",
    "api-key": api_key
}

# Just a simple test payload
payload = {
    "sender": {"email": "bismakgustavo3@gmail.com", "name": "Ana Mercado"},
    "to": [{"email": "bismakgustavo3@gmail.com"}],
    "subject": "Debug Brevo",
    "textContent": "Teste de depuração do sistema Brevo."
}

response = requests.post(url, json=payload, headers=headers)

print(f"Status: {response.status_code}")
try:
    print(f"Body: {response.json()}")
except:
    print(f"Body: {response.text}")
