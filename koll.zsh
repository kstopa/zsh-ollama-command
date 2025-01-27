# default shortcut as Ctrl-o
(( ! ${+KOLLZSH_HOTKEY} )) && typeset -g KOLLZSH_HOTKEY='^o'
# default ollama model as qwen2.5-coder:3b
(( ! ${+KOLLZSH_MODEL} )) && typeset -g KOLLZSH_MODEL='qwen2.5-coder:3b'
# default response number as 5
(( ! ${+KOLLZSH_COMMAND_COUNT} )) && typeset -g KOLLZSH_COMMAND_COUNT='5'
# default ollama server host
(( ! ${+KOLLZSH_URL} )) && typeset -g KOLLZSH_URL='http://localhost:11434'

# Source utility functions
source "${0:A:h}/utils.zsh"

# Set up logging with proper permissions
KOLLZSH_LOG_FILE="/tmp/kollzsh_debug.log"
touch "$KOLLZSH_LOG_FILE"
chmod 666 "$KOLLZSH_LOG_FILE"

log_debug() {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  {
    echo "[${timestamp}] $1"
    if [ -n "$2" ]; then
      echo "Data: $2"
      echo "----------------------------------------"
    fi
  } >> "$KOLLZSH_LOG_FILE" 2>&1
}

validate_required() {
  # Check required tools are installed
  check_command "jq" || return 1
  check_command "fzf" || return 1
  check_command "curl" || return 1
  
  # Check if Ollama is running
  check_ollama_running || return 1
  
  # Check if the specified model exists
  if ! curl -s "${KOLLZSH_URL}/api/tags" | grep -q $KOLLZSH_MODEL; then
    echo "🚨 Model ${KOLLZSH_MODEL} not found!"
    echo "Please pull it with: ollama pull ${KOLLZSH_MODEL}"
    return 1
  fi
}

fzf_kollzsh() {
  setopt extendedglob
  validate_required
  if [ $? -eq 1 ]; then
    return 1
  fi

  KOLLZSH_USER_QUERY=$BUFFER

  zle end-of-line
  zle reset-prompt

  print
  print -u1 "👻Please wait..."

  KOLLZSH_MESSAGE_CONTENT="Seeking OLLAMA for $(detect_os) terminal commands for the following task: $KOLLZSH_USER_QUERY. Reply with a JSON array without newlines consisting solely of possible commands. The format must use double quotes like this: [\"command1; command2;\", \"command3&command4;\"] - do not use single quotes. Response only contains array, no any additional description. No additional text should be present in each entry and commands, remove empty string entry. Each string entry should be a new string entry. If the task need more than one command, combine them in one string entry. Each string entry should only contain the command(s). Do not include empty entry. Provide multiple entry (at most $KOLLZSH_COMMAND_COUNT relevant entry) in response Json suggestions if available. Please ensure response can be parsed by jq"

  # Properly escape the message content for JSON
  KOLLZSH_MESSAGE_CONTENT_ESCAPED=$(echo "$KOLLZSH_MESSAGE_CONTENT" | sed 's/"/\\"/g')

  KOLLZSH_REQUEST_BODY=$(cat <<EOF
{
  "model": "$KOLLZSH_MODEL",
  "messages": [
    {
      "role": "user",
      "content": "$KOLLZSH_MESSAGE_CONTENT_ESCAPED"
    }
  ],
  "stream": false
}
EOF
)

  KOLLZSH_RESPONSE=$(curl --silent "${KOLLZSH_URL}/api/chat" \
    -H "Content-Type: application/json" \
    -d "$KOLLZSH_REQUEST_BODY")
  local ret=$?

  if [ $ret -ne 0 ]; then
    log_debug "Curl request failed with status: $ret"
    echo "Error: Failed to get response from Ollama"
    return 1
  fi

  log_debug "Raw Ollama response:" "$KOLLZSH_RESPONSE"

  # First extract just the content field from the response
  TEMP_JSON=$(mktemp)
  echo "$KOLLZSH_RESPONSE" | jq -r '.message.content' > "$TEMP_JSON"
  
  if [ $? -ne 0 ] || [ ! -s "$TEMP_JSON" ]; then
    log_debug "Failed to extract message content"
    echo "Error: Failed to extract message content"
    rm "$TEMP_JSON"
    return 1
  fi
  
  # Clean up markdown formatting and convert to proper JSON
  CLEANED_CONTENT=$(cat "$TEMP_JSON" | 
    sed -E 's/^```json[[:space:]]*//' |  # Remove leading ```json and any whitespace
    sed -E 's/[[:space:]]*```[[:space:]]*$//' |  # Remove trailing ``` and any whitespace
    sed -E "s/'/\"/g" |  # Convert single quotes to double quotes
    tr -d '\n\r')  # Remove all newlines and carriage returns
  
  log_debug "Cleaned content:" "$CLEANED_CONTENT"
  
  # Write cleaned content to temp file for jq processing
  echo "$CLEANED_CONTENT" > "$TEMP_JSON"
  
  # Validate it's a proper JSON array
  if ! jq -e 'type == "array"' "$TEMP_JSON" >/dev/null 2>&1; then
    log_debug "Not a valid JSON array:" "$CLEANED_CONTENT"
    echo "Error: Response is not a valid array of commands"
    rm "$TEMP_JSON"
    return 1
  fi

  # Extract commands
  KOLLZSH_COMMANDS=$(jq -r '.[]' "$TEMP_JSON")
  if [ $? -ne 0 ] || [ -z "$KOLLZSH_COMMANDS" ]; then
    log_debug "Failed to extract commands from array"
    echo "Error: Failed to extract command suggestions"
    rm "$TEMP_JSON"
    return 1
  fi
  
  log_debug "Extracted commands:" "$KOLLZSH_COMMANDS"
  rm "$TEMP_JSON"

  tput cuu 1 # cleanup waiting message

  # Use echo to pipe the commands to fzf
  KOLLZSH_SELECTED=$(echo "$KOLLZSH_COMMANDS" | fzf --ansi --height=~10 --cycle)
  if [ -n "$KOLLZSH_SELECTED" ]; then
    BUFFER="$KOLLZSH_SELECTED"
    CURSOR=${#BUFFER}  # Move cursor to end of buffer
    
    # Ensure we're not accepting the line
    zle -R
    zle reset-prompt
    
    log_debug "Selected command:" "$KOLLZSH_SELECTED"
  else
    log_debug "No command selected"
  fi
  
  return 0
}

validate_required

autoload -U fzf_kollzsh
zle -N fzf_kollzsh
bindkey "$KOLLZSH_HOTKEY" fzf_kollzsh
