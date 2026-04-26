import os
import asyncio
import tempfile
import logging
import json
import re
import base64
import secrets
import smtplib
import socket
from typing import Optional, List
from datetime import datetime, timedelta, timezone
from email.message import EmailMessage
from pathlib import Path
from dotenv import load_dotenv
from fastapi import FastAPI, UploadFile, File, HTTPException, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import bcrypt
import requests
from pymongo import MongoClient
from bson.objectid import ObjectId
from google import genai
from google.genai import types as genai_types

# Load environment variables from backend/.env regardless of current working directory
BASE_DIR = Path(__file__).resolve().parent
load_dotenv(dotenv_path=BASE_DIR / ".env")

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

MAX_UPLOAD_SIZE_BYTES = 10 * 1024 * 1024

app = FastAPI(title="SmartNotes Transcription API")

# Enable CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
print("LOADED API KEY:", GROQ_API_KEY)
GROQ_ENDPOINT = "https://api.groq.com/openai/v1/audio/transcriptions"
GROQ_CHAT_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions"
GROQ_CHAT_MODEL = os.getenv("GROQ_CHAT_MODEL", "llama-3.1-8b-instant")
GROQ_VISION_MODEL = os.getenv("GROQ_VISION_MODEL", "llama-3.2-11b-vision-preview")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "").strip()
GEMINI_COOLDOWN_MINUTES = int(os.getenv("GEMINI_COOLDOWN_MINUTES", "15"))
_gemini_disabled_until: Optional[datetime] = None


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _to_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _gemini_model_candidates() -> List[str]:
    candidates: List[str] = []
    if GEMINI_MODEL:
        candidates.append(GEMINI_MODEL)

    for model_name in [
        "gemini-2.0-flash",
        "gemini-1.5-flash-latest",
        "gemini-1.5-flash",
    ]:
        if model_name not in candidates:
            candidates.append(model_name)

    return candidates


def _is_gemini_disabled() -> bool:
    if _gemini_disabled_until is None:
        return False
    return _utc_now() < _gemini_disabled_until


def _disable_gemini_temporarily(reason: str) -> None:
    global _gemini_disabled_until
    _gemini_disabled_until = _utc_now() + timedelta(minutes=GEMINI_COOLDOWN_MINUTES)
    logger.warning(
        f"[GENERATE_NOTES] Gemini temporarily disabled until {_gemini_disabled_until.isoformat()} due to: {reason}"
    )


def _generate_gemini_response_text(client: genai.Client, model_name: str, prompt: str) -> str:
    response = client.models.generate_content(
        model=model_name,
        contents=prompt,
        config=genai_types.GenerateContentConfig(
            system_instruction="You are an AI tutor.",
            response_mime_type="application/json",
            temperature=0.3,
        ),
    )
    return (getattr(response, "text", "") or "").strip()


def _file_too_large_response() -> JSONResponse:
    return JSONResponse(
        status_code=413,
        content={"error": "File too large", "text": ""},
    )

# MongoDB Configuration
MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017/smartnotes")
try:
    mongo_client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
    mongo_client.admin.command('ping')
    db = mongo_client['smartnotes']
    notes_collection = db['notes']
    users_collection = db['users']
    logger.info("✓ MongoDB connected successfully")
except Exception as e:
    logger.warning(f"⚠ MongoDB connection failed: {e}")
    db = None
    notes_collection = None
    users_collection = None

OTP_EXPIRY_MINUTES = 5
OTP_LENGTH = 6
OTP_EMAIL_ENABLED = os.getenv("OTP_EMAIL_ENABLED", "true").strip().lower() in {
    "1",
    "true",
    "yes",
    "on",
}


class ProcessTranscriptRequest(BaseModel):
    text: str


class ProcessImageRequest(BaseModel):
    imageBase64: str


class GenerateNotesRequest(BaseModel):
    text: str
    mode: str = "exam"


class SaveTranscriptRequest(BaseModel):
    userId: str
    title: str
    subject: str = "Lecture Notes"
    rawText: str
    cleanText: str = ""
    summary: str = ""
    keyPoints: list = []


class FeedbackRequest(BaseModel):
    name: str = ""
    email: str = ""
    feedback: str
    userId: str = ""


class SendOtpRequest(BaseModel):
    email: str


class VerifyOtpRequest(BaseModel):
    email: str
    otp: str


class ResetPasswordRequest(BaseModel):
    email: str
    otp: str
    newPassword: str


def _normalize_email(email: str) -> str:
    return email.strip().lower()


def _find_user_by_email(email: str):
    if users_collection is None:
        return None

    # Prefer exact lookup, then fallback to case-insensitive match for legacy rows.
    user = users_collection.find_one({"email": email})
    if user:
        return user

    escaped_email = re.escape(email)
    return users_collection.find_one({"email": {"$regex": f"^{escaped_email}$", "$options": "i"}})


def _generate_otp() -> str:
    return f"{secrets.randbelow(10 ** OTP_LENGTH):0{OTP_LENGTH}d}"


def _email_port() -> int:
    try:
        return int(os.getenv("EMAIL_PORT", "587"))
    except ValueError:
        return 587


def _send_otp_email(recipient: str, otp: str) -> None:
    email_user = os.getenv("EMAIL_USER", "").strip()
    email_pass = os.getenv("EMAIL_PASS", "").strip()
    
    # DEBUG LOGGING
    print("="*60)
    print("[DEBUG] EMAIL CREDENTIALS CHECK")
    print(f"EMAIL_USER: {email_user}")
    print(f"EMAIL_PASS: {'*' * len(email_pass) if email_pass else 'NOT SET'}")
    print("="*60)
    
    if not email_user or not email_pass:
        raise ValueError("Email credentials are not configured")

    email_host = os.getenv("EMAIL_HOST", "smtp.gmail.com")
    email_from = os.getenv("EMAIL_FROM", email_user)

    message = EmailMessage()
    message["Subject"] = "🔐 SmartNotes Password Reset Code"
    message["From"] = email_from
    message["To"] = recipient
    
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background-color: #f5f5f5;
                margin: 0;
                padding: 20px;
            }}
            .container {{
                max-width: 600px;
                margin: 0 auto;
                background-color: #ffffff;
                border-radius: 8px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                overflow: hidden;
            }}
            .header {{
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 30px;
                text-align: center;
            }}
            .header h1 {{
                margin: 0;
                font-size: 28px;
                font-weight: 600;
            }}
            .content {{
                padding: 40px 30px;
            }}
            .greeting {{
                font-size: 16px;
                color: #333;
                margin-bottom: 20px;
            }}
            .otp-section {{
                background-color: #f8f9fa;
                border-left: 4px solid #667eea;
                padding: 20px;
                margin: 30px 0;
                border-radius: 4px;
            }}
            .otp-label {{
                font-size: 12px;
                color: #666;
                text-transform: uppercase;
                letter-spacing: 1px;
                font-weight: 600;
                margin-bottom: 10px;
            }}
            .otp-code {{
                font-size: 32px;
                font-weight: 700;
                color: #667eea;
                letter-spacing: 4px;
                font-family: 'Monaco', 'Courier New', monospace;
                text-align: center;
            }}
            .expiry-info {{
                background-color: #fff3cd;
                border-left: 4px solid #ffc107;
                padding: 15px;
                margin: 20px 0;
                border-radius: 4px;
                font-size: 14px;
                color: #856404;
            }}
            .security-notice {{
                background-color: #e8f4f8;
                border-left: 4px solid #17a2b8;
                padding: 15px;
                margin: 20px 0;
                border-radius: 4px;
                font-size: 13px;
                color: #0c5460;
            }}
            .footer {{
                background-color: #f8f9fa;
                padding: 20px 30px;
                text-align: center;
                font-size: 12px;
                color: #666;
                border-top: 1px solid #e0e0e0;
            }}
            .footer-link {{
                color: #667eea;
                text-decoration: none;
            }}
            .divider {{
                height: 1px;
                background-color: #e0e0e0;
                margin: 20px 0;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🔐 Password Reset Code</h1>
            </div>
            
            <div class="content">
                <p class="greeting">Hello,</p>
                
                <p>We received a request to reset your SmartNotes password. Use the code below to complete the password reset process:</p>
                
                <div class="otp-section">
                    <div class="otp-label">Your Reset Code</div>
                    <div class="otp-code">{otp}</div>
                </div>
                
                <div class="expiry-info">
                    ⏰ <strong>This code expires in {OTP_EXPIRY_MINUTES} minutes.</strong> If you didn't request this code, please ignore this email.
                </div>
                
                <div class="security-notice">
                    🔒 <strong>Security Notice:</strong> Never share this code with anyone. SmartNotes team will never ask for this code.
                </div>
                
                <div class="divider"></div>
                
                <p style="font-size: 13px; color: #666; margin-top: 20px;">
                    If you didn't request a password reset, you can safely ignore this email. Your account remains secure.
                </p>
            </div>
            
            <div class="footer">
                <p>© 2026 SmartNotes. All rights reserved.</p>
                <p>
                    <a href="#" class="footer-link">Privacy Policy</a> | 
                    <a href="#" class="footer-link">Help Center</a>
                </p>
            </div>
        </div>
    </body>
    </html>
    """
    
    message.set_content("Your OTP for password reset is: " + otp)
    message.add_alternative(html_content, subtype='html')

    try:
        print("[DEBUG] Connecting to SMTP server...")
        with smtplib.SMTP(email_host, _email_port(), timeout=15) as server:
            print("[DEBUG] Connection successful, starting TLS...")
            server.starttls()
            print("[DEBUG] TLS started, attempting login...")
            server.login(email_user, email_pass)
            print("[DEBUG] Login successful!")
            server.send_message(message)
            print("[DEBUG] Email sent successfully!")
    except Exception as e:
        print("="*60)
        print("[SMTP ERROR]:", str(e))
        print("ERROR TYPE:", type(e).__name__)
        print("="*60)
        raise


def _is_valid_otp(otp: str) -> bool:
    return bool(re.fullmatch(r"\d{6}", otp))


def _password_strength_error(password: str) -> Optional[str]:
    if len(password) < 8:
        return "Password must be at least 8 characters"
    if not re.search(r"[A-Z]", password):
        return "Password must include an uppercase letter"
    if not re.search(r"[a-z]", password):
        return "Password must include a lowercase letter"
    if not re.search(r"\d", password):
        return "Password must include a number"
    return None


def _empty_process_response(error_message: str) -> dict:
    return {
        "clean_text": "",
        "summary": "",
        "key_points": [],
        "error": error_message,
    }


def _extract_json_object(content: str) -> dict:
    try:
        return json.loads(content)
    except json.JSONDecodeError:
        start = content.find("{")
        end = content.rfind("}")
        if start != -1 and end != -1 and end > start:
            return json.loads(content[start:end + 1])
    raise ValueError("Model response is not valid JSON")


def _normalize_process_response(data: dict) -> dict:
    clean_text = str(data.get("clean_text", "")).strip()
    summary = str(data.get("summary", "")).strip()
    key_points = data.get("key_points", [])

    if isinstance(key_points, str):
        points = [p.strip(" -*\t") for p in key_points.splitlines() if p.strip()]
        key_points = points if points else [key_points.strip()]
    elif isinstance(key_points, list):
        key_points = [str(p).strip() for p in key_points if str(p).strip()]
    else:
        key_points = []

    return {
        "clean_text": clean_text,
        "summary": summary,
        "key_points": key_points,
    }


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/send-otp")
async def send_otp(payload: SendOtpRequest):
    if users_collection is None:
        return JSONResponse(
            status_code=500,
            content={"error": "Database connection failed"},
        )

    email = _normalize_email(payload.email)

    print("✅ API HIT - NORMALIZED EMAIL:", email)

    if not email:
        return JSONResponse(
            status_code=400,
            content={"error": "Email is required"},
        )

    try:
        user = _find_user_by_email(email)
    except Exception as exc:
        logger.error(f"[SEND_OTP] User lookup failed for {email}: {exc}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"error": "Database query failed"},
        )

    if not user:
        return JSONResponse(
            status_code=404,
            content={"error": "User not found"},
        )

    otp = _generate_otp()
    expires_at = _utc_now() + timedelta(minutes=OTP_EXPIRY_MINUTES)

    print(f"[SEND_OTP] Generated OTP: {otp}, Expires: {expires_at}")

    try:
        users_collection.update_one(
            {"_id": user["_id"]},
            {
                "$set": {
                    "passwordResetOtp": otp,
                    "passwordResetOtpExpiresAt": expires_at.isoformat(),
                }
            },
        )
        print(f"[SEND_OTP] OTP stored for {email}")
    except Exception as exc:
        logger.error(f"[SEND_OTP] Failed to store OTP: {exc}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"error": "Failed to store OTP"},
        )

    if OTP_EMAIL_ENABLED:
        try:
            _send_otp_email(email, otp)
        except Exception as exc:
            logger.error(f"[SEND_OTP] Email sending failed: {exc}", exc_info=True)
            return JSONResponse(
                status_code=500,
                content={"error": "Failed to send OTP email"},
            )

    return JSONResponse(
        status_code=200,
        content={"message": "OTP sent successfully"},
    )


@app.post("/verify-otp")
async def verify_otp(payload: VerifyOtpRequest):
    if users_collection is None:
        return JSONResponse(
            status_code=500,
            content={"error": "Database connection failed"},
        )

    email = _normalize_email(payload.email)
    otp = payload.otp.strip()

    if not email or not otp:
        return JSONResponse(
            status_code=400,
            content={"error": "Email and OTP are required"},
        )

    if not _is_valid_otp(otp):
        return JSONResponse(
            status_code=400,
            content={"error": "OTP must be a 6-digit number"},
        )

    try:
        user = _find_user_by_email(email)
    except Exception as exc:
        logger.error(f"[VERIFY_OTP] User lookup failed for {email}: {exc}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"error": "Database query failed"},
        )

    if not user:
        return JSONResponse(
            status_code=404,
            content={"error": "User not found"},
        )

    stored_otp = str(user.get("passwordResetOtp", "")).strip()
    expires_at = user.get("passwordResetOtpExpiresAt")

    if not stored_otp or not expires_at:
        return JSONResponse(
            status_code=400,
            content={"error": "OTP not found"},
        )

    if stored_otp != otp:
        return JSONResponse(
            status_code=400,
            content={"error": "Invalid OTP"},
        )

    if isinstance(expires_at, str):
        try:
            expires_at = datetime.fromisoformat(expires_at)
        except ValueError:
            expires_at = None

    if not isinstance(expires_at, datetime) or _utc_now() > _to_utc(expires_at):
        return JSONResponse(
            status_code=400,
            content={"error": "OTP expired"},
        )

    print("OTP verified for:", email)
    return JSONResponse(status_code=200, content={"success": True})


@app.post("/reset-password")
async def reset_password(payload: ResetPasswordRequest):
    if users_collection is None:
        return JSONResponse(
            status_code=500,
            content={"error": "Database connection failed"},
        )

    email = _normalize_email(payload.email)
    otp = payload.otp.strip()
    new_password = payload.newPassword

    if not email or not otp or not new_password:
        return JSONResponse(
            status_code=400,
            content={"error": "Email, OTP, and new password are required"},
        )

    if not _is_valid_otp(otp):
        return JSONResponse(
            status_code=400,
            content={"error": "OTP must be a 6-digit number"},
        )

    strength_error = _password_strength_error(new_password)
    if strength_error:
        return JSONResponse(
            status_code=400,
            content={"error": strength_error},
        )

    try:
        user = _find_user_by_email(email)
    except Exception as exc:
        logger.error(f"[RESET_PASSWORD] User lookup failed for {email}: {exc}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"error": "Database query failed"},
        )

    if not user:
        return JSONResponse(
            status_code=404,
            content={"error": "User not found"},
        )

    stored_otp = str(user.get("passwordResetOtp", "")).strip()
    expires_at = user.get("passwordResetOtpExpiresAt")

    if not stored_otp or not expires_at:
        return JSONResponse(
            status_code=400,
            content={"error": "OTP not found"},
        )

    if stored_otp != otp:
        return JSONResponse(
            status_code=400,
            content={"error": "Invalid OTP"},
        )

    if isinstance(expires_at, str):
        try:
            expires_at = datetime.fromisoformat(expires_at)
        except ValueError:
            expires_at = None

    if not isinstance(expires_at, datetime) or _utc_now() > _to_utc(expires_at):
        return JSONResponse(
            status_code=400,
            content={"error": "OTP expired"},
        )

    hashed_password = bcrypt.hashpw(
        new_password.encode("utf-8"),
        bcrypt.gensalt(),
    ).decode("utf-8")

    users_collection.update_one(
        {"_id": user["_id"]},
        {
            "$set": {
                "password": hashed_password,
                "updatedAt": _utc_now(),
            },
            "$unset": {
                "passwordResetOtp": "",
                "passwordResetOtpExpiresAt": "",
                "passwordResetOtpRequestedAt": "",
            },
        },
    )

    return JSONResponse(
        status_code=200,
        content={"success": True, "message": "Password reset successfully"},
    )


@app.post("/transcribe")
async def transcribe(file: UploadFile = File(...)):
    """
    Transcribe audio file using Groq API.
    
    Args:
        file: Audio file (WAV, MP3, etc.)
    
    Returns:
        {"text": "transcription"}
    """
    logger.debug(f"[TRANSCRIBE] Received file: {file.filename}")
    
    if not GROQ_API_KEY:
        logger.error("[TRANSCRIBE] GROQ_API_KEY not set")
        return JSONResponse(
            status_code=500,
            content={"error": "GROQ_API_KEY not configured", "text": ""}
        )
    
    try:
        # Save uploaded file to temp location
        content = await file.read()
        if len(content) > MAX_UPLOAD_SIZE_BYTES:
            logger.warning(
                f"[TRANSCRIBE] File too large: {len(content)} bytes ({file.filename})"
            )
            return _file_too_large_response()

        with tempfile.NamedTemporaryFile(
            suffix=".wav", delete=False, dir=tempfile.gettempdir()
        ) as temp_file:
            temp_file.write(content)
            temp_path = temp_file.name
        
        logger.debug(f"[TRANSCRIBE] Saved temp file: {temp_path}, size: {len(content)} bytes")
        
        # Call Groq API
        with open(temp_path, "rb") as audio:
            files = {
                "file": (file.filename, audio, "audio/wav"),
            }
            data = {
                "model": "whisper-large-v3-turbo",
                "language": "en",
            }
            headers = {
                "Authorization": f"Bearer {GROQ_API_KEY}",
            }
            
            logger.debug("[TRANSCRIBE] Sending to Groq API...")
            response = requests.post(
                GROQ_ENDPOINT,
                headers=headers,
                files=files,
                data=data,
                timeout=30,
            )
        
        logger.debug(f"[TRANSCRIBE] Groq response status: {response.status_code}")
        
        if response.status_code != 200:
            logger.error(f"[TRANSCRIBE] Groq error: {response.text}")
            return JSONResponse(
                status_code=response.status_code,
                content={"error": "Groq API failed", "text": ""}
            )
        
        result = response.json()
        text = result.get("text", "").strip()
        logger.debug(f"[TRANSCRIBE] Extracted text: {text}")
        
        return JSONResponse({"text": text})
    
    except Exception as e:
        logger.error(f"[TRANSCRIBE] Exception: {str(e)}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"error": str(e), "text": ""}
        )
    
    finally:
        # Clean up temp file
        try:
            os.unlink(temp_path)
            logger.debug(f"[TRANSCRIBE] Cleaned up temp file: {temp_path}")
        except Exception as e:
            logger.warning(f"[TRANSCRIBE] Failed to clean up temp file: {e}")


@app.post("/process-transcript")
async def process_transcript(payload: ProcessTranscriptRequest):
    """
    Clean and structure a raw lecture transcript using Groq Chat Completion API.

    Input:
        {"text": "raw transcript text"}
    """
    if not GROQ_API_KEY:
        logger.error("[PROCESS_TRANSCRIPT] GROQ_API_KEY not set")
        return JSONResponse(
            status_code=500,
            content=_empty_process_response("GROQ_API_KEY not configured"),
        )

    if not payload.text or not payload.text.strip():
        return JSONResponse(
            status_code=400,
            content=_empty_process_response("Text is required"),
        )

    prompt = (
        "You are an AI note-taking assistant.\n\n"
        "Clean and improve the following lecture transcript:\n\n"
        "* Remove repeated words\n"
        "* Fix grammar\n"
        "* Convert into clear sentences\n"
        "* Create a short summary\n"
        "* Extract key points\n\n"
        "Return JSON in this format:\n"
        "{\n"
        '"clean_text": "...",\n'
        '"summary": "...",\n'
        '"key_points": ["...", "..."]\n'
        "}\n\n"
        "Transcript:\n"
        f"{payload.text}"
    )

    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type": "application/json",
    }
    body = {
        "model": GROQ_CHAT_MODEL,
        "messages": [
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.2,
    }

    try:
        logger.debug("[PROCESS_TRANSCRIPT] Sending to Groq chat completion API...")
        response = requests.post(
            GROQ_CHAT_ENDPOINT,
            headers=headers,
            json=body,
            timeout=45,
        )

        logger.debug(f"[PROCESS_TRANSCRIPT] Groq response status: {response.status_code}")

        if response.status_code != 200:
            logger.error(f"[PROCESS_TRANSCRIPT] Groq error: {response.text}")
            return JSONResponse(
                status_code=response.status_code,
                content=_empty_process_response("Groq API failed"),
            )

        result = response.json()
        choices = result.get("choices", [])
        if not choices:
            raise ValueError("Missing choices in Groq response")

        message = choices[0].get("message", {})
        content = message.get("content", "")
        if not content:
            raise ValueError("Empty content in Groq response")

        parsed = _extract_json_object(content)
        normalized = _normalize_process_response(parsed)
        return JSONResponse(normalized)

    except Exception as e:
        logger.error(f"[PROCESS_TRANSCRIPT] Exception: {str(e)}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content=_empty_process_response("Failed to process transcript"),
        )


async def generate_notes_with_gemini(text: str, mode: str, is_retry: bool = False) -> dict:
    gemini_key = os.getenv("GEMINI_API_KEY")
    if not gemini_key:
        raise ValueError("GEMINI_API_KEY not configured")

    gemini_client = genai.Client(api_key=gemini_key)
    
    normalized_mode = (mode or "exam").strip().lower()
    if normalized_mode not in {"beginner", "exam", "panic"}:
        normalized_mode = "exam"

    mode_labels = {
        "beginner": "Beginner",
        "exam": "Exam",
        "panic": "Panic",
    }

    output_format_by_mode = {
        "beginner": (
            "🧠 Simple Explanation:\n"
            "(Explain clearly in easy words)\n\n"
            "📌 Key Concepts:\n"
            "* Point 1\n"
            "* Point 2\n"
            "* Point 3\n\n"
            "🌍 Real-Life Example:\n"
            "(Relatable example)\n\n"
            "⚡ Quick Summary:\n"
            "(2–3 lines)\n\n"
            "📝 Practice Questions:\n"
            "1. Easy question\n"
            "2. Easy question\n"
            "3. Easy question"
        ),
        "exam": (
            "🎯 Important Topics (Ranked):\n"
            "1. Topic\n"
            "2. Topic\n"
            "3. Topic\n\n"
            "📖 Key Definitions:\n"
            "* Definition 1\n"
            "* Definition 2\n\n"
            "❓ Important Questions:\n"
            "1. Question\n"
            "2. Question\n"
            "3. Question\n\n"
            "🧩 Answer Framework:\n"
            "(How to write answers in exam)\n\n"
            "⚡ Revision Sheet:\n"
            "* Bullet points only"
        ),
        "panic": (
            "🚨 Ultra Short Summary:\n"
            "(max 5 lines)\n\n"
            "📌 Must Remember:\n"
            "* Point 1\n"
            "* Point 2\n\n"
            "🔑 Keywords / Formulas:\n"
            "* keyword1\n"
            "* keyword2\n\n"
            "⚡ 30-Second Revision Trick:\n"
            "(memory shortcut)\n\n"
            "❓ Likely Questions:\n"
            "1. Question\n"
            "2. Question\n"
            "3. Question"
        ),
    }

    prompt = f"""You are an intelligent adaptive learning assistant integrated into a smart notes application.

Your task is to transform a student's selected note into a structured learning output based on the selected mode.

INPUT PARAMETERS:
Mode: {mode_labels[normalized_mode]}
Note Content:
{text}

CORE INSTRUCTIONS:
1. You MUST strictly adapt your response based on the selected mode:
   - Beginner -> Deep understanding, simple explanations
   - Exam -> High-scoring, structured, important points only
   - Panic -> Ultra-fast revision, compressed content
2. You MUST always:
   - Use clean formatting
   - Break content into sections
   - Avoid unnecessary fluff
   - Stay relevant to the note content only
3. If the note is unclear or incomplete:
   - Infer intelligently
   - Do NOT say "insufficient data"

MODE-SPECIFIC BEHAVIOR FOR CURRENT MODE ({mode_labels[normalized_mode]}):
{output_format_by_mode[normalized_mode]}

IMPORTANT RULES:
- DO NOT mix modes
- DO NOT give generic responses
- ALWAYS base output on the provided note
- Keep formatting clean and readable
- Do not use HTML/XML tags (such as <h1>, <li>, <p>) and do not use markdown emphasis markers like ** or __ in the final content text
- Be accurate and concise

FINAL INSTRUCTION:
Generate the best possible output for the selected mode using the given note.

Return ONLY valid JSON. No markdown code fences.
JSON schema:
{{
  "title": "A short mode-aware title",
  "content": "The full formatted learning output matching the current mode exactly",
  "key_points": ["5 to 8 concise high-value bullets extracted from the note and response"]
}}"""

    def _generate_notes_with_groq_fallback() -> dict:
        if not GROQ_API_KEY:
            raise ValueError("GROQ_API_KEY not configured for fallback")

        headers = {
            "Authorization": f"Bearer {GROQ_API_KEY}",
            "Content-Type": "application/json",
        }
        body = {
            "model": GROQ_CHAT_MODEL,
            "messages": [
                {"role": "user", "content": prompt},
            ],
            "temperature": 0.3,
            "response_format": {"type": "json_object"},
        }

        response = requests.post(
            GROQ_CHAT_ENDPOINT,
            headers=headers,
            json=body,
            timeout=45,
        )

        if response.status_code != 200:
            raise ValueError(f"Groq fallback failed: {response.status_code} - {response.text}")

        data = response.json()
        choices = data.get("choices", [])
        if not choices:
            raise ValueError("Groq fallback returned no choices")

        message = choices[0].get("message", {})
        content = message.get("content", "")
        parsed = _extract_json_object(content)

        title = str(parsed.get("title") or "Generated Notes")
        body_text = str(parsed.get("content") or "")
        key_points_raw = parsed.get("key_points", [])
        if isinstance(key_points_raw, list):
            key_points = [str(point) for point in key_points_raw if str(point).strip()]
        elif key_points_raw:
            key_points = [str(key_points_raw)]
        else:
            key_points = []

        return {
            "title": title,
            "content": body_text,
            "key_points": key_points,
        }

    if _is_gemini_disabled():
        logger.info("[GENERATE_NOTES] Gemini cooldown active, using Groq fallback directly")
        try:
            return _generate_notes_with_groq_fallback()
        except Exception as groq_error:
            logger.error(f"[GENERATE_NOTES] Groq fallback failed during Gemini cooldown: {groq_error}")
            return {
                "title": "Notes Unavailable",
                "content": "We couldn't generate notes at this time. Please try again.",
                "key_points": [],
            }

    attempts = 2 if not is_retry else 1
    last_error: Optional[Exception] = None

    for attempt in range(attempts):
        for model_name in _gemini_model_candidates():
            try:
                response_text = await asyncio.to_thread(
                    _generate_gemini_response_text,
                    gemini_client,
                    model_name,
                    prompt,
                )
                if not response_text:
                    raise ValueError("Gemini returned an empty response")

                if response_text.startswith("```json"):
                    response_text = response_text[7:]
                if response_text.startswith("```"):
                    response_text = response_text[3:]
                if response_text.endswith("```"):
                    response_text = response_text[:-3]

                response_text = response_text.strip()
                parsed = json.loads(response_text)
                if not isinstance(parsed, dict):
                    raise ValueError("Gemini response is not a JSON object")

                logger.info(
                    f"[GENERATE_NOTES] Success with model: {model_name} (attempt {attempt + 1})"
                )
                return parsed
            except Exception as e:
                last_error = e
                error_text = str(e).lower()
                if "quota exceeded" in error_text or "not found for api version" in error_text:
                    _disable_gemini_temporarily(str(e))
                    logger.info(
                        "[GENERATE_NOTES] Switching to Groq fallback immediately after Gemini availability failure"
                    )
                    try:
                        return _generate_notes_with_groq_fallback()
                    except Exception as groq_error:
                        logger.error(
                            f"[GENERATE_NOTES] Groq fallback failed after Gemini availability failure: {groq_error}"
                        )
                logger.warning(
                    f"[GENERATE_NOTES] Model {model_name} failed on attempt {attempt + 1}: {e}"
                )

    logger.warning(f"[GENERATE_NOTES] All Gemini model attempts failed: {last_error}")

    try:
        logger.info("[GENERATE_NOTES] Falling back to Groq for adaptive notes generation")
        return _generate_notes_with_groq_fallback()
    except Exception as groq_error:
        logger.error(f"[GENERATE_NOTES] Groq fallback failed: {groq_error}")
        return {
            "title": "Notes Unavailable",
            "content": "We couldn't generate notes at this time. Please try again.",
            "key_points": [],
        }


@app.post("/generate-notes")
async def generate_notes_endpoint(payload: GenerateNotesRequest):
    if not payload.text or not payload.text.strip():
        return JSONResponse(
            status_code=400,
            content={"error": "Text is required and cannot be empty"}
        )

    logger.info(f"[GENERATE_NOTES] MODE: {payload.mode}")
    print(f"[GENERATE_NOTES] MODE: {payload.mode}")  # visible in terminal

    try:
        result = await generate_notes_with_gemini(payload.text, payload.mode)
        return JSONResponse(status_code=200, content=result)
    except Exception as e:
        logger.error(f"[GENERATE_NOTES] Exception: {str(e)}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"error": str(e)}
        )


@app.post("/process-ocr-text")
async def process_ocr_text(payload: ProcessTranscriptRequest):
    """
    Clean and structure OCR output (especially handwriting) using Groq Chat API.

    Input:
        {"text": "raw OCR text"}
    """
    if not GROQ_API_KEY:
        logger.error("[PROCESS_OCR_TEXT] GROQ_API_KEY not set")
        return JSONResponse(
            status_code=500,
            content=_empty_process_response("GROQ_API_KEY not configured"),
        )

    if not payload.text or not payload.text.strip():
        return JSONResponse(
            status_code=400,
            content=_empty_process_response("Text is required"),
        )

    prompt = (
        "You are given OCR text extracted from handwritten notes.\\n\\n"
        "The OCR may contain: broken words, missing spaces, wrong spellings, random layout noise, "
        "labels like Date:, and orientation artifacts.\\n\\n"
        "Your job:\\n"
        "1. Reconstruct meaningful sentences from the OCR text\\n"
        "2. Fix spelling and grammar\\n"
        "3. Merge split words and split merged words\\n"
        "4. Remove irrelevant noise and metadata labels when not part of content\\n"
        "5. Preserve original meaning and technical terms\\n\\n"
        "Rules:\\n"
        "* Do not invent facts\\n"
        "* If uncertain, prefer the most likely classroom meaning\\n"
        "* Keep output concise and readable\\n\\n"
        "Return strict JSON in this format:\\n"
        "{\\n"
        '"clean_text": "...",\\n'
        '"summary": "...",\\n'
        '"key_points": ["...", "..."]\\n'
        "}\\n\\n"
        "OCR Text:\\n"
        f"{payload.text}"
    )

    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type": "application/json",
    }
    body = {
        "model": GROQ_CHAT_MODEL,
        "messages": [
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.1,
    }

    try:
        logger.debug("[PROCESS_OCR_TEXT] Sending to Groq chat completion API...")
        response = requests.post(
            GROQ_CHAT_ENDPOINT,
            headers=headers,
            json=body,
            timeout=45,
        )

        logger.debug(f"[PROCESS_OCR_TEXT] Groq response status: {response.status_code}")

        if response.status_code != 200:
            logger.error(f"[PROCESS_OCR_TEXT] Groq error: {response.text}")
            return JSONResponse(
                status_code=response.status_code,
                content=_empty_process_response("Groq API failed"),
            )

        result = response.json()
        choices = result.get("choices", [])
        if not choices:
            raise ValueError("Missing choices in Groq response")

        message = choices[0].get("message", {})
        content = message.get("content", "")
        if not content:
            raise ValueError("Empty content in Groq response")

        parsed = _extract_json_object(content)
        normalized = _normalize_process_response(parsed)
        return JSONResponse(normalized)

    except Exception as e:
        logger.error(f"[PROCESS_OCR_TEXT] Exception: {str(e)}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content=_empty_process_response("Failed to process OCR text"),
        )


@app.post("/process-image")
async def process_image(request: Request, file: Optional[UploadFile] = File(default=None)):
    """
    Extract and clean text directly from image using Groq Vision.

    Accepts:
      - Multipart: file=<image>
      - JSON: {"imageBase64": "..."}
    """
    if not GROQ_API_KEY:
        logger.error("[PROCESS_IMAGE] GROQ_API_KEY not set")
        return JSONResponse(
            status_code=500,
            content={"error": "GROQ_API_KEY not configured", "text": ""},
        )

    image_base64 = ""
    image_mime = "image/jpeg"

    try:
        if file is not None:
            content = await file.read()
            if not content:
                return JSONResponse(
                    status_code=400,
                    content={"error": "Empty image file", "text": ""},
                )
            if len(content) > MAX_UPLOAD_SIZE_BYTES:
                logger.warning(
                    f"[PROCESS_IMAGE] File too large: {len(content)} bytes ({file.filename})"
                )
                return _file_too_large_response()
            image_base64 = base64.b64encode(content).decode("utf-8")
            image_mime = file.content_type or "image/jpeg"
        else:
            payload = await request.json()
            image_base64 = str(payload.get("imageBase64", "")).strip()
            if image_base64.startswith("data:") and "," in image_base64:
                header, raw = image_base64.split(",", 1)
                image_base64 = raw
                mime_match = re.match(r"data:([^;]+);base64", header)
                if mime_match:
                    image_mime = mime_match.group(1)

            try:
                decoded_bytes = base64.b64decode(image_base64, validate=True)
            except Exception:
                decoded_bytes = b""

            if len(decoded_bytes) > MAX_UPLOAD_SIZE_BYTES:
                logger.warning(
                    f"[PROCESS_IMAGE] Base64 payload too large: {len(decoded_bytes)} bytes"
                )
                return _file_too_large_response()

        if not image_base64:
            return JSONResponse(
                status_code=400,
                content={"error": "Image payload is required", "text": ""},
            )
    except Exception as e:
        logger.error(f"[PROCESS_IMAGE] Invalid request payload: {e}")
        return JSONResponse(
            status_code=400,
            content={"error": "Invalid image payload", "text": ""},
        )

    prompt = (
        "You are given an image of handwritten or printed notes.\\n\\n"
        "Your tasks:\\n"
        "1. Extract all readable text from the image.\\n"
        "2. Correct OCR errors (spelling, spacing, broken words).\\n"
        "3. Reconstruct proper sentences.\\n"
        "4. Ignore noise like lines, borders, or irrelevant symbols.\\n"
        "5. Preserve meaning exactly.\\n\\n"
        "Return ONLY clean readable text."
    )

    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type": "application/json",
    }
    body = {
        "model": GROQ_VISION_MODEL,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:{image_mime};base64,{image_base64}",
                        },
                    },
                ],
            }
        ],
        "temperature": 0.1,
        "max_tokens": 1200,
    }

    try:
        logger.debug("[PROCESS_IMAGE] Sending image to Groq Vision...")
        response = requests.post(
            GROQ_CHAT_ENDPOINT,
            headers=headers,
            json=body,
            timeout=60,
        )

        logger.debug(f"[PROCESS_IMAGE] Groq response status: {response.status_code}")

        if response.status_code != 200:
            logger.error(f"[PROCESS_IMAGE] Groq error: {response.text}")
            return JSONResponse(
                status_code=response.status_code,
                content={"error": "Groq Vision API failed", "text": ""},
            )

        result = response.json()
        choices = result.get("choices", [])
        if not choices:
            raise ValueError("Missing choices in Groq response")

        content = str(choices[0].get("message", {}).get("content", "")).strip()
        return JSONResponse({"text": content})
    except Exception as e:
        logger.error(f"[PROCESS_IMAGE] Exception: {str(e)}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"error": "Failed to process image", "text": ""},
        )


def _serialize_note_document(note: dict) -> dict:
    serialized = dict(note)

    if "_id" in serialized:
        serialized["_id"] = str(serialized["_id"])
    if "userId" in serialized:
        serialized["userId"] = str(serialized["userId"])

    created_at = serialized.get("createdAt")
    if isinstance(created_at, datetime):
        serialized["createdAt"] = created_at.isoformat()

    updated_at = serialized.get("updatedAt")
    if isinstance(updated_at, datetime):
        serialized["updatedAt"] = updated_at.isoformat()

    return serialized


@app.get("/api/notes")
async def get_all_notes():
    if notes_collection is None:
        logger.error("[GET_NOTES] MongoDB not available")
        return JSONResponse(
            status_code=500,
            content={"error": "Database connection failed"},
        )

    try:
        notes = list(notes_collection.find().sort("createdAt", -1))
        serialized_notes = [_serialize_note_document(note) for note in notes]
        return JSONResponse(serialized_notes)
    except Exception as e:
        logger.error(f"[GET_NOTES] Exception: {str(e)}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"error": "Failed to fetch notes"},
        )


@app.get("/api/notes/{user_id}")
async def get_user_notes(user_id: str):
    if notes_collection is None:
        logger.error("[GET_USER_NOTES] MongoDB not available")
        return JSONResponse(
            status_code=500,
            content={"success": False, "message": "Database connection failed"},
        )

    if not ObjectId.is_valid(user_id):
        return JSONResponse(
            status_code=400,
            content={"success": False, "message": "Invalid User ID"},
        )

    try:
        notes = list(
            notes_collection.find({"userId": ObjectId(user_id)}).sort("createdAt", -1)
        )
        serialized_notes = [_serialize_note_document(note) for note in notes]
        return JSONResponse(
            {
                "success": True,
                "data": serialized_notes,
            }
        )
    except Exception as e:
        logger.error(f"[GET_USER_NOTES] Exception: {str(e)}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"success": False, "message": "Failed to fetch notes"},
        )


@app.post("/save-transcript")
async def save_transcript(payload: SaveTranscriptRequest):
    """
    Save a processed transcript to MongoDB.
    
    Input:
        {
            "userId": "user_id",
            "title": "Lecture Title",
            "subject": "Subject Name",
            "rawText": "original transcript",
            "cleanText": "cleaned text",
            "summary": "summary",
            "keyPoints": ["point1", "point2"]
        }
    """
    if notes_collection is None:
        logger.error("[SAVE_TRANSCRIPT] MongoDB not available")
        return JSONResponse(
            status_code=500,
            content={"error": "Database connection failed"}
        )
    
    try:
        # Validate required fields
        if not payload.userId or not payload.title:
            return JSONResponse(
                status_code=400,
                content={"error": "userId and title are required"}
            )
        
        # Create note document
        note_doc = {
            "userId": ObjectId(payload.userId),
            "title": payload.title,
            "subject": payload.subject,
            "content": payload.rawText,
            "cleanedText": payload.cleanText,
            "summary": payload.summary,
            "keyPoints": payload.keyPoints,
            "createdAt": _utc_now(),
            "updatedAt": _utc_now(),
        }
        
        # Insert into MongoDB
        result = notes_collection.insert_one(note_doc)
        
        logger.info(f"[SAVE_TRANSCRIPT] Saved transcript {result.inserted_id} for user {payload.userId}")
        
        return JSONResponse({
            "success": True,
            "noteId": str(result.inserted_id),
            "message": "Transcript saved successfully"
        })
    
    except Exception as e:
        logger.error(f"[SAVE_TRANSCRIPT] Exception: {str(e)}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"error": str(e)}
        )


@app.post("/process-and-save-transcript")
async def process_and_save_transcript(payload: SaveTranscriptRequest):
    """
    Process a raw transcript AND save it to MongoDB in one call.
    
    Input:
        {
            "userId": "user_id",
            "title": "Lecture Title",
            "subject": "Subject Name",
            "rawText": "original transcript",
            "cleanText": "",
            "summary": "",
            "keyPoints": []
        }
    """
    if not GROQ_API_KEY:
        logger.error("[PROCESS_AND_SAVE] GROQ_API_KEY not set")
        return JSONResponse(
            status_code=500,
            content={"error": "GROQ_API_KEY not configured"}
        )
    
    if not payload.rawText or not payload.rawText.strip():
        return JSONResponse(
            status_code=400,
            content={"error": "rawText is required"}
        )

    # Step 1: Process the transcript
    prompt = (
        "You are an AI note-taking assistant.\n\n"
        "Clean and improve the following lecture transcript:\n\n"
        "* Remove repeated words\n"
        "* Fix grammar\n"
        "* Convert into clear sentences\n"
        "* Create a short summary\n"
        "* Extract key points\n\n"
        "Return JSON in this format:\n"
        "{\n"
        '"clean_text": "...",\n'
        '"summary": "...",\n'
        '"key_points": ["...", "..."]\n'
        "}\n\n"
        "Transcript:\n"
        f"{payload.rawText}"
    )

    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type": "application/json",
    }
    body = {
        "model": GROQ_CHAT_MODEL,
        "messages": [
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.2,
    }

    try:
        logger.debug("[PROCESS_AND_SAVE] Processing transcript...")
        response = requests.post(
            GROQ_CHAT_ENDPOINT,
            headers=headers,
            json=body,
            timeout=45,
        )

        if response.status_code != 200:
            logger.error(f"[PROCESS_AND_SAVE] Groq error: {response.text}")
            return JSONResponse(
                status_code=response.status_code,
                content={"error": "Failed to process transcript"}
            )

        result = response.json()
        choices = result.get("choices", [])
        if not choices:
            raise ValueError("Missing choices in Groq response")

        message = choices[0].get("message", {})
        content = message.get("content", "")
        if not content:
            raise ValueError("Empty content in Groq response")

        parsed = _extract_json_object(content)
        normalized = _normalize_process_response(parsed)

        # Step 2: Save to MongoDB
        if notes_collection is None:
            logger.error("[PROCESS_AND_SAVE] MongoDB not available")
            return JSONResponse(
                status_code=500,
                content={"error": "Database connection failed"}
            )
        
        note_doc = {
            "userId": ObjectId(payload.userId),
            "title": payload.title,
            "subject": payload.subject,
            "content": payload.rawText,
            "cleanedText": normalized["clean_text"],
            "summary": normalized["summary"],
            "keyPoints": normalized["key_points"],
            "createdAt": _utc_now(),
            "updatedAt": _utc_now(),
        }
        
        save_result = notes_collection.insert_one(note_doc)
        
        logger.info(f"[PROCESS_AND_SAVE] Saved and processed transcript {save_result.inserted_id}")
        
        return JSONResponse({
            "success": True,
            "noteId": str(save_result.inserted_id),
            "cleanText": normalized["clean_text"],
            "summary": normalized["summary"],
            "keyPoints": normalized["key_points"],
            "message": "Transcript processed and saved successfully"
        })

    except Exception as e:
        logger.error(f"[PROCESS_AND_SAVE] Exception: {str(e)}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"error": str(e)}
        )


@app.put("/update-note/{note_id}")
async def update_note(note_id: str, payload: SaveTranscriptRequest):
    """
    Update an existing note in MongoDB.
    
    Input:
        {
            "userId": "user_id",
            "title": "Updated Title",
            "subject": "Updated Subject",
            "rawText": "updated raw text",
            "cleanText": "updated cleaned text",
            "summary": "updated summary",
            "keyPoints": ["updated", "points"]
        }
    """
    if notes_collection is None:
        logger.error("[UPDATE] MongoDB not available")
        return JSONResponse(
            status_code=500,
            content={"error": "Database not available"}
        )

    try:
        logger.info(f"[UPDATE] Updating note {note_id}")

        result = notes_collection.update_one(
            {"_id": ObjectId(note_id)},
            {
                "$set": {
                    "title": payload.title,
                    "subject": payload.subject,
                    "content": payload.rawText,
                    "cleanedText": payload.cleanText,
                    "summary": payload.summary,
                    "keyPoints": payload.keyPoints,
                    "updatedAt": _utc_now(),
                }
            }
        )

        logger.info(f"[UPDATE] Modified count: {result.modified_count}")

        return JSONResponse({
            "success": True,
            "modified_count": result.modified_count,
            "message": "Note updated successfully"
        })

    except Exception as e:
        logger.error(f"[UPDATE] Exception: {str(e)}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"error": str(e)}
        )


@app.post("/submit-feedback")
async def submit_feedback(payload: FeedbackRequest):
    """
    Submit feedback from users. Saves to MongoDB feedback collection.
    
    Input:
        {
            "name": "User Name (optional)",
            "email": "user@example.com (optional)",
            "feedback": "Feedback message (required)",
            "userId": "user_id (optional)"
        }
    """
    if not payload.feedback or not payload.feedback.strip():
        return JSONResponse(
            status_code=400,
            content={"error": "Feedback message is required"}
        )

    if db is None:
        return JSONResponse(
            status_code=500,
            content={"error": "Database connection failed"}
        )

    try:
        feedback_collection = db['feedback']
        
        feedback_doc = {
            "name": payload.name.strip() if payload.name else "",
            "email": payload.email.strip() if payload.email else "",
            "feedback": payload.feedback.strip(),
            "userId": payload.userId.strip() if payload.userId else "",
            "submittedAt": _utc_now(),
        }
        
        result = feedback_collection.insert_one(feedback_doc)
        
        logger.info(f"[FEEDBACK] Feedback saved with ID: {result.inserted_id}")
        
        return JSONResponse(
            status_code=200,
            content={
                "message": "Feedback submitted successfully",
                "feedbackId": str(result.inserted_id),
            }
        )
    except Exception as e:
        logger.error(f"[FEEDBACK] Exception: {str(e)}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"error": f"Failed to submit feedback: {str(e)}"}
        )


if __name__ == "__main__":
    import uvicorn
    host = os.getenv("HOST", "0.0.0.0")
    preferred_port = int(os.getenv("FASTAPI_PORT", 8001))

    def _find_free_port(start_port: int, bind_host: str) -> int:
        for candidate in range(start_port, 65536):
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
                sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
                try:
                    sock.bind((bind_host, candidate))
                except OSError:
                    continue
                return candidate
        raise RuntimeError(f"No free port available from {start_port} to 65535")

    port = _find_free_port(preferred_port, host)
    logger.info(f"Starting FastAPI server on {host}:{port}")
    uvicorn.run(app, host=host, port=port, log_level="debug")
