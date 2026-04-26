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
 * @param {number} duration - minutes spent (optional)
 */
const updateDailyProgress = async (userId, type, duration) => {
  try {
    const today = getTodayDate();

    let progress = await DailyProgress.findOne({ userId, date: today });
    if (!progress) {
      progress = new DailyProgress({ userId, date: today });
    }

    if (type === 'note') progress.notesCreated += 1;
    else if (type === 'audio') progress.audioRecorded += 1;
    else if (type === 'quiz') progress.quizzesGenerated += 1;

    if (duration != null) {
      progress.studyTime += duration;
    }

    progress.updatedAt = new Date();
    await progress.save();

    console.log(`[PROGRESS] Updated ${type} count for user ${userId}`);
    console.log("Study time:", progress.studyTime);
    console.log('Progress:', progress);
  } catch (error) {
    console.error('[PROGRESS] Error updating daily progress:', error);
  }
};

module.exports = {
  getTodayDate,
  updateDailyProgress
};
