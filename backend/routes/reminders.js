const express = require('express');
const mongoose = require('mongoose');
const RevisionReminder = require('../models/RevisionReminder');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

/**
 * @route POST /api/reminders/create
 * @desc Create a new revision reminder
 */
router.post('/create', requireAuth, async (req, res) => {
  try {
    const { title, description, reminderDateTime, noteId, repeat } = req.body;
    const userId = req.userId;

    if (!title) {
      return res.status(400).json({ success: false, message: 'Title is required' });
    }
    if (!reminderDateTime) {
      return res.status(400).json({ success: false, message: 'Reminder date/time is required' });
    }

    const reminder = new RevisionReminder({
      userId,
      noteId: noteId || null,
      title: title.trim(),
      description: description ? description.trim() : '',
      reminderDateTime,
      repeat: repeat || 'none'
    });

    await reminder.save();

    res.status(201).json({
      success: true,
      data: reminder
    });
  } catch (error) {
    console.error('[REMINDERS] Create error:', error);
    res.status(500).json({ success: false, message: 'Failed to create reminder' });
  }
});

/**
 * @route GET /api/reminders/:userId
 * @desc Get all reminders for a user
 */
router.get('/:userId', requireAuth, async (req, res) => {
  try {
    const { userId } = req.params;
    const { upcoming, completed } = req.query;

    // Security check: ensure user is fetching their own reminders
    if (userId !== req.userId) {
      return res.status(403).json({ success: false, message: 'Unauthorized access' });
    }

    let query = { userId };
    
    if (upcoming === 'true') {
      query.reminderDateTime = { $gte: new Date() };
      query.isCompleted = false;
    } else if (completed === 'true') {
      query.isCompleted = true;
    }

    const reminders = await RevisionReminder.find(query)
      .sort({ reminderDateTime: 1 })
      .lean();

    res.json({
      success: true,
      data: reminders
    });
  } catch (error) {
    console.error('[REMINDERS] Fetch error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch reminders' });
  }
});

/**
 * @route PUT /api/reminders/:id
 * @desc Update a reminder (edit or toggle completion)
 */
router.put('/:id', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const reminder = await RevisionReminder.findById(id);
    if (!reminder) {
      return res.status(404).json({ success: false, message: 'Reminder not found' });
    }

    // Security check
    if (reminder.userId.toString() !== req.userId) {
      return res.status(403).json({ success: false, message: 'Unauthorized access' });
    }

    // Update fields
    const allowedUpdates = ['title', 'description', 'reminderDateTime', 'isCompleted', 'repeat'];
    allowedUpdates.forEach(field => {
      if (updateData[field] !== undefined) {
        reminder[field] = updateData[field];
      }
    });

    await reminder.save();

    res.json({
      success: true,
      data: reminder
    });
  } catch (error) {
    console.error('[REMINDERS] Update error:', error);
    res.status(500).json({ success: false, message: 'Failed to update reminder' });
  }
});

/**
 * @route DELETE /api/reminders/:id
 * @desc Delete a reminder
 */
router.delete('/:id', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;

    const reminder = await RevisionReminder.findById(id);
    if (!reminder) {
      return res.status(404).json({ success: false, message: 'Reminder not found' });
    }

    // Security check
    if (reminder.userId.toString() !== req.userId) {
      return res.status(403).json({ success: false, message: 'Unauthorized access' });
    }

    await RevisionReminder.findByIdAndDelete(id);

    res.json({
      success: true,
      message: 'Reminder deleted successfully'
    });
  } catch (error) {
    console.error('[REMINDERS] Delete error:', error);
    res.status(500).json({ success: false, message: 'Failed to delete reminder' });
  }
});

module.exports = router;
