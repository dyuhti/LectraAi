import os
import tempfile
import logging
import json
import re
import secrets
import smtplib
from typing import Optional
from datetime import datetime, timedelta
from email.message import EmailMessage
from pathlib import Path
from dotenv import load_dotenv
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import bcrypt
import requests
from pymongo import MongoClient
from bson.objectid import ObjectId

# Load environment variables from backend/.env regardless of current working directory
BASE_DIR = Path(__file__).resolve().parent
load_dotenv(dotenv_path=BASE_DIR / ".env")

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

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
    expires_at = datetime.utcnow() + timedelta(minutes=OTP_EXPIRY_MINUTES)

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

    if not isinstance(expires_at, datetime) or datetime.utcnow() > expires_at:
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

    if not isinstance(expires_at, datetime) or datetime.utcnow() > expires_at:
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
                "updatedAt": datetime.utcnow(),
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
        with tempfile.NamedTemporaryFile(
            suffix=".wav", delete=False, dir=tempfile.gettempdir()
        ) as temp_file:
            content = await file.read()
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
            "createdAt": datetime.utcnow(),
            "updatedAt": datetime.utcnow(),
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
            "createdAt": datetime.utcnow(),
            "updatedAt": datetime.utcnow(),
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
                    "updatedAt": datetime.utcnow(),
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
            "submittedAt": datetime.utcnow(),
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
    port = int(os.getenv("FASTAPI_PORT", 8001))
    host = os.getenv("HOST", "0.0.0.0")
    logger.info(f"Starting FastAPI server on {host}:{port}")
    uvicorn.run(app, host=host, port=port, log_level="debug")
