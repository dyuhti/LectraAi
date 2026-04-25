const mongoose = require('mongoose');

const RevisionReminderSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  noteId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Note',
    required: false,
  },
  title: {
    type: String,
    required: true,
    trim: true,
  },
  description: {
    type: String,
    required: false,
    trim: true,
  },
  reminderDateTime: {
    type: Date,
    required: true,
  },
  isCompleted: {
    type: Boolean,
    default: false,
  },
  repeat: {
    type: String,
    enum: ['none', 'daily', 'weekly', 'monthly'],
    default: 'none',
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

// Index for efficient retrieval of upcoming reminders per user
RevisionReminderSchema.index({ userId: 1, reminderDateTime: 1 });

module.exports = mongoose.model('RevisionReminder', RevisionReminderSchema);
