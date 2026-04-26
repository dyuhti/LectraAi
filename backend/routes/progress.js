const express = require('express');
const mongoose = require('mongoose');
const DailyProgress = require('../models/DailyProgress');
const { getTodayDate } = require('../services/progressService');

const router = express.Router();

/**
 * GET /api/progress/:userId
 * Returns today's progress for a user
 */
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ error: 'Invalid User ID' });
    }

    const today = getTodayDate();
    const dashboard = await DailyProgress.findOne({ userId, date: today });

    if (!dashboard) {
      return res.json({
        notesCreated: 0,
        audioRecorded: 0,
        quizzesGenerated: 0,
        studyTime: 0
      });
    }

    console.log('[PROGRESS] Data from DB:', dashboard);

    res.json({
      userId: dashboard.userId,
      date: dashboard.date,
      notesCreated: dashboard.notesCreated,
      audioRecorded: dashboard.audioRecorded,
      quizzesGenerated: dashboard.quizzesGenerated,
      studyTime: dashboard.studyTime
    });
  } catch (error) {
    console.error('[PROGRESS] Error fetching today progress:', error);
    res.status(500).json({ error: 'Failed to fetch progress' });
  }
});

/**
 * GET /api/progress/history/:userId
 * Returns last 7 days of progress
 */
router.get('/history/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ error: 'Invalid User ID' });
    }

    const history = await DailyProgress.find({ userId })
      .sort({ date: -1 })
      .limit(7)
      .lean();

    res.json(history);
  } catch (error) {
    console.error('[PROGRESS] Error fetching history:', error);
    res.status(500).json({ error: 'Failed to fetch history' });
  }
});

module.exports = router;
