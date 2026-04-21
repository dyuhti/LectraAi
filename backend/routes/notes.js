const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const Note = require('../models/Note');

const router = express.Router();

function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.startsWith('Bearer ')
    ? authHeader.substring(7)
    : null;

  if (!token) {
    return res.status(401).json({ msg: 'Missing auth token' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.id;
    return next();
  } catch (error) {
    return res.status(401).json({ msg: 'Invalid token' });
  }
}

router.get('/', requireAuth, async (req, res) => {
  try {
    const notes = await Note.find({ userId: req.userId })
      .sort({ createdAt: -1 })
      .lean();
    return res.json(notes);
  } catch (error) {
    return res.status(500).json({ msg: 'Failed to fetch notes' });
  }
});

router.post('/', requireAuth, async (req, res) => {
  try {
    const {
      title,
      subject,
      content,
      summary,
      cleanedText,
      keyPoints,
      formulas,
      examples,
      createdAt,
    } = req.body;

    if (!title || !title.trim()) {
      return res.status(400).json({ msg: 'Title is required' });
    }

    const note = await Note.create({
      userId: req.userId,
      title: title.trim(),
      subject: subject || 'Document',
      content: content || '',
      summary: summary || '',
      cleanedText: cleanedText || '',
      keyPoints: Array.isArray(keyPoints) ? keyPoints : [],
      formulas: Array.isArray(formulas) ? formulas : [],
      examples: Array.isArray(examples) ? examples : [],
      createdAt: createdAt ? new Date(createdAt) : new Date(),
    });

    return res.status(201).json(note);
  } catch (error) {
    return res.status(500).json({ msg: 'Failed to create note' });
  }
});

router.put('/:id', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ msg: 'Invalid note id' });
    }

    console.log('Updating note ID:', id);

    const updates = {};
    if (typeof req.body.title !== 'undefined') updates.title = req.body.title;
    if (typeof req.body.subject !== 'undefined') updates.subject = req.body.subject;
    if (typeof req.body.content !== 'undefined') updates.content = req.body.content;
    if (typeof req.body.summary !== 'undefined') updates.summary = req.body.summary;
    if (typeof req.body.cleanedText !== 'undefined') updates.cleanedText = req.body.cleanedText;
    if (Object.prototype.hasOwnProperty.call(req.body, 'keyPoints')) {
      updates.keyPoints = Array.isArray(req.body.keyPoints) ? req.body.keyPoints : [];
    }
    if (Object.prototype.hasOwnProperty.call(req.body, 'formulas')) {
      updates.formulas = Array.isArray(req.body.formulas) ? req.body.formulas : [];
    }
    if (Object.prototype.hasOwnProperty.call(req.body, 'examples')) {
      updates.examples = Array.isArray(req.body.examples) ? req.body.examples : [];
    }

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ msg: 'No fields provided for update' });
    }

    console.log('Update payload:', updates);

    const result = await Note.updateOne(
      { _id: id, userId: req.userId },
      { $set: updates }
    );

    console.log('Update result:', result.modifiedCount);

    if (result.matchedCount === 0) {
      return res.status(404).json({ msg: 'Note not found' });
    }

    const note = await Note.findOne({ _id: id, userId: req.userId });
    return res.json(note);
  } catch (error) {
    return res.status(500).json({ msg: 'Failed to update note' });
  }
});

router.delete('/:id', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    const note = await Note.findOneAndDelete({ _id: id, userId: req.userId });
    if (!note) {
      return res.status(404).json({ msg: 'Note not found' });
    }
    return res.json({ msg: 'Note deleted' });
  } catch (error) {
    return res.status(500).json({ msg: 'Failed to delete note' });
  }
});

module.exports = router;
