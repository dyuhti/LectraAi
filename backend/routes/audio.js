const express = require('express');
const { updateDailyProgress } = require('../services/progressService');
const router = express.Router();

/**
 * POST /api/audio/process
 * Placeholder for audio processing logic
 */
router.post('/process', async (req, res) => {
  try {
    const { userId } = req.body;
    console.log('[AUDIO_API] Processing audio for user:', userId || 'None');

    if (!userId) return res.status(400).json({ error: 'userId is required' });

    // logic for processing audio goes here...

    // Update progress
    await updateDailyProgress(userId, 'audio');
    console.log(`[AUDIO_API] ✅ Progress incremented for user ${userId}`);

    res.json({ success: true, message: 'Audio processed and progress updated' });
  } catch (error) {
    console.error('[AUDIO_API] Error:', error);
    res.status(500).json({ error: 'Audio processing failed' });
  }
});

module.exports = router;
