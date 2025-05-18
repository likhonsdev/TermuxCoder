#!/usr/bin/env bash
#
# TermuxCoder - Plan command implementation
#

# Load utility functions
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/utils.sh"

# Display usage
usage() {
    cat << EOF
Usage: termuxcoder plan [OPTIONS] TASK

Generate a task plan for complex coding queries.

Options:
  -s, --save FILENAME    Save the plan to a file
  -d, --detailed         Request a more detailed plan
  -h, --help             Show this help message

Examples:
  termuxcoder plan "Create a RESTful API with Node.js"
  termuxcoder plan -d "Build a full-stack web application"
  termuxcoder plan -s project_plan.md "Build a mobile app with React Native"
EOF
}

# Main function
main() {
    # Default values
    local save_file=""
    local detailed=0
    local task=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--save)
                save_file="$2"
                shift 2
                ;;
            -d|--detailed)
                detailed=1
                shift
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
                # If task is already set, append to it
                if [[ -n "$task" ]]; then
                    task="$task $1"
                else
                    task="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Check if task is provided
    if [[ -z "$task" ]]; then
        print_error "No task provided."
        usage
        exit 1
    fi
    
    # Log the task
    log_message "Plan: $task"
    
    # Prepare prompt for detailed or regular plan
    local prompt
    if [[ $detailed -eq 1 ]]; then
        prompt="Create a detailed step-by-step plan for the following task. Include specific technologies, file structures, and implementation details where appropriate. Break the plan into phases and provide estimated time for each phase. TASK: $task"
    else
        prompt="Create a step-by-step plan for the following coding task. Break it down into logical phases and steps. TASK: $task"
    fi
    
    # Display header
    print_color "$PURPLE" "🔍 Generating plan for: $task"
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
    
    # Save the response to a file if requested
    if [[ -n "$save_file" ]]; then
        save_output "$save_file"
    fi
    
    # Print completion message
    printf '\n'
    print_color "$GREEN" "✅ Plan generated successfully"
}

# Run the main function
main "$@"
