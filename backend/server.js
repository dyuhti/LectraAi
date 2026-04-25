require('dotenv').config();

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const fileUpload = require('express-fileupload');

const app = express();

app.use(cors());
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true, limit: '5mb' }));
app.use(fileUpload({ limits: { fileSize: 50 * 1024 * 1024 } }));

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Feedback submission endpoint
app.post('/feedback', (req, res) => {
  try {
    const { name, email, feedback } = req.body;

    // Validate feedback is required
    if (!feedback || !feedback.trim()) {
      console.error('[FEEDBACK] Missing feedback text');
      return res.status(400).json({ error: 'Feedback is required' });
    }

    // Log feedback submission
    console.log('[FEEDBACK] Received feedback submission');
    console.log(`  Name: ${name || 'Not provided'}`);
    console.log(`  Email: ${email || 'Not provided'}`);
    console.log(`  Feedback: ${feedback.substring(0, 100)}...`);

    // Return success response
    res.status(200).json({ 
      message: 'Feedback submitted successfully',
      feedbackId: Date.now().toString(),
    });
  } catch (error) {
    console.error('[FEEDBACK] Error processing feedback:', error);
    res.status(500).json({ error: 'Failed to submit feedback' });
  }
});

app.use('/api/auth', require('./routes/auth'));
app.use('/api/notes', require('./routes/notes'));
app.use('/transcribe', require('./routes/transcribe'));

const port = process.env.PORT || 5000;
const mongoUri = process.env.MONGO_URI;

if (!mongoUri) {
  console.error('MONGO_URI is missing');
  process.exit(1);
}

mongoose
  .connect(mongoUri)
  .then(() => {
  app.listen(port, '0.0.0.0', () => {
    console.log(`Server running on port ${port}`);
  });
  })
  .catch((error) => {
    console.error('MongoDB connection error:', error);
    process.exit(1);
  });
