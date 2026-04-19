import os
import tempfile
import logging
import json
from dotenv import load_dotenv
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import requests

# Load environment variables from .env file
load_dotenv(dotenv_path=".env")

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
GROQ_CHAT_MODEL = os.getenv("GROQ_CHAT_MODEL", "mixtral-8x7b-32768")


class ProcessTranscriptRequest(BaseModel):
    text: str


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


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("FASTAPI_PORT", 8001))
    host = os.getenv("HOST", "0.0.0.0")
    logger.info(f"Starting FastAPI server on {host}:{port}")
    uvicorn.run(app, host=host, port=port, log_level="debug")
