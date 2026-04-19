# Network Connection Test Plan - Real Device

## Pre-Flight Checklist

- [ ] Backend: `python app.py` running on PC (port 8000)
- [ ] PC IP: `192.168.0.191` (or your actual IP)
- [ ] Android phone: Connected to same WiFi network
- [ ] Groq API key: Set in `backend/.env`
- [ ] Android Studio / VS Code: Ready to run Flutter app

---

## Test 1: Backend Health Check

### From PC (Command Prompt):

```bash
curl http://localhost:8000/health
```

Expected:
```json
{"status":"ok"}
```

### From Phone Browser:

1. Open Chrome on phone
2. Enter: `http://192.168.0.191:8000/health`
3. Should display: `{"status":"ok"}`

**Result:** ✅ PASS / ❌ FAIL

---

## Test 2: Network Connectivity (Ping)

### From PC (Command Prompt):

```bash
ipconfig
```

Find your IPv4 Address (e.g., `192.168.0.191`)

### From Phone:

```bash
# In Android Terminal (if available) or test via ping from PC
ping <phone_ip>
```

**Result:** ✅ PASS / ❌ FAIL

---

## Test 3: Multipart File Upload

### From PC (Command Prompt):

```bash
# Create a dummy WAV file or use existing test audio
# Then test multipart upload:

curl -X POST \
  -F "file=@path/to/test.wav" \
  http://localhost:8000/transcribe
```

Expected response:
```json
{"text":"transcribed text here"}
```

**Result:** ✅ PASS / ❌ FAIL

---

## Test 4: Flutter App Connection

### Run Flutter App:

```bash
cd c:\Users\Dyuthi\smartnotes
flutter clean
flutter pub get
flutter run --dart-define=TRANSCRIBE_BASE_URL=http://192.168.0.191:8000
```

### Monitor Console Output:

Watch for initialization logs:
```
[API] Backend URL: http://192.168.0.191:8000/transcribe
```

**Result:** ✅ PASS / ❌ FAIL

---

## Test 5: Live Recording Test

### On Flutter App:

1. **Open "Record Lecture" screen**
2. **Tap microphone button**
3. **Observe console for:**
   ```
   [RECORDING] Starting recording...
   [RECORDING] Recording started successfully
   ```
4. **Speak test phrase:** "This is a test of the live transcription system"
5. **Watch console for:**
   ```
   [CONTROLLER] Processing chunk: /path/to/chunk.wav
   [API] Sending file: /path/to/chunk.wav
   [API] Response status: 200
   [API] SUCCESS: Transcribed text: this is a test of the live transcription system
   ```
6. **Verify in UI:** Live Transcript box shows real text (not "Listening..." or dummy text)
7. **Tap Stop button**
8. **Verify:** AudioTranscriptScreen shows transcript (not placeholder text)

**Result:** ✅ PASS / ❌ FAIL

---

## Test 6: Error Handling

### Simulate Network Failure:

1. **Stop backend:** Kill the `python app.py` process
2. **Start recording in Flutter app**
3. **Observe UI:**
   - Should show "Network issue, retrying..."
   - Recording continues but no transcription updates

4. **Restart backend**
5. **Continue speaking**
6. **Verify:** Transcription resumes after backend comes back online

**Result:** ✅ PASS / ❌ FAIL

---

## Debug Output Reference

### Successful Flow Console Output:

```
[RECORDING] Starting recording...
[RECORDING] Recording started successfully
[CONTROLLER] Processing chunk: /data/user/0/com.example.app/cache/lecture_chunk_1713607200000.wav
[API] Sending file: /data/user/0/com.example.app/cache/lecture_chunk_1713607200000.wav
[API] Backend URL: http://192.168.0.191:8000/transcribe
[API] Multipart request created, sending...
[API] Response status: 200
[API] Response body: {"text":"this is a test"}
[API] SUCCESS: Transcribed text: this is a test
[CONTROLLER] Raw text length: 15
[CONTROLLER] Cleaned text: this is a test
[CONTROLLER] Updated transcript: this is a test
[RECORDING] Stopping recording...
[RECORDING] Final transcript: this is a test
```

### Backend Console Output:

```
INFO:     Uvicorn running on http://0.0.0.0:8000
[TRANSCRIBE] Received file: audio_chunk_1713607200000.wav
[TRANSCRIBE] Saved temp file: /tmp/tmpxyz123.wav, size: 32000 bytes
[TRANSCRIBE] Sending to Groq API...
[TRANSCRIBE] Groq response status: 200
[TRANSCRIBE] Extracted text: this is a test
```

---

## Common Issues & Solutions

### Issue: "Network issue, retrying..."

| Symptom | Check | Solution |
|---------|-------|----------|
| Cannot reach backend | `curl http://192.168.0.191:8000/health` | Start backend: `python app.py` |
| Wrong IP in logs | Backend console shows different IP | Update phone WiFi to correct network |
| Connection timeout | Phone not on same WiFi | Settings → WiFi → Connect to correct network |
| Firewall blocking | Windows Firewall | Advanced Settings → Inbound Rules → Port 8000 |

### Issue: Empty Transcript

| Symptom | Check | Solution |
|---------|-------|----------|
| Silent response | Backend console for errors | Check Groq API key in `.env` |
| "No speech detected" | Speak louder/longer | 2+ seconds, close to mic |
| API error 401 | Groq credentials | Verify GROQ_API_KEY in `.env` from console.groq.com |

### Issue: "Response status: 500"

| Symptom | Check | Solution |
|---------|-------|----------|
| Backend error | Backend console | Check exception message in terminal |
| Invalid WAV | Audio file format | Verify recording creates valid WAV (should auto) |

---

## Configuration Files Modified

✅ **lib/services/api_service.dart**
- Default: `http://10.0.2.2:8000` → `http://192.168.0.191:8000`
- Configurable via: `--dart-define=TRANSCRIBE_BASE_URL=...`

✅ **android/app/src/main/AndroidManifest.xml**
- Added: `<uses-permission android:name="android.permission.INTERNET" />`

✅ **backend/.env**
- Verify: `GROQ_API_KEY=your_key_from_console.groq.com`
- Verify: `HOST=0.0.0.0` (accepts external connections)
- Verify: `FASTAPI_PORT=8000`

---

## Quick Fix Commands

### Backend won't start?

```bash
cd backend
pip install -r requirements.txt  # Install dependencies
python app.py                     # Start server
```

### Flutter app still using old URL?

```bash
flutter clean
flutter pub get
flutter run --dart-define=TRANSCRIBE_BASE_URL=http://192.168.0.191:8000
```

### Need to check PC IP?

```bash
ipconfig  # Windows
# Look for IPv4 Address (e.g., 192.168.0.191)
```

### Test Groq API directly?

```bash
curl -X POST https://api.groq.com/openai/v1/audio/transcriptions \
  -H "Authorization: Bearer YOUR_GROQ_KEY" \
  -F "file=@test.wav" \
  -F "model=whisper-large-v3-turbo"
```

---

## Success Criteria

- ✅ Flutter app connects to backend on real device
- ✅ Live transcript updates in real-time during recording
- ✅ No "Network issue" errors in snackbar
- ✅ Console shows [API] SUCCESS logs
- ✅ Backend shows [TRANSCRIBE] logs
- ✅ Final transcript displayed (not dummy text)
- ✅ Error handling graceful (pauses, resumes when backend available)

---

**Ready to test? Start with Test 1 above!** 🎤
