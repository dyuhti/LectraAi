const mongoose = require('mongoose');

const NoteSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    subject: {
      type: String,
      default: 'Document',
      trim: true,
    },
    transcript: {
      type: String,
      default: '',
    },
    content: {
      type: String,
      default: '',
    },
    cleanedText: {
      type: String,
      default: '',
    },
    summary: {
      type: String,
      default: '',
    },
    keyPoints: {
      type: [String],
      default: [],
    },
    formulas: {
      type: [String],
      default: [],
    },
    examples: {
      type: [String],
      default: [],
    },
    fileUrl: {
      type: String,
      default: '',
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Note', NoteSchema);
