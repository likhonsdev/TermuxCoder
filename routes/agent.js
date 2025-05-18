const express = require('express');
const axios = require('axios');
const router = express.Router();
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { PrismaClient } = require('@prisma/client');
const { Redis } = require('@upstash/redis');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-pro-latest' });
const prisma = new PrismaClient();
const redis = new Redis({
  url: process.env.REDIS_URL,
  token: process.env.REDIS_TOKEN,
});

const PIPE_API_URL = 'https://api.langbase.com/v1/pipes/run';

// Chat with Pipe API
router.post('/chat', async (req, res) => {
  const { message } = req.body;
  const cacheKey = `chat:${message}`;
  const cached = await redis.get(cacheKey);
  if (cached) return res.send({ response: cached });

  const data = {
    messages: [{ role: 'user', content: message }],
    stream: false,
  };

  try {
    const response = await axios.post(PIPE_API_URL, data, {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${process.env.PIPE_API_KEY}`,
      },
    });
    const reply = response.data.choices[0].message.content;
    await redis.set(cacheKey, reply, { ex: 3600 });
    res.send({ response: reply });
  } catch (err) {
    res.status(500).send({ error: err.message });
  }
});

// Generate app with Gemini API
router.post('/generate-app', async (req, res) => {
  const { description } = req.body;
  const cacheKey = `generate-app:${description}`;
  const cached = await redis.get(cacheKey);
  if (cached) return res.send({ files: cached });

  const prompt = `Generate a complete application from this description: ${description}. Provide the code for all necessary files, each in a separate markdown code block with the file path above it, like "**File: path/to/file.ext**" followed by the code block.`;
  const result = await model.generateContent(prompt);
  const responseText = result.response.text();

  // Parse multiple files
  const files = parseFilesFromResponse(responseText);

  // Store in database
  const project = await prisma.project.create({
    data: {
      name: description.slice(0, 50),
      userId: req.user.userId,
      files: {
        create: files.map((file) => ({ path: file.path, content: file.content, version: 1 })),
      },
    },
    include: { files: true },
  });

  await redis.set(cacheKey, project.files, { ex: 3600 });
  res.send({ files: project.files });
});

// Parse files from AI response
function parseFilesFromResponse(text) {
  const fileRegex = /\*\*File:\s*([^\\*]+)\*\*\s*```[\\w]*\n([\\s\\S]*?)```/g;
  const files = [];
  let match;
  while ((match = fileRegex.exec(text)) !== null) {
    files.push({ path: match[1].trim(), content: match[2].trim() });
  }
  return files.length ? files : [{ path: 'index.js', content: text }];
}

// Debug with Gemini API
router.post('/debug', async (req, res) => {
  const { code } = req.body;
  const prompt = `Debug this code and suggest fixes: ${code}`;
  const result = await model.generateContent(prompt);
  res.send({ suggestions: result.response.text() });
});

// Generate docs with Gemini API
router.post('/docs', async (req, res) => {
  const { files } = req.body; // Array of {path, content}
  const prompt = `Generate documentation for these files: ${JSON.stringify(files)}`;
  const result = await model.generateContent(prompt);
  res.send({ documentation: result.response.text() });
});

module.exports = router;
