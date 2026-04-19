# Live Transcription Setup Guide

## Architecture

- **Flutter App**: Records audio in 1-second WAV chunks (16 kHz mono)
- **FastAPI Backend** (`app.py`): `/transcribe` endpoint receives multipart audio, calls Groq API
- **Groq API**: Speech-to-text transcription (whisper-large-v3-turbo)
- **Live Flow**: Audio chunk → HTTP POST → Groq → JSON response → UI update

---

## 1. Backend Setup (FastAPI)

### Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

Or manually:

```bash
pip install fastapi uvicorn python-multipart requests python-dotenv
```

### Configure Environment

Edit `backend/.env`:

```
GROQ_API_KEY=your_actual_groq_api_key_from_console.groq.com
HOST=0.0.0.0
FASTAPI_PORT=8000
```

**Get Groq API Key:**
1. Go to https://console.groq.com/
2. Sign up / Log in
3. Create → API Key
4. Copy and paste into `.env`

### Run FastAPI Server

```bash
cd backend
python app.py
```

Or with auto-reload:

```bash
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

**Check health:**

```bash
curl http://localhost:8000/health
# Expected: {"status":"ok"}
```

---

## 2. Flutter Configuration

### Find Your Backend IP

If running on emulator (Android Virtual Device):
- Backend URL: `http://10.0.2.2:8000` (auto-detected)

If running on physical phone:
1. Get your PC's IP:
   ```bash
   ipconfig  # Windows: look for "IPv4 Address"
   # e.g., 192.168.x.x
   ```
2. Ensure phone and PC on **same WiFi**
3. Run Flutter with:
   ```bash
   flutter run --dart-define=TRANSCRIBE_BASE_URL=http://192.168.x.x:8000
   ```

### Build & Run

```bash
cd .  # root directory
flutter pub get
flutter run --dart-define=TRANSCRIBE_BASE_URL=http://10.0.2.2:8000
```

---

## 3. Testing Flow

### Step 1: Open Record Lecture Screen

- Tap **Record Lecture** on home screen
- You should see the microphone card + timer

### Step 2: Start Recording

- Tap the blue microphone button
- You'll see:
  - Timer counting up
  - Waveform animating
  - "Listening..." status in Live Transcript box

### Step 3: Speak Clearly

- Say something like: "This is a test of the speech to text system"
- Audio chunks capture every 1 second

### Step 4: Watch Live Transcript Update

- Check the **Live Transcript** box below the waveform
- Real text should appear within 2-3 seconds
- Text keeps appending as you speak

### Step 5: Stop & Review

- Tap **Stop**
- System waits for pending API calls
- Navigates to **Audio Transcript** screen
- Shows full transcript (not dummy data)
- Tap **Save Note** to save

---

## 4. Debugging

### Enable Console Logs

Look for these log messages:

**Flutter (Xcode/Android Studio console):**

```
[RECORDING] Starting recording...
[RECORDING] Recording started successfully
[CONTROLLER] Processing chunk: /path/to/chunk.wav
[API] Sending audio file: /path/to/chunk.wav
[API] Backend URL: http://10.0.2.2:8000/transcribe
[API] Response status: 200
[API] SUCCESS: Transcribed text: your text here
[CONTROLLER] Updated transcript: your text here
```

**FastAPI (Terminal):**

```
[TRANSCRIBE] Received file: audio_chunk_12345.wav
[TRANSCRIBE] Saved temp file: /tmp/..., size: 12340 bytes
[TRANSCRIBE] Sending to Groq API...
[TRANSCRIBE] Groq response status: 200
[TRANSCRIBE] Extracted text: your text here
```

### Common Issues

#### "Network issue, retrying..."

1. ✅ Backend running? Check: `curl http://10.0.2.2:8000/health`
2. ✅ Correct URL? Should be `http://10.0.2.2:8000` or `http://192.168.x.x:8000`
3. ✅ Same WiFi? Phone and PC on same network?

#### Empty transcript / "Listening for speech..."

1. ✅ Check FastAPI console for errors
2. ✅ Verify `GROQ_API_KEY` in `.env`
3. ✅ Speak loud enough (1-2 feet from phone mic)
4. ✅ Check Groq API status: https://status.groq.com/

#### "Transcription failed"

1. Check FastAPI console for exception
2. Verify audio file is valid WAV (16 kHz, mono)
3. Check Groq API is not rate limited

---

## 5. File Structure

```
backend/
├── app.py                 # FastAPI main app + /transcribe endpoint
├── requirements.txt       # Python dependencies
├── .env                   # API keys (GROQ_API_KEY, etc.)
└── .env.example

lib/
├── services/
│   ├── audio_service.dart            # WAV recording (16 kHz mono)
│   ├── api_service.dart              # HTTP client with debug logs
│   └── transcription_controller.dart  # Chunk loop + overlap trimming
├── screens/
│   ├── recording_screen.dart         # UI with Live Transcript
│   └── audio_transcript_screen.dart  # Final transcript (no dummy)
```

---

## 6. Performance Tips

- **Chunk Duration**: Currently 1 second
  - Adjust in `transcription_controller.dart`: `Duration chunkDuration = const Duration(milliseconds: 1000);`
  - Shorter = more responsive but requires more bandwidth
  - Longer = fewer requests but higher latency

- **Chunk Gap**: 150 ms between recordings
  - Adjust in `transcription_controller.dart`: `Duration chunkGap = const Duration(milliseconds: 150);`

- **Groq Model**: Using `whisper-large-v3-turbo`
  - Faster + cheaper than `whisper-large-v3`
  - Change in `backend/app.py`: `"model": "whisper-large-v3-turbo",`

---

## 7. API Spec

### POST /transcribe

**Request:**
- Method: `POST`
- Content-Type: `multipart/form-data`
- Field name: `file` (WAV audio)

**Response:**
```json
{
  "text": "transcribed speech here"
}
```

**Error Response:**
```json
{
  "error": "error message",
  "text": ""
}
```

---

## 8. Production Deployment

### Option A: Cloud (Recommended)

1. Deploy FastAPI to Render/Railway/Heroku:
   ```bash
   gunicorn -w 4 -k uvicorn.workers.UvicornWorker app:app
   ```

2. Update Flutter `TRANSCRIBE_BASE_URL` to cloud endpoint:
   ```bash
   flutter run --dart-define=TRANSCRIBE_BASE_URL=https://your-api.com
   ```

### Option B: Docker

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## Next Steps

1. ✅ Install dependencies (`pip install -r requirements.txt`)
2. ✅ Get Groq API key
3. ✅ Update `.env`
4. ✅ Start FastAPI server
5. ✅ Run Flutter with correct backend URL
6. ✅ Test end-to-end

**Happy transcribing! 🎤**
