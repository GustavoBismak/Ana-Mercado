import os
import resend
from dotenv import load_dotenv

# Load environment variables from .env
load_dotenv()

resend.api_key = os.environ.get("RESEND_API_KEY")

def send_verification_code(email, code):
    """
    Sends a verification code to the user's email using Resend API.
    """
    try:
        params = {
            "from": "Ana Mercado <onboarding@resend.dev>",
            "to": [email],
            "subject": f"{code} é o seu código de verificação",
            "html": f"""
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
            """,
        }

        email_response = resend.Emails.send(params)
        print(f"Email sent successfully to {email}: {email_response}")
        return True
    except Exception as e:
        print(f"Error sending email with Resend: {e}")
        return False
