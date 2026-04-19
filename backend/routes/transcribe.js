const express = require('express');
const fs = require('fs');
const path = require('path');
const router = express.Router();

// Mock Groq API call (replace with actual Groq SDK)
async function transcribeWithGroq(filePath) {
  const GROQ_API_KEY = process.env.GROQ_API_KEY;
  if (!GROQ_API_KEY) {
    throw new Error('GROQ_API_KEY not set');
  }

  // For testing: return mock transcription
  if (process.env.NODE_ENV === 'development') {
    return 'This is a test transcription of the audio chunk.';
  }

  // Real Groq implementation (requires @groq/sdk):
  const Groq = require('groq-sdk');
  const groq = new Groq({ apiKey: GROQ_API_KEY });

  const audioBuffer = fs.readFileSync(filePath);
  const audioFile = new File([audioBuffer], 'audio.wav', { type: 'audio/wav' });

  const response = await groq.audio.transcriptions.create({
    file: audioFile,
    model: 'whisper-large-v3-turbo',
    language: 'en',
  });

  return response.text;
}

// POST /transcribe
router.post('/transcribe', async (req, res) => {
  try {
    // Check if file exists
    if (!req.files || !req.files.file) {
      return res.status(400).json({ error: 'No audio file provided' });
    }

    const audioFile = req.files.file;
    const tempDir = path.join(__dirname, '..', 'temp');

    // Create temp dir if it doesn't exist
    if (!fs.existsSync(tempDir)) {
      fs.mkdirSync(tempDir, { recursive: true });
    }

    const tempPath = path.join(tempDir, `audio_${Date.now()}.wav`);
    await audioFile.mv(tempPath);

    // Transcribe with Groq
    const text = await transcribeWithGroq(tempPath);

    // Clean up temp file
    fs.unlink(tempPath, (err) => {
      if (err) console.error('Failed to delete temp file:', err);
    });

    res.json({ text });
  } catch (error) {
    console.error('Transcription error:', error);
    res.status(500).json({
      error: 'Transcription failed',
      message: error.message,
    });
  }
});

module.exports = router;
