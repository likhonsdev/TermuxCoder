import React, { useEffect, useRef } from 'react';
import { Terminal } from '@xterm/xterm';
import { FitAddon } from '@xterm/addon-fit';
import '@xterm/xterm/css/xterm.css';
import chalk from 'chalk';
import boxen from 'boxen';
import figlet from 'figlet';
import gradient from 'gradient-string';

const TerminalIntro = () => {
  const terminalRef = useRef(null);

  useEffect(() => {
    const terminal = new Terminal({
      theme: {
        background: '#282a36',
        foreground: '#f8f8f2',
        cursor: '#f8f8f2',
        selectionBackground: '#44475a',
        black: '#21222c',
        red: '#ff5555',
        green: '#50fa7b',
        yellow: '#f1fa8c',
        blue: '#6272a4',
        magenta: '#ff79c6',
        cyan: '#8be9fd',
        white: '#f8f8f2',
        brightBlack: '#6272a4',
        brightRed: '#ff5555',
        brightGreen: '#50fa7b',
        brightYellow: '#f1fa8c',
        brightBlue: '#6272a4',
        brightMagenta: '#ff79c6',
        brightCyan: '#8be9fd',
        brightWhite: '#f8f8f2',
      },
    });

    const fitAddon = new FitAddon();
    terminal.loadAddon(fitAddon);

    terminal.open(terminalRef.current);
    fitAddon.fit();

    // Terminal UI
    terminal.write('\x1bc'); // Clear the screen

    // Banner
    const banner = figlet.textSync('CLAUDE\\nCODE', {
      font: 'Rectangles',
      horizontalLayout: 'default',
      verticalLayout: 'default',
    });
    terminal.write(chalk.hex('#F97316')(banner) + '\\r\\n');

    // Welcome message box
    const welcomeMessage = boxen(
      chalk.white('✱  Welcome to the ') +
      chalk.bold.whiteBright('Claude Code') +
      chalk.white(' research preview!'),
      {
        padding: 1,
        margin: 1,
        borderStyle: 'round',
        borderColor: '#F97316'
      }
    );
    terminal.write(welcomeMessage + '\\r\\n');

    // Status
    terminal.write(
      chalk.blueBright('🎉 Login successful. ') +
      chalk.white('Press ') +
      chalk.bold('Enter') +
      chalk.white(' to continue') +
      '\\r\\n'
    );

    // Wait for Enter key (placeholder)
    terminal.write('Launching TermuxCoder...\\r\\n');

    return () => {
      terminal.dispose();
    };
  }, []);

  return <div ref={terminalRef} />;
};

export default TerminalIntro;
