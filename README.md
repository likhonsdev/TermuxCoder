# TermuxCoder

A Gemini-powered terminal AI coding agent optimized for Termux on Android.

![Terminal](https://img.shields.io/badge/Terminal-Compatible-blue)
![Termux](https://img.shields.io/badge/Termux-Optimized-green)
![Gemini](https://img.shields.io/badge/Gemini_1.5-Powered-orange)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

**TermuxCoder** is a lightweight CLI tool that brings the power of Gemini 1.5 Pro directly to your terminal. Ask coding questions, generate complete applications, debug issues, and more - all without leaving the command line.

## ✨ Features

- 🧠 **Ask Anything**: Send prompts to Gemini for code, explanations, or advice
- 📝 **Code Generation**: Auto-extract code blocks to files from responses
- 🔍 **Task Planning**: Break down complex coding tasks into manageable steps
- 🐛 **Auto-Debugging**: Fix issues in your code with AI assistance
- 📊 **Execution Tracing**: Run code with AI analysis of results
- ✏️ **Code Editing**: Make AI-assisted edits to existing files

## 🚀 Installation

### One-Line Install (Recommended)
```bash
curl -sSL https://raw.githubusercontent.com/likhonsdev/TermuxCoder/main/install.sh | bash
```

### Manual Installation
```bash
# Clone the repository
git clone https://github.com/likhonsdev/TermuxCoder.git
cd TermuxCoder

# Make the script executable
chmod +x termuxcoder.sh
chmod +x bin/*.sh

# Create symlink (optional)
ln -s "$(pwd)/termuxcoder.sh" ~/.local/bin/termuxcoder
```

## 📋 Requirements

- Bash shell
- Python 3 with `requests` module
- curl
- jq (for JSON parsing)
- figlet + lolcat (optional, for fancy headers)

## 🔧 Configuration

Run the setup command to configure your API key:
```bash
termuxcoder setup
```

This will prompt you for your Google AI Studio API key and create a `config.json` file.

## 💻 Usage

### Basic Usage

```bash
termuxcoder [COMMAND] [OPTIONS]
```

### Commands

- **ask**: Send a prompt to Gemini
  ```bash
  termuxcoder ask "Write a Python function to download YouTube videos"
  termuxcoder ask -e "Create a React component" # Extract code to files
  ```

- **plan**: Generate a task plan for complex coding queries
  ```bash
  termuxcoder plan "Create a full-stack Todo application"
  ```

- **fix**: Debug code with Gemini suggestions
  ```bash
  termuxcoder fix buggy_script.py
  ```

- **run**: Execute and trace code output
  ```bash
  termuxcoder run script.py
  ```

- **edit**: Make Gemini-assisted code edits
  ```bash
  termuxcoder edit app.js "Add form validation"
  ```

- **save**: Save last output to logs directory
  ```bash
  termuxcoder save response.txt
  ```

- **help**: Show help message
  ```bash
  termuxcoder help
  ```

## 📂 Project Structure

```
TermuxCoder/
├── termuxcoder.sh           # Main entry script
├── config.json              # Stores API key and settings
├── bin/
│   ├── ask.sh               # Ask prompt
│   ├── plan.sh              # Task planner
│   ├── fix.sh               # Code fixing
│   ├── run.sh               # Code execution
│   ├── edit.sh              # Code editing
│   ├── save.sh              # Output saving
│   └── utils.sh             # Helper functions
├── logs/                    # Directory for saved outputs
└── models/
    └── gemini_client.py     # Gemini API interface
```

## 🔒 Privacy and API Keys

Your API key is stored locally in the `config.json` file. TermuxCoder doesn't send data anywhere except directly to the Google API servers.

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Feel free to open issues, submit pull requests, or suggest new features.

## 📱 Termux-Specific Tips

For best results in Termux:
- Install a good monospace font
- Increase terminal font size for better readability
- Use a terminal session manager like `tmux`

---

**Built with ❤️ for developers who love working in the terminal.**
