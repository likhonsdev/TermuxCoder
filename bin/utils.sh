#!/usr/bin/env bash
#
# TermuxCoder - Utility functions
#

# Configuration
CONFIG_FILE="$(dirname "$(dirname "$0")")/config.json"
LOGS_DIR="$(dirname "$(dirname "$0")")/logs"
LASTOUTPUT_FILE="/tmp/termuxcoder_lastoutput.txt"

# ANSI color codes
export RED="\033[0;31m"
export GREEN="\033[0;32m"
export YELLOW="\033[0;33m"
export BLUE="\033[0;34m"
export PURPLE="\033[0;35m"
export CYAN="\033[0;36m"
export WHITE="\033[0;37m"
export BOLD="\033[1m"
export UNDERLINE="\033[4m"
export RESET="\033[0m"

# Print colored text
print_color() {
    local color="$1"
    local text="$2"
    echo -e "${color}${text}${RESET}"
}

# Print error message
print_error() {
    print_color "$RED" "ERROR: $1" >&2
}

# Print success message
print_success() {
    print_color "$GREEN" "$1"
}

# Print info message
print_info() {
    print_color "$CYAN" "$1"
}

# Print warning message
print_warning() {
    print_color "$YELLOW" "$1"
}

# Log message to file
log_message() {
    local log_file="$LOGS_DIR/termuxcoder_$(date +%Y-%m-%d).log"
    mkdir -p "$LOGS_DIR"
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$log_file"
}

# Get config value
get_config() {
    local key="$1"
    local default="$2"
    
    if [[ -f "$CONFIG_FILE" ]] && command -v jq >/dev/null; then
        local value
        value=$(jq -r ".$key" "$CONFIG_FILE" 2>/dev/null)
        if [[ "$value" == "null" || -z "$value" ]]; then
            echo "$default"
        else
            echo "$value"
        fi
    else
        echo "$default"
    fi
}

# Set config value
set_config() {
    local key="$1"
    local value="$2"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "{}" > "$CONFIG_FILE"
    fi
    
    if command -v jq >/dev/null; then
        jq --arg key "$key" --arg val "$value" '.[$key] = $val' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    else
        print_error "jq is not installed. Cannot update configuration."
        return 1
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Prompt user for confirmation (y/n)
confirm() {
    local msg="$1"
    local default="${2:-n}"
    local prompt
    
    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi
    
    read -p "$msg $prompt " answer
    answer=${answer:-$default}
    
    [[ "$answer" =~ ^[Yy] ]]
}

# Get API key from config
get_api_key() {
    get_config "api_key" ""
}

# Make API request to Gemini
call_gemini_api() {
    local prompt="$1"
    local model
    local api_key
    local max_tokens
    local temperature
    
    # Get config values
    api_key=$(get_api_key)
    model=$(get_config "model" "gemini-1.5-pro")
    max_tokens=$(get_config "max_tokens" "8192")
    temperature=$(get_config "temperature" "0.7")
    
    if [[ -z "$api_key" ]]; then
        print_error "API key not found in config. Please run 'termuxcoder setup' first."
        return 1
    fi
    
    # Prepare request data
    local request_data='{
        "contents": [
            {
                "role": "user",
                "parts": [
                    {
                        "text": "'"${prompt//\"/\\\"}"'"
                    }
                ]
            }
        ],
        "generationConfig": {
            "maxOutputTokens": '"$max_tokens"',
            "temperature": '"$temperature"'
        }
    }'
    
    # Log API request (without sensitive data)
    log_message "API Request to model: $model"
    
    # Check if we can use python client
    if [[ -f "$(dirname "$(dirname "$0")")/models/gemini_client.py" ]] && command_exists python3; then
        python3 "$(dirname "$(dirname "$0")")/models/gemini_client.py" "$api_key" "$model" "$prompt" "$temperature" "$max_tokens"
        return $?
    fi
    
    # Fallback to curl if python client is not available
    if command_exists curl; then
        # Create temp file for response
        local tmp_response
        tmp_response=$(mktemp)
        
        # Send request to Gemini API
        curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $api_key" \
            -d "$request_data" > "$tmp_response"
        
        # Check for errors
        if grep -q "error" "$tmp_response"; then
            local error
            error=$(jq -r '.error.message // "Unknown error"' "$tmp_response" 2>/dev/null)
            print_error "API request failed: $error"
            rm -f "$tmp_response"
            return 1
        fi
        
        # Extract and display response content
        jq -r '.candidates[0].content.parts[0].text' "$tmp_response" 2>/dev/null
        
        # Clean up
        rm -f "$tmp_response"
    else
        print_error "curl not found. Please install curl to continue."
        return 1
    fi
}

# Extract code blocks from markdown
extract_code_blocks() {
    local file="$1"
    local output_dir="${2:-$(pwd)}"
    local text
    
    if [[ ! -f "$file" ]]; then
        text="$1"
    else
        text=$(cat "$file")
    fi
    
    # Temporary file for processing
    local tmp_file
    tmp_file=$(mktemp)
    echo "$text" > "$tmp_file"
    
    # Extract code blocks with language specifiers
    local block_count=0
    local in_block=0
    local current_block=""
    local language=""
    local filename=""
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^[\`]{3}([a-zA-Z0-9+]+)$ ]]; then
            # Start of a code block with language
            in_block=1
            language="${BASH_REMATCH[1]}"
            current_block=""
            continue
        elif [[ "$line" =~ ^[\`]{3}$ ]]; then
            # End of a code block
            if [[ $in_block -eq 1 ]]; then
                ((block_count++))
                
                # Determine file extension based on language
                local extension=""
                case "$language" in
                    python|py) extension="py" ;;
                    javascript|js) extension="js" ;;
                    typescript|ts) extension="ts" ;;
                    bash|sh) extension="sh" ;;
                    c) extension="c" ;;
                    cpp) extension="cpp" ;;
                    java) extension="java" ;;
                    go) extension="go" ;;
                    rust|rs) extension="rs" ;;
                    html) extension="html" ;;
                    css) extension="css" ;;
                    json) extension="json" ;;
                    yaml|yml) extension="yml" ;;
                    xml) extension="xml" ;;
                    sql) extension="sql" ;;
                    markdown|md) extension="md" ;;
                    *) extension="txt" ;;
                esac
                
                # Check if code block has a filename comment
                if [[ "$current_block" =~ ^[\#\/]+\ *([a-zA-Z0-9_\.\-\/]+) ]]; then
                    filename="${BASH_REMATCH[1]}"
                    # Remove the filename line from the code block
                    current_block=$(echo "$current_block" | tail -n +2)
                else
                    filename="code_block_${block_count}.${extension}"
                fi
                
                # Save code block to file
                mkdir -p "$output_dir/$(dirname "$filename")"
                echo "$current_block" > "$output_dir/$filename"
                echo "$filename"
            fi
            in_block=0
            continue
        fi
        
        if [[ $in_block -eq 1 ]]; then
            current_block+="$line"$'\n'
        fi
    done < "$tmp_file"
    
    rm -f "$tmp_file"
    
    return $block_count
}

# Save output to last output file
save_last_output() {
    cat > "$LASTOUTPUT_FILE"
}

# Save output to specified file
save_output() {
    local filename="$1"
    if [[ -f "$LASTOUTPUT_FILE" ]]; then
        mkdir -p "$LOGS_DIR"
        cp "$LASTOUTPUT_FILE" "$LOGS_DIR/$filename"
        print_success "Output saved to $LOGS_DIR/$filename"
    else
        print_error "No output to save"
        return 1
    fi
}

# Display a spinner for long-running processes
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p "$pid" > /dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Display progress bar
progress_bar() {
    local current=$1
    local total=$2
    local width=${3:-50}
    
    # Calculate percentage
    local percent=$((current * 100 / total))
    local completed=$((width * percent / 100))
    
    # Build the bar
    local bar="["
    for ((i=0; i<completed; i++)); do
        bar+="="
    done
    if [[ $completed -lt $width ]]; then
        bar+=">"
        for ((i=completed+1; i<width; i++)); do
            bar+=" "
        done
    fi
    bar+="] ${percent}%"
    
    # Print the bar
    echo -ne "\r$bar"
    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

# Make a script executable
make_executable() {
    local file="$1"
    chmod +x "$file" 2>/dev/null || {
        print_warning "Could not make $file executable. You may need to run 'chmod +x $file' manually."
        return 1
    }
    return 0
}
