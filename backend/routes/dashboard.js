const express = require('express');
const mongoose = require('mongoose');
const StudyDashboard = require('../models/StudyDashboard');
const DailyProgress = require('../models/DailyProgress');

const router = express.Router();

/**
 * Helper to sync dashboard for a user
 * Reads from dailyprogresses and calculates scores for studydashboards
 */
const syncStudyDashboard = async (userId) => {
  // Generate last 7 days array (YYYY-MM-DD)
  const today = new Date();
  const last7Days = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date(today);
    d.setDate(today.getDate() - i);
    const dateStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    last7Days.push(dateStr);
  }

  // Fetch raw data from dailyprogresses
  const rawData = await DailyProgress.find({
    userId,
    date: { $in: last7Days }
  }).lean();

  // For each day, calculate and upsert
  for (const date of last7Days) {
    const dayData = rawData.find(r => r.date === date);
    
    let score = 0;
    if (dayData) {
      // BACKEND CALCULATION LOGIC
      score = (dayData.notesCreated * 10) +
              (dayData.audioRecorded * 5) +
              (dayData.quizzesGenerated * 7) +
              dayData.studyTime;
    }

    await StudyDashboard.findOneAndUpdate(
      { userId: new mongoose.Types.ObjectId(userId), date },
      { 
        progressScore: score,
        updatedAt: new Date()
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
  }
};

/**
 * POST /api/dashboard/sync/:userId
 * Triggers re-calculation of dashboard scores from raw data
 */
router.post('/sync/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ error: 'Invalid User ID' });
    }

    await syncStudyDashboard(userId);
    
    console.log(`[DASHBOARD] Sync complete for user ${userId}`);
    res.json({ message: 'Dashboard synchronized successfully' });
  } catch (error) {
    console.error('[DASHBOARD] Sync error:', error);
    res.status(500).json({ error: 'Failed to sync dashboard' });
  }
});

/**
 * GET /api/dashboard/weekly/:userId
 * Returns exactly 7 days of data from studydashboards collection
 */
router.get('/weekly/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ error: 'Invalid User ID' });
    }

    const today = new Date();
    const last7Days = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(today);
      d.setDate(today.getDate() - i);
      const dateStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
      last7Days.push(dateStr);
    }

    const [dashboardRecords, rawRecords] = await Promise.all([
      StudyDashboard.find({ userId, date: { $in: last7Days } }).lean(),
      DailyProgress.find({ userId, date: { $in: last7Days } }).lean()
    ]);

    const result = last7Days.map(date => {
      const dashboard = dashboardRecords.find(r => r.date === date);
      const raw = rawRecords.find(r => r.date === date);
      return {
        date,
        progressScore: dashboard ? dashboard.progressScore : 0,
        notesCreated: raw ? raw.notesCreated : 0,
        audioRecorded: raw ? raw.audioRecorded : 0,
        quizzesGenerated: raw ? raw.quizzesGenerated : 0,
        studyTime: raw ? raw.studyTime : 0
      };
    });

    res.json(result);
  } catch (error) {
    console.error('[DASHBOARD] Error fetching weekly dashboard:', error);
    res.status(500).json({ error: 'Failed to fetch weekly dashboard data' });
  }
});

module.exports = router;
