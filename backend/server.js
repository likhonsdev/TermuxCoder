const express = require('express');
const bodyParser = require('body-parser');
const authRoutes = require('./routes/auth');
const agentRoutes = require('./routes/agent');
const authenticate = require('./middleware/auth');

const app = express();
app.use(bodyParser.json());

app.use('/auth', authRoutes);
app.use('/agent', authenticate, agentRoutes);

const PORT = 4001;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
