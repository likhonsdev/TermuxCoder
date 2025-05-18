#!/usr/bin/env node
const chalk = require('chalk').default;
const boxen = require('boxen').default;
const figlet = require('figlet');
const gradient = require('gradient-string');
const readline = require('readline');

// Terminal UI
console.clear();

// Banner
console.log(
  chalk.hex('#F97316')(figlet.textSync('CLAUDE\nCODE', {
    font: 'Rectangles',
    horizontalLayout: 'default',
    verticalLayout: 'default',
  }))
);

// Welcome message box
console.log(
  boxen(
    chalk.white('✱  Welcome to the ') +
    chalk.bold.whiteBright('Claude Code') +
    chalk.white(' research preview!'),
    {
      padding: 1,
      margin: 1,
      borderStyle: 'round',
      borderColor: '#F97316'
    }
  )
);

// Status
console.log(
  chalk.blueBright('🎉 Login successful. ') + chalk.white('Press ') + chalk.bold('Enter') + chalk.white(' to continue')
);

// Wait for Enter key
readline.emitKeypressEvents(process.stdin);
process.stdin.setRawMode(true);
process.stdin.on('keypress', (_, key) => {
  if (key.name === 'return') {
    console.clear();
    console.log(gradient.vice('🚀 Launching TermuxCoder...'));
    process.exit(0);
  }
});
