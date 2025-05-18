#!/usr/bin/env bash
#
# TermuxCoder - Ask command implementation
#

# Load utility functions
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/utils.sh"

# Display usage
usage() {
    cat << EOF
Usage: termuxcoder ask [OPTIONS] PROMPT

Send a prompt to Gemini and display the response.

Options:
  -s, --save FILENAME    Save the response to a file
  -e, --extract          Extract and save code blocks from the response
  -d, --dir DIRECTORY    Directory to save extracted code blocks (default: current directory)
  -h, --help             Show this help message

Examples:
  termuxcoder ask "Write a Python function to sort a list"
  termuxcoder ask -e "Create a simple React component"
  termuxcoder ask -e -d ~/projects "Create an Express.js API"
  termuxcoder ask -s answer.txt "Explain Docker containers"
EOF
}

# Main function
main() {
    # Default values
    local save_file=""
    local extract_code=0
    local extract_dir="$(pwd)"
    local prompt=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--save)
                save_file="$2"
                shift 2
                ;;
            -e|--extract)
                extract_code=1
                shift
                ;;
            -d|--dir)
                extract_dir="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                # If prompt is already set, append to it
                if [[ -n "$prompt" ]]; then
                    prompt="$prompt $1"
                else
                    prompt="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Check if prompt is provided
    if [[ -z "$prompt" ]]; then
        print_error "No prompt provided."
        usage
        exit 1
    fi
    
    # Log the prompt
    log_message "Ask: $prompt"
    
    # Display header
    print_color "$BLUE" "🧠 Thinking..."
    printf '\n'
    
    # Call the Gemini API and capture the response
    local response
    response=$(call_gemini_api "$prompt" | tee >(cat > "$LASTOUTPUT_FILE"))
    
    # Check if the API call was successful
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    
    # Print a divider
    print_color "$CYAN" "────────────────────────────────────────────────────────────────────"
    
    # Handle code block extraction
    if [[ $extract_code -eq 1 ]]; then
        printf '\n'
        print_color "$PURPLE" "🔍 Extracting code blocks..."
        
        # Extract and save code blocks
        extract_code_blocks "$LASTOUTPUT_FILE" "$extract_dir"
        local code_block_count=$?
        
        if [[ $code_block_count -gt 0 ]]; then
            print_success "✅ Extracted $code_block_count code blocks to $extract_dir"
        else
            print_warning "⚠️  No code blocks found in the response."
        fi
    fi
    
    # Save the response to a file if requested
    if [[ -n "$save_file" ]]; then
        save_output "$save_file"
    fi
    
    # Print completion message
    printf '\n'
    print_color "$GREEN" "✅ Response received from Gemini (${model:-gemini-1.5-pro})"
}

# Run the main function
main "$@"
