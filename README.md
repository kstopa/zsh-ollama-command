# koll.zsh

```
  :###:
  :   :
  :   :
.'     '.
:       :
|_______|
|kollzsh|
|‐‐‐‐‐‐‐|
|       |
:_______:
```

koll.zsh: keyvez ollama for zsh

<img src="demo.svg" alt="Kollzsh Demo" width="600">

An [`oh-my-zsh`](https://ohmyz.sh) plugin that integrates the OLLAMA AI model
with [fzf](https://github.com/junegunn/fzf) to provide intelligent command
suggestions based on user input requirements.

## Features

- **Intelligent Command Suggestions**: Use OLLAMA to generate relevant MacOS
  terminal commands based on your query or input requirement.
- **FZF Integration**: Interactively select suggested commands using FZF's fuzzy
  finder, ensuring you find the right command for your task.
- **Customizable**: Configure default shortcut, OLLAMA model, and response number
  to suit your workflow.

## Requirements

- `jq` for parsing JSON responses
- `fzf` for interactive selection of commands
- `curl` for making API requests
- `OLLAMA` server running

## Configuration Variables

| Variable Name           | Default Value            | Description                                    |
| ----------------------- | ------------------------ | ---------------------------------------------- |
| `KOLLZSH_MODEL`         | `qwen2.5-coder:3b`       | OLLAMA model to use (e.g., `qwen2.5-coder:3b`) |
| `KOLLZSH_HOTKEY`        | `^o` (Ctrl-o)            | Default shortcut key for triggering the plugin |
| `KOLLZSH_COMMAND_COUNT` | `5`                      | Number of command suggestions displayed        |
| `KOLLZSH_URL`           | `http://localhost:11434` | The URL of OLLAMA server host                  |
| `KOLLZSH_KEEP_ALIVE`    | `1h`                     | The time to keep the OLLAMA server alive       |

## Usage

1. Clone the repository to `oh-my-zsh` custom plugin folder

   ```bash
   git clone https://github.com/krugergui/kollzsh.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/kollzsh
   ```

2. Enable the plugin in ~/.zshrc:

   ```bash
   plugins=(
     [plugins...]
     kollzsh
   )
   ```

3. Set the desirable variables

   ```bash
   KOLLZSH_MODEL="qwen2.5-coder:3b"
   KOLLZSH_HOTKEY="^o"
   KOLLZSH_COMMAND_COUNT=5
   KOLLZSH_URL="http://localhost:11434"
   KOLLZSH_KEEP_ALIVE="1h"
   ```

4. Input what you want to do then trigger the plugin. Press the custom shortcut (default is Ctrl-o) to start
   the command suggestion process.

5. Interact with FZF: Type a query or input requirement, and FZF will display
   suggested MacOS terminal commands. Select one to execute.

**Get Started**

Experience the power of AI-driven command suggestions in your MacOS terminal! This
plugin is perfect for developers, system administrators, and anyone looking to
streamline their workflow.

Let me know if you have any specific requests or changes!

![Kollzsh Beer](kollzsh_beer.png)
