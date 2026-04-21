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
    content: {
      type: String,
      default: '',
    },
    summary: {
      type: String,
      default: '',
    },
    cleanedText: {
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
