const { program } = require('commander');
const axios = require('axios');
const fs = require('fs');
const path = require('path');

const API_URL = 'http://localhost:4000';
let token = process.env.TERMUXCODER_TOKEN;
const tokenFile = path.join(__dirname, '.token');
if (fs.existsSync(tokenFile)) {
  token = fs.readFileSync(tokenFile, 'utf8');
}

program
  .command('login')
  .description('Login to TermuxCoder')
  .action(async () => {
    const username = process.env.TERMUXCODER_USERNAME;
    const password = process.env.TERMUXCODER_PASSWORD;
    if (!username || !password) {
      console.log('Set TERMUXCODER_USERNAME and TERMUXCODER_PASSWORD');
      return;
    }
    try {
      const response = await axios.post(`${API_URL}/auth/login`, { username, password });
      token = response.data.token;
      fs.writeFileSync(tokenFile, token);
      console.log('Login successful');
    } catch (err) {
      console.error('Login failed', err.response?.data);
    }
  });

program
  .command('create <description>')
  .description('Create a new app from description')
  .action(async (description) => {
    if (!token) {
      console.log('Please login first');
      return;
    }
    try {
      const response = await axios.post(`${API_URL}/agent/generate-app`, { description }, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const files = response.data.files;
      const projectName = description.replace(/\s+/g, '-').toLowerCase();
      const projectDir = path.join(process.cwd(), projectName);
      fs.mkdirSync(projectDir, { recursive: true });
      files.forEach(file => {
        const filePath = path.join(projectDir, file.path);
        fs.mkdirSync(path.dirname(filePath), { recursive: true });
        fs.writeFileSync(filePath, file.content);
      });
      console.log(`App generated in ${projectDir}`);
    } catch (err) {
      console.error('Failed to generate app', err.response?.data);
    }
  });

// Add other commands like debug, docs, etc.

program.parse(process.argv);
