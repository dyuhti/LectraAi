const express = require('express');
const { updateDailyProgress } = require('../services/progressService');
const router = express.Router();

/**
 * POST /api/quiz/generate
 * Placeholder for quiz generation logic
 */
router.post('/generate', async (req, res) => {
  try {
    const { userId } = req.body;
    console.log('[QUIZ_API] Generating quiz for user:', userId || 'None');

    if (!userId) return res.status(400).json({ error: 'userId is required' });

    // logic for generating quiz goes here...

    // Update progress
    await updateDailyProgress(userId, 'quiz');
    console.log(`[QUIZ_API] ✅ Progress incremented for user ${userId}`);

    res.json({ success: true, message: 'Quiz generated and progress updated' });
  } catch (error) {
    console.error('[QUIZ_API] Error:', error);
    res.status(500).json({ error: 'Quiz generation failed' });
  }
});

module.exports = router;
