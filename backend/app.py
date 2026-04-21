import os
import tempfile
import logging
import json
from datetime import datetime
from pathlib import Path
from dotenv import load_dotenv
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
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
    logger.info("✓ MongoDB connected successfully")
except Exception as e:
    logger.warning(f"⚠ MongoDB connection failed: {e}")
    db = None
    notes_collection = None


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
    if not notes_collection:
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
        if not notes_collection:
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
    if not notes_collection:
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


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("FASTAPI_PORT", 8001))
    host = os.getenv("HOST", "0.0.0.0")
    logger.info(f"Starting FastAPI server on {host}:{port}")
    uvicorn.run(app, host=host, port=port, log_level="debug")
