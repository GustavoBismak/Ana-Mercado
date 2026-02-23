from email_service import send_verification_code
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

if __name__ == "__main__":
    email = "bismakgustavo3@gmail.com" # Using a test email
    code = "123456"
    print(f"Testando envio de email via BREVO para {email}...")
    
    api_key = os.environ.get('BREVO_API_KEY')
    if api_key:
        print(f"API Key: {api_key[:10]}...{api_key[-5:]}")
    else:
        print("API Key não encontrada no .env!")

    success = send_verification_code(email, code)
    
    if success:
        print("\n✅ Sucesso! O email deve chegar em breve.")
    else:
        print("\n❌ Falha no envio. Tente novamente.")
