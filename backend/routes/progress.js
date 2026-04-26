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

/**
 * POST /api/progress/update
 * Updates daily progress with type and duration
 */
const { updateDailyProgress } = require('../services/progressService');
router.post('/update', async (req, res) => {
  try {
    const { userId, type, duration } = req.body;

    if (!userId || !type) {
      return res.status(400).json({ error: 'User ID and type are required' });
    }

    await updateDailyProgress(userId, type, duration);
    res.json({ message: 'Progress updated successfully' });
  } catch (error) {
    console.error('[PROGRESS] Error updating progress:', error);
    res.status(500).json({ error: 'Failed to update progress' });
  }
});

/**
 * GET /api/progress/weekly/:userId
 * Returns last 7 days of progress for a user
 */
router.get('/weekly/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ error: 'Invalid User ID' });
    }

    // Generate last 7 days array
    const today = new Date();
    const last7Days = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(today);
      d.setDate(today.getDate() - i);
      const dateStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
      last7Days.push(dateStr);
    }

    // Find all records within this range
    const history = await DailyProgress.find({
      userId,
      date: { $in: last7Days }
    }).lean();

    // Map existing data to the 7 days array
    const result = last7Days.map(date => {
      const record = history.find(h => h.date === date);
      if (record) return record;
      return {
        userId,
        date,
        notesCreated: 0,
        audioRecorded: 0,
        quizzesGenerated: 0,
        studyTime: 0
      };
    });

    res.json(result);
  } catch (error) {
    console.error('[PROGRESS] Error fetching weekly progress:', error);
    res.status(500).json({ error: 'Failed to fetch weekly progress' });
  }
});

module.exports = router;
