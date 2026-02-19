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
            "subject": "Seu código de verificação - Ana Mercado",
            "html": f"""
            <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #eee; border-radius: 10px; padding: 20px;">
                <h2 style="color: #333; text-align: center;">Recuperação de Senha</h2>
                <p>Olá,</p>
                <p>Você solicitou a redefinição de sua senha no <strong>Ana Mercado</strong>.</p>
                <p>Use o código abaixo para completar o processo:</p>
                <div style="background-color: #f4f4f4; padding: 20px; text-align: center; font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #4F46E5; border-radius: 8px; margin: 20px 0;">
                    {code}
                </div>
                <p style="color: #666; font-size: 14px;">Este código expira em 15 minutos.</p>
                <p style="color: #666; font-size: 14px;">Se você não solicitou isso, por favor ignore este email.</p>
                <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
                <p style="text-align: center; color: #999; font-size: 12px;">© 2024 Ana Mercado. Todos os direitos reservados.</p>
            </div>
            """,
        }

        email_response = resend.Emails.send(params)
        print(f"Email sent successfully to {email}: {email_response}")
        return True
    except Exception as e:
        print(f"Error sending email with Resend: {e}")
        return False
