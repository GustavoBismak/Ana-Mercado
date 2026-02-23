import os
import requests
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

BREVO_API_KEY = os.environ.get('BREVO_API_KEY')
SENDER_EMAIL = "bismakgustavo3@gmail.com"
SENDER_NAME = "Ana Mercado"

def send_verification_code(email, code):
    """
    Sends a verification code using Brevo (formerly Sendinblue) API.
    """
    if not BREVO_API_KEY:
        print("Erro: BREVO_API_KEY não configurada no .env")
        return False

    url = "https://api.brevo.com/v3/smtp/email"
    
    headers = {
        "accept": "application/json",
        "content-type": "application/json",
        "api-key": BREVO_API_KEY
    }

    payload = {
        "sender": {
            "name": SENDER_NAME,
            "email": SENDER_EMAIL
        },
        "to": [
            {
                "email": email,
                "name": "Usuário"
            }
        ],
        "subject": f"{code} é o seu código de verificação",
        "htmlContent": f"""
            <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 25px rgba(0,0,0,0.1); border: 1px solid #e1e7f0;">
                <div style="background: linear-gradient(135deg, #4F46E5 0%, #7C3AED 100%); padding: 40px 20px; text-align: center;">
                    <h1 style="color: #ffffff; margin: 0; font-size: 28px; letter-spacing: -1px;">Ana Mercado</h1>
                    <p style="color: rgba(255,255,255,0.8); margin-top: 10px; font-size: 16px;">Segurança e Praticidade</p>
                </div>
                
                <div style="padding: 40px; color: #1f2937;">
                    <h2 style="font-size: 22px; font-weight: 700; margin-bottom: 20px; color: #111827;">Recuperação de Acesso</h2>
                    <p style="font-size: 16px; line-height: 1.6; color: #4b5563;">Olá,</p>
                    <p style="font-size: 16px; line-height: 1.6; color: #4b5563;">Recebemos uma solicitação para redefinir a senha da sua conta no <strong>Ana Mercado</strong>. Use o código de verificação abaixo:</p>
                    
                    <div style="margin: 35px 0; text-align: center;">
                        <div style="background-color: #f3f4f6; display: inline-block; padding: 20px 40px; border-radius: 12px; border: 2px dashed #4F46E5;">
                            <span style="font-family: 'Courier New', Courier, monospace; font-size: 38px; font-weight: 800; letter-spacing: 8px; color: #4F46E5;">{code}</span>
                        </div>
                        <p style="font-size: 13px; color: #9ca3af; margin-top: 15px;">Este código é válido por <strong>15 minutos</strong>.</p>
                    </div>
                </div>
                
                <div style="background-color: #f9fafb; padding: 25px; text-align: center; border-top: 1px solid #f1f5f9;">
                    <p style="margin: 0; font-size: 14px; color: #9ca3af;">&copy; 2024 Ana Mercado. App de Gestão Inteligente.</p>
                </div>
            </div>
            """
    }

    try:
        response = requests.post(url, json=payload, headers=headers)
        if response.status_code in [200, 201, 202]:
            print(f"Email enviado com sucesso via Brevo para {email}")
            return True
        else:
            print(f"Erro ao enviar e-mail via Brevo: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print(f"Exceção ao enviar e-mail via Brevo: {e}")
        return False
