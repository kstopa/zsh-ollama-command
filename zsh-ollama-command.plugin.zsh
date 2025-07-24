# default shortcut as Ctrl-o
(( ! ${+ZSH_OLLAMA_HOTKEY} )) && typeset -g ZSH_OLLAMA_HOTKEY='^o'
# default ollama model as qwen2.5-coder:3b
(( ! ${+ZSH_OLLAMA_MODEL} )) && typeset -g ZSH_OLLAMA_MODEL='qwen2.5-coder:3b'
# default response number as 5
(( ! ${+ZSH_OLLAMA_COMMAND_COUNT} )) && typeset -g ZSH_OLLAMA_MODEL_COMMAND_COUNT='5'
# default ollama server host
(( ! ${+ZSH_OLLAMA_URL} )) && typeset -g ZSH_OLLAMA_URL='http://localhost:11434'
# default ollama time to keep the server alive
(( ! ${+ZSH_OLLAMA_KEEP_ALIVE} )) && typeset -g ZSH_OLLAMA_KEEP_ALIVE='1h'
# default python3 path
(( ! ${+ZSH_OLLAMA_PYTHON3} )) && typeset -g ZSH_OLLAMA_PYTHON3='python3'

# Source utility functions
source "${0:A:h}/utils.zsh"

# Set up logging with proper permissions
ZSH_OLLAMA_LOG_FILE="/tmp/zsh_ollama_debug.log"
touch "$ZSH_OLLAMA_LOG_FILE"
chmod 666 "$ZSH_OLLAMA_LOG_FILE"

log_debug() {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  {
    echo "[${timestamp}] $1"
    if [ -n "$2" ]; then
      echo "Data: $2"
      echo "----------------------------------------"
    fi
  } >> "$ZSH_OLLAMA_LOG_FILE" 2>&1
}

validate_required() {
  # Check required tools are installed
  check_command "jq" || return 1
  check_command "fzf" || return 1
  check_command "curl" || return 1
  check_command $ZSH_OLLAMA_PYTHON3 || return 1
  
  # Check if Ollama is running
  check_ollama_running || return 1
  
  # Check if the specified  exists
  if ! curl -s "${ZSH_OLLAMA_URL}/api/tags" | grep -q $ZSH_OLLAMA_MODEL; then
    echo "🚨 Model ${ZSH_OLLAMA_MODEL} not found!"
    echo "Please pull it with: ollama pull ${ZSH_OLLAMA_MODEL}"
    return 1
  fi
}

fzf_kollzsh() {
  setopt extendedglob
  validate_required
  if [ $? -eq 1 ]; then
    return 1
  fi

  ZSH_OLLAMA_USER_QUERY=$BUFFER

  zle end-of-line
  zle reset-prompt

  print
  print -u1 "👻Please wait..."

  log_debug "Raw Ollama response:" "$ZSH_OLLAMA_RESPONSE"

  # Export necessary environment variables to be used by the python script
  export ZSH_OLLAMA_URL
  export ZSH_OLLAMA_COMMAND_COUNT
  export ZSH_OLLAMA_MODEL
  export ZSH_OLLAMA_KEEP_ALIVE

  # Get absolute path to the script directory
  PLUGIN_DIR=${${(%):-%x}:A:h}
  ZSH_OLLAMA_COMMANDS=$( "$ZSH_OLLAMA_PYTHON3" "$PLUGIN_DIR/ollama_util.py" "$ZSH_OLLAMA_USER_QUERY")
 
  # Check if the command was successful and that the commands is an array
  if [ $? -ne 0 ] || [ -z "$ZSH_OLLAMA_COMMANDS" ]; then
    log_debug "Failed to parse commands"
    echo "Error: Failed to parse commands"
    echo "Raw response:"
    echo "$ZSH_OLLAMA_COMMANDS"
    return 0
  fi
  
  log_debug "Extracted commands:" "$ZSH_OLLAMA_COMMANDS"

  tput cuu 1 # cleanup waiting message

  # Use echo to pipe the commands to fzf
  ZSH_OLLAMA_SELECTED=$(echo "$ZSH_OLLAMA_COMMANDS" | fzf --ansi --height=~10 --cycle)
  if [ -n "$ZSH_OLLAMA_SELECTED" ]; then
    BUFFER="$ZSH_OLLAMA_SELECTED"
    CURSOR=${#BUFFER}  # Move cursor to end of buffer
    
    # Ensure we're not accepting the line
    zle -R
    zle reset-prompt
    
    log_debug "Selected command:" "$ZSH_OLLAMA_SELECTED"
  else
    log_debug "No command selected"
  fi
  
  return 0
}

autoload -U fzf_kollzsh
zle -N fzf_kollzsh
bindkey "$ZSH_OLLAMA_HOTKEY" fzf_kollzsh
