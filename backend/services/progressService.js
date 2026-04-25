const DailyProgress = require('../models/DailyProgress');

/**
 * Returns current date in YYYY-MM-DD format
 */
const getTodayDate = () => {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
};

/**
 * Updates daily progress for a user
 * @param {string} userId 
 * @param {string} type - 'note', 'audio', or 'quiz'
 */
const updateDailyProgress = async (userId, type) => {
  try {
    const today = getTodayDate();
    
    const updateField = {};
    if (type === 'note') updateField.notesCreated = 1;
    else if (type === 'audio') updateField.audioRecorded = 1;
    else if (type === 'quiz') updateField.quizzesGenerated = 1;
    else return;

    // Use findOneAndUpdate with upsert for atomicity and efficiency
    const updatedDoc = await DailyProgress.findOneAndUpdate(
      { userId, date: today },
      { 
        $inc: updateField,
        $set: { updatedAt: new Date() }
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
    
    console.log(`[PROGRESS] ✅ Updated ${type} count for user ${userId}. New status:`, {
      notes: updatedDoc.notesCreated,
      audio: updatedDoc.audioRecorded,
      quiz: updatedDoc.quizzesGenerated
    });
  } catch (error) {
    console.error('[PROGRESS] Error updating daily progress:', error);
  }
};

module.exports = {
  getTodayDate,
  updateDailyProgress
};
