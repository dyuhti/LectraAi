# Real Device Setup - Flutter + FastAPI Live Transcription

## Prerequisites

- ✅ PC with FastAPI backend running (`python app.py`)
- ✅ PC IP: `192.168.0.191`
- ✅ Android phone on same WiFi network
- ✅ Groq API key in `.env`

---

## Step 1: Verify Backend is Running

### On PC Terminal:

```bash
cd c:\Users\Dyuthi\smartnotes\backend
python app.py
```

Expected output:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete
```

### Test Health Endpoint:

```bash
curl http://192.168.0.191:8000/health
```

Expected response:
```json
{"status":"ok"}
```

---

## Step 2: Verify Android Phone Can Reach Backend

### On Android Phone:

1. Open Chrome browser
2. Navigate to: `http://192.168.0.191:8000/health`
3. Should see: `{"status":"ok"}`

**If fails:**
- ✅ Check phone WiFi: Same network as PC?
- ✅ Check PC firewall: Allow port 8000?
- ✅ Check PC IP: Run `ipconfig` on Windows (look for IPv4 Address)

---

## Step 3: Update Flutter App

### Option A: Run with Default IP (192.168.0.191)

```bash
cd c:\Users\Dyuthi\smartnotes
flutter clean
flutter pub get
flutter run
```

**This uses the new default:** `http://192.168.0.191:8000`

### Option B: Run with Custom IP (if PC IP is different)

```bash
flutter run --dart-define=TRANSCRIBE_BASE_URL=http://YOUR_PC_IP:8000
```

Example:
```bash
flutter run --dart-define=TRANSCRIBE_BASE_URL=http://192.168.1.100:8000
```

---

## Step 4: Test Live Transcription

### On Flutter App:

1. **Tap "Record Lecture"**
2. **Tap microphone button** to start
3. **Speak clearly** (e.g., "This is a test of the transcription system")
4. **Watch Live Transcript box** for real-time text
5. **Tap Stop** when done
6. **Verify transcript** appears on next screen (not dummy text)

---

## Step 5: Monitor Logs

### Flutter Console (AndroidStudio / Terminal):

Look for:
```
[API] Backend URL: http://192.168.0.191:8000/transcribe
[API] Sending file: /path/to/chunk.wav
[API] Response status: 200
[API] SUCCESS: Transcribed text: your words here
[CONTROLLER] Updated transcript: your words here
```

### Backend Console (PC Terminal):

Look for:
```
[TRANSCRIBE] Received file: audio_chunk_12345.wav
[TRANSCRIBE] Saved temp file: /tmp/..., size: 12340 bytes
[TRANSCRIBE] Sending to Groq API...
[TRANSCRIBE] Groq response status: 200
[TRANSCRIBE] Extracted text: your words here
```

---

## Troubleshooting

### Issue: "Network issue, retrying..."

**Check 1: Backend Running?**
```bash
curl http://192.168.0.191:8000/health
```
Should return: `{"status":"ok"}`

**Check 2: Phone on Same WiFi?**
- Settings → WiFi → Check connected network
- PC: Settings → Network → Check WiFi name matches

**Check 3: Correct IP?**
- On PC: Run `ipconfig` (find IPv4 Address)
- Verify matches in Flutter logs: `[API] Backend URL: http://XXX.XXX.XXX.XXX:8000/transcribe`

**Check 4: Firewall Blocking?**
- Windows Defender Firewall → Allow app through firewall
- Search "Windows Firewall" → Advanced Settings
- Inbound Rules → New Rule → Port 8000 → Allow

---

### Issue: Empty Transcript / "Listening for speech..."

**Check 1: Groq API Key**
```bash
# In backend/.env, verify:
GROQ_API_KEY=your_actual_key_from_console.groq.com
```

**Check 2: Speak Loud & Clear**
- 1-2 feet from phone microphone
- 2+ seconds of speech minimum

**Check 3: Backend Console Error**
- Check PC terminal for `[TRANSCRIBE]` error messages
- Look for Groq API failures

---

### Issue: "Response status: 500"

**Backend Error:**
1. Check PC terminal for exception
2. Verify `.env` has valid GROQ_API_KEY
3. Check audio file is valid WAV format

---

## File Structure Reference

```
lib/
├── services/
│   ├── api_service.dart               # Default: http://192.168.0.191:8000
│   ├── transcription_controller.dart  # Error handling + retry logic
│   └── audio_service.dart             # WAV recording

backend/
├── app.py                             # FastAPI + /health + /transcribe
├── requirements.txt                   # Dependencies
├── .env                               # GROQ_API_KEY

android/
├── app/src/main/AndroidManifest.xml  # INTERNET permission added
```

---

## Network Configuration Changes

✅ **Updated api_service.dart:**
- Default URL changed from `http://10.0.2.2:8000` → `http://192.168.0.191:8000`
- Still supports `--dart-define=TRANSCRIBE_BASE_URL=...` override
- Comprehensive debug logging for all network steps

✅ **Updated AndroidManifest.xml:**
- Added: `<uses-permission android:name="android.permission.INTERNET" />`
- Already has: `android:usesCleartextTraffic="true"` (allows HTTP, not HTTPS-only)

✅ **Backend (app.py):**
- Includes GET `/health` endpoint for connectivity testing
- POST `/transcribe` with multipart file upload ("file" field)
- CORS enabled for Flutter requests

---

## Quick Start Command

```bash
# Terminal 1: Backend (PC)
cd backend
python app.py

# Terminal 2: Flutter App (Phone)
cd ..
flutter run --dart-define=TRANSCRIBE_BASE_URL=http://192.168.0.191:8000
```

Then test on phone:
1. Record Lecture → Tap Mic → Speak → Watch transcript update

**Done! 🎤✨**
