# default shortcut as Ctrl-o
(( ! ${+KOLLZSH_HOTKEY} )) && typeset -g KOLLZSH_HOTKEY='^o'
# default ollama model as qwen2.5-coder:3b
(( ! ${+KOLLZSH_MODEL} )) && typeset -g KOLLZSH_MODEL='qwen2.5-coder:3b'
# default response number as 5
(( ! ${+KOLLZSH_COMMAND_COUNT} )) && typeset -g KOLLZSH_COMMAND_COUNT='5'
# default ollama server host
(( ! ${+KOLLZSH_URL} )) && typeset -g KOLLZSH_URL='http://localhost:11434'
# default ollama time to keep the server alive
(( ! ${+KOLLZSH_KEEP_ALIVE} )) && typeset -g KOLLZSH_KEEP_ALIVE='1h'

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
  check_command "python3" || return 1
  
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

  log_debug "Raw Ollama response:" "$KOLLZSH_RESPONSE"

  # Export necessary environment variables to be used by the python script
  export KOLLZSH_URL
  export KOLLZSH_COMMAND_COUNT
  export KOLLZSH_MODEL
  export KOLLZSH_KEEP_ALIVE

  # Get absolute path to the script directory
  PLUGIN_DIR=${${(%):-%x}:A:h}
  KOLLZSH_COMMANDS=$(python3 "$PLUGIN_DIR/ollama_util.py" "$KOLLZSH_USER_QUERY")
  
  if [ $? -ne 0 ] || [ -z "$KOLLZSH_COMMANDS" ]; then
    log_debug "Failed to parse commands"
    echo "Error: Failed to parse commands"
    return 1
  fi
  
  log_debug "Extracted commands:" "$KOLLZSH_COMMANDS"

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
