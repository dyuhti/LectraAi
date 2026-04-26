const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const Note = require('../models/Note');
const { updateDailyProgress } = require('../services/progressService');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

// GET /api/notes - Fetch all notes
router.get('/', async (req, res) => {
  try {
    const notes = await Note.find().sort({ createdAt: -1 });
    return res.status(200).json(notes);
  } catch (error) {
    console.error('Error fetching notes:', error);
    return res.status(500).json({ error: 'Failed to fetch notes' });
  }
});

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

// PUT /api/notes/:id - Update an existing note
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const {
      title,
      content,
      summary,
      transcript,
      cleanedText,
      subject,
      keyPoints,
      formulas,
      examples,
    } = req.body;

    console.log(`[NOTES] Update request for id: ${id}`);
    console.log('[NOTES] Update payload:', {
      title,
      contentPreview: typeof content === 'string' ? content.substring(0, 120) : content,
      summaryPreview: typeof summary === 'string' ? summary.substring(0, 120) : summary,
      transcriptPreview: typeof transcript === 'string' ? transcript.substring(0, 120) : transcript,
      cleanedTextPreview:
        typeof cleanedText === 'string' ? cleanedText.substring(0, 120) : cleanedText,
      subject,
      keyPointsCount: Array.isArray(keyPoints) ? keyPoints.length : undefined,
      formulasCount: Array.isArray(formulas) ? formulas.length : undefined,
      examplesCount: Array.isArray(examples) ? examples.length : undefined,
    });

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid Note ID' });
    }

    const updatePayload = {
      updatedAt: new Date(),
    };

    if (title !== undefined) {
      updatePayload.title = typeof title === 'string' ? title.trim() : title;
    }
    if (content !== undefined) {
      updatePayload.content = content;
    }
    if (summary !== undefined) {
      updatePayload.summary = summary;
    }
    if (transcript !== undefined) {
      updatePayload.transcript = transcript;
    }
    if (cleanedText !== undefined) {
      updatePayload.cleanedText = cleanedText;
    }
    if (subject !== undefined) {
      updatePayload.subject = subject;
    }
    if (keyPoints !== undefined) {
      updatePayload.keyPoints = Array.isArray(keyPoints) ? keyPoints : [];
    }
    if (formulas !== undefined) {
      updatePayload.formulas = Array.isArray(formulas) ? formulas : [];
    }
    if (examples !== undefined) {
      updatePayload.examples = Array.isArray(examples) ? examples : [];
    }

    const updatedNote = await Note.findByIdAndUpdate(id, updatePayload, {
      new: true,
      runValidators: true,
    });

    if (!updatedNote) {
      return res.status(404).json({ message: 'Note not found' });
    }

    console.log(`[NOTES] Note updated successfully: ${id}`);
    return res.status(200).json(updatedNote);
  } catch (error) {
    console.error('[NOTES] Error updating note:', error);
    return res.status(500).json({ error: error.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    console.log(`[NOTES] Delete request for id: ${id}`);

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid Note ID' });
    }

    const deletedNote = await Note.findByIdAndDelete(id);
    if (!deletedNote) {
      return res.status(404).json({ message: 'Note not found' });
    }

    console.log(`[NOTES] Note deleted successfully: ${id}`);
    return res.status(200).json({ message: 'Deleted successfully' });
  } catch (error) {
    console.error('[NOTES] Error deleting note:', error);
    return res.status(500).json({ error: error.message });
  }
});

module.exports = router;
