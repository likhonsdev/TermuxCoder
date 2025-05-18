require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');
const { Redis } = require('@upstash/redis');
const agentRoutes = require('./routes/agent');

const app = express();
app.use(bodyParser.json());

const prisma = new PrismaClient();
const redis = new Redis({
  url: process.env.REDIS_URL,
  token: process.env.REDIS_TOKEN,
});

// Authentication middleware
const authenticate = (req, res, next) => {
  const token = req.header('Authorization')?.replace('Bearer ', '');
  if (!token) return res.status(401).send('Access denied');
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    res.status(401).send('Invalid token');
  }
};

// Login endpoint
app.post('/auth/login', async (req, res) => {
  const { username, password } = req.body;
  const user = await prisma.user.findUnique({ where: { username } });
  if (!user || user.password !== password) {
    return res.status(401).send('Invalid credentials');
  }
  const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: '1h' });
  res.send({ token });
});

// Agent routes
app.use('/agent', authenticate, agentRoutes);

// Handle server shutdown gracefully
process.on('close', () => {
  if (server) {
    server.close();
  }
});

const PORT = process.env.PORT || 4000;
let server;

function startServer(port) {
  server = app.listen(port);

  server.on('listening', () => {
    console.log(`Server running on port ${port}`);
  });

  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.log(`Port ${port} is already in use. Trying alternative port...`);
      // Generate a random port between 3000 and 9000
      let newPort = 3000 + Math.floor(Math.random() * 6000);
      startServer(newPort); // Recursively try a new port
    } else {
      console.error(err);
    }
  });
}

startServer(PORT);
