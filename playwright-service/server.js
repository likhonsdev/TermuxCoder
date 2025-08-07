const express = require('express');
const { chromium } = require('playwright');

const app = express();
app.use(express.json());

const PORT = 3000;

let browser;
let page;

(async () => {
  // Launch a persistent browser context
  browser = await chromium.launch({ headless: false }); // Run with a head for VNC
  const context = await browser.newContext();
  page = await context.newPage();
  console.log('Playwright browser launched');
})();

app.get('/screenshot', async (req, res) => {
  if (!page) {
    return res.status(500).send('Browser not initialized');
  }
  try {
    const screenshotBuffer = await page.screenshot();
    res.setHeader('Content-Type', 'image/png');
    res.send(screenshotBuffer);
  } catch (error) {
    console.error('Failed to take screenshot:', error);
    res.status(500).send('Failed to take screenshot');
  }
});

app.post('/execute', async (req, res) => {
  if (!page) {
    return res.status(500).send('Browser not initialized');
  }
  const { code } = req.body;
  if (!code) {
    return res.status(400).send('No code provided');
  }

  try {
    // THIS IS A SECURITY RISK and is only for demonstration purposes.
    // In a real application, you would not want to execute arbitrary code.
    await eval(`(async () => { ${code} })()`);
    res.status(200).send({ message: 'Code executed successfully' });
  } catch (error) {
    console.error('Failed to execute code:', error);
    res.status(500).send(`Failed to execute code: ${error.message}`);
  }
});

app.listen(PORT, () => {
  console.log(`Playwright service listening on port ${PORT}`);
});
