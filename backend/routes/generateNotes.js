const express = require('express');

const router = express.Router();

const GROQ_CHAT_ENDPOINT = 'https://api.groq.com/openai/v1/chat/completions';
const GROQ_CHAT_MODEL = process.env.GROQ_CHAT_MODEL || 'llama-3.1-8b-instant';

function extractJsonObject(raw) {
  const trimmed = (raw || '').trim();
  if (!trimmed) {
    throw new Error('Empty AI response');
  }

  try {
    return JSON.parse(trimmed);
  } catch (_) {
    // Try extracting JSON payload from fenced blocks or surrounding prose.
  }

  const fenced = trimmed.match(/```(?:json)?\s*([\s\S]*?)\s*```/i);
  if (fenced && fenced[1]) {
    return JSON.parse(fenced[1]);
  }

  const start = trimmed.indexOf('{');
  const end = trimmed.lastIndexOf('}');
  if (start >= 0 && end > start) {
    return JSON.parse(trimmed.slice(start, end + 1));
  }

  throw new Error('AI response did not contain valid JSON');
}

function normalizeResult(parsed, fallbackText) {
  const title = (parsed.title || 'Generated Notes').toString().trim();
  const content = (parsed.content || fallbackText || '').toString().trim();

  let keyPoints = [];
  if (Array.isArray(parsed.key_points)) {
    keyPoints = parsed.key_points
      .map((point) => point?.toString().trim())
      .filter((point) => point && point.length > 0);
  } else if (typeof parsed.key_points === 'string') {
    const single = parsed.key_points.trim();
    if (single) keyPoints = [single];
  }

  return { title, content, key_points: keyPoints };
}

router.post('/generate-notes', async (req, res) => {
  try {
    const { text, mode = 'exam' } = req.body || {};

    if (!text || !text.toString().trim()) {
      return res.status(400).json({ error: 'Text is required and cannot be empty' });
    }

    const apiKey = process.env.GROQ_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ error: 'GROQ_API_KEY not configured' });
    }

    const prompt = [
      'You are an AI study assistant.',
      'Convert the input text into clean study notes.',
      `Mode: ${mode}`,
      'Return ONLY valid JSON in this exact shape:',
      '{"title":"...","content":"...","key_points":["...","..."]}',
      '',
      'Input text:',
      text,
    ].join('\n');

    const response = await fetch(GROQ_CHAT_ENDPOINT, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: GROQ_CHAT_MODEL,
        temperature: 0.3,
        messages: [{ role: 'user', content: prompt }],
        response_format: { type: 'json_object' },
      }),
    });

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      const message = data?.error?.message || data?.error || `Groq API error: ${response.status}`;
      return res.status(response.status).json({ error: message });
    }

    const content =
      data?.choices?.[0]?.message?.content?.toString() ||
      '';

    const parsed = extractJsonObject(content);
    const result = normalizeResult(parsed, text.toString());

    return res.status(200).json(result);
  } catch (error) {
    console.error('[GENERATE_NOTES] Error:', error);
    return res.status(500).json({ error: error.message || 'Failed to generate notes' });
  }
});

module.exports = router;
