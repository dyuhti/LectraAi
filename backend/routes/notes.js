const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const Note = require('../models/Note');
const { updateDailyProgress } = require('../services/progressService');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

// GET /api/notes/:userId - Fetch all notes for a specific user
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ success: false, message: 'Invalid User ID' });
    }

    const notes = await Note.find({ userId })
      .sort({ createdAt: -1 })
      .lean();

    return res.status(200).json({
      success: true,
      data: notes
    });
  } catch (error) {
    console.error('[NOTES] Error fetching user notes:', error);
    return res.status(500).json({ success: false, message: 'Failed to fetch notes' });
  }
});

// POST /api/notes/save - Save a processed note
router.post('/save', async (req, res) => {
  try {
    const { userId, title, transcript, summary, fileUrl } = req.body;

    // Validation
    if (!userId) {
      return res.status(400).json({ success: false, message: 'userId is required' });
    }
    if (!title || !title.trim()) {
      return res.status(400).json({ success: false, message: 'title is required' });
    }

    const note = new Note({
      userId,
      title: title.trim(),
      transcript: transcript || '',
      summary: summary || '',
      fileUrl: fileUrl || ''
    });

    await note.save();

    // Track daily progress
    await updateDailyProgress(userId, 'note');

    return res.status(201).json({
      success: true,
      message: 'Note saved successfully',
      data: note
    });
  } catch (error) {
    console.error('[NOTES] Error saving note:', error);
    return res.status(500).json({ success: false, message: 'Failed to save note' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ success: false, message: 'Invalid Note ID' });
    }

    const note = await Note.findByIdAndDelete(id);
    if (!note) {
      return res.status(404).json({ success: false, message: 'Note not found' });
    }

    return res.json({
      success: true,
      message: 'Note deleted successfully'
    });
  } catch (error) {
    console.error('[NOTES] Error deleting note:', error);
    return res.status(500).json({ success: false, message: 'Failed to delete note' });
  }
});

module.exports = router;
