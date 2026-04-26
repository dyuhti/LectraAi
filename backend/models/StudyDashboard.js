const mongoose = require('mongoose');

const StudyDashboardSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  date: {
    type: String, // YYYY-MM-DD
    required: true,
  },
  progressScore: {
    type: Number,
    default: 0,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
}, { 
  collection: 'studydashboards', // Explicitly use the existing collection
  timestamps: false 
});

// Ensure unique record per user per day
StudyDashboardSchema.index({ userId: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('StudyDashboard', StudyDashboardSchema);
