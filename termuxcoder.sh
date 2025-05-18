#!/usr/bin/env bash
#
# TermuxCoder - A Gemini-powered terminal AI coding agent
# 

set -e

# Script version
VERSION="0.1.0"

# Default config location
CONFIG_FILE="$(dirname "$0")/config.json"
LOGS_DIR="$(dirname "$0")/logs"
UTILS_FILE="$(dirname "$0")/bin/utils.sh"

# Load utilities
source "$UTILS_FILE" 2>/dev/null || {
    echo "Error: Could not load utilities from $UTILS_FILE"
    echo "Please ensure TermuxCoder is properly installed."
    exit 1
}

# Display TermuxCoder header
display_header() {
    if command -v figlet >/dev/null && command -v lolcat >/dev/null; then
        figlet "TermuxCoder" | lolcat
    else
        echo "================================================="
        echo "               TermuxCoder v$VERSION              "
        echo "  Gemini-powered terminal AI coding assistant    "
        echo "================================================="
    fi
}

# Display help message
show_help() {
    display_header
    cat << EOF

USAGE:
    termuxcoder [COMMAND] [OPTIONS]

COMMANDS:
    ask [prompt]      Send a prompt to Gemini and display the response
    plan [task]       Generate a task plan for complex coding queries
    fix [file]        Debug code with Gemini suggestions
    run [file]        Execute and trace code output
    edit [file]       Gemini-assisted code editing
    save [filename]   Save last output to logs directory
    setup             Configure API key and settings
    help              Show this help message
    version           Show version information

EXAMPLES:
    termuxcoder ask "Write a Python function to sort a dictionary by values"
    termuxcoder plan "Build a weather app with React"
    termuxcoder fix buggy_script.py
    termuxcoder edit app.js "Add user authentication"

For more information, visit: https://github.com/likhonsdev/TermuxCoder
EOF
}

# Show version
show_version() {
    echo "TermuxCoder v$VERSION"
}

# Check if API key is configured
check_api_key() {
    if [[ -f "$CONFIG_FILE" ]]; then
        API_KEY=$(jq -r '.api_key' "$CONFIG_FILE" 2>/dev/null)
        if [[ "$API_KEY" == "null" || -z "$API_KEY" ]]; then
            echo "Error: API key not found in config file."
            echo "Please run 'termuxcoder setup' to configure your API key."
            return 1
        fi
    else
        echo "Error: Config file not found."
        echo "Please run 'termuxcoder setup' to configure TermuxCoder."
        return 1
    fi
    return 0
}

# Setup function
setup() {
    display_header
    echo "Setting up TermuxCoder..."
    
    # Create config directory if it doesn't exist
    mkdir -p "$(dirname "$CONFIG_FILE")"
    mkdir -p "$LOGS_DIR"
    
    # Prompt for API key
    read -p "Enter your Google AI Studio API key: " API_KEY
    
    # Check if jq is installed
    if command -v jq >/dev/null; then
        if [[ -f "$CONFIG_FILE" ]]; then
            # Update existing config file
            jq --arg key "$API_KEY" '.api_key = $key' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        else
            # Create new config file
            echo '{
  "api_key": "'"$API_KEY"'",
  "model": "gemini-1.5-pro",
  "max_tokens": 8192,
  "temperature": 0.7,
  "stream_output": true,
  "logs_enabled": true
}' > "$CONFIG_FILE"
        fi
    else
        # Fallback if jq is not available
        echo '{
  "api_key": "'"$API_KEY"'",
  "model": "gemini-1.5-pro",
  "max_tokens": 8192,
  "temperature": 0.7,
  "stream_output": true,
  "logs_enabled": true
}' > "$CONFIG_FILE"
    fi
    
    echo "Configuration saved to $CONFIG_FILE"
    echo "TermuxCoder setup complete!"
}

# Main command dispatcher
main() {
    # Handle empty command
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    # Parse command
    COMMAND="$1"
    shift
    
    case "$COMMAND" in
        ask)
            [[ $# -eq 0 ]] && { echo "Error: No prompt specified."; exit 1; }
            check_api_key || exit 1
            "$(dirname "$0")/bin/ask.sh" "$@"
            ;;
        plan)
            [[ $# -eq 0 ]] && { echo "Error: No task specified."; exit 1; }
            check_api_key || exit 1
            "$(dirname "$0")/bin/plan.sh" "$@"
            ;;
        fix)
            [[ $# -eq 0 ]] && { echo "Error: No file specified."; exit 1; }
            check_api_key || exit 1
            "$(dirname "$0")/bin/fix.sh" "$@"
            ;;
        run)
            [[ $# -eq 0 ]] && { echo "Error: No file specified."; exit 1; }
            "$(dirname "$0")/bin/run.sh" "$@"
            ;;
        edit)
            [[ $# -lt 1 ]] && { echo "Error: No file specified."; exit 1; }
            check_api_key || exit 1
            "$(dirname "$0")/bin/edit.sh" "$@"
            ;;
        save)
            "$(dirname "$0")/bin/save.sh" "$@"
            ;;
        setup)
            setup
            ;;
        help)
            show_help
            ;;
        version)
            show_version
            ;;
        *)
            echo "Error: Unknown command '$COMMAND'."
            echo "Run 'termuxcoder help' for usage information."
            exit 1
            ;;
    esac
}

# Run the main function with all arguments
main "$@"
