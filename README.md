# zsh-ollama-command zsh plugin

Ollama for zsh

<img src="demo.svg" alt="Kollzsh Demo" width="600">

An [`oh-my-zsh`](https://ohmyz.sh) plugin that integrates the OLLAMA AI model
with [fzf](https://github.com/junegunn/fzf) to provide intelligent command
suggestions based on user input requirements.

## Features

- **Intelligent Command Suggestions**: Use OLLAMA to generate relevant MacOS and Linux
  terminal commands based on your query or input requirement.
- **FZF Integration**: Interactively select suggested commands using FZF's fuzzy
  finder, ensuring you find the right command for your task.
- **Customizable**: Configure default shortcut, OLLAMA model, and response number
  to suit your workflow.

## Setup

### Requirements

- `fzf` for interactive selection of commands (type `brew install fzf` or `sudo apt install fzf`)
- `ollama` server running (visit [https://ollama.com/download](https://ollama.com/download)
- `python3` with a virtual env with installed ollama package. You can setup it with eg:

```
# Create
python3 -m venv ~/.venvs/ollama
# Activate
. ~/.venvs/ollama/bin/activate
# Install ollama package
pip install ollama

```

Then following this example you should set `KOLLZSH_PYTHON3` to `~/.venvs/ollama/bin/python3`

### Configuration Variables

| Variable Name           | Default Value            | Description                                    |
| ----------------------- | ------------------------ | ---------------------------------------------- |
| `ZSH_OLLAMA_MODEL`         | `qwen2.5-coder:3b`       | OLLAMA model to use (e.g., `qwen2.5-coder:3b`) |
| `ZSH_OLLAMA_HOTKEY`        | `^o` (Ctrl-o)            | Default shortcut key for triggering the plugin |
| `ZSH_OLLAMA_COMMAND_COUNT` | `5`                      | Number of command suggestions displayed        |
| `ZSH_OLLAMA_URL`           | `http://localhost:11434` | The URL of OLLAMA server host                  |
| `ZSH_OLLAMA_KEEP_ALIVE`    | `1h`                     | The time to keep the OLLAMA server alive       |
| `ZSH_OLLAMA_PYTHON3`       | `/usr/bin/python3`       | Python interpreter to use (set with your env)  |

### Usage

1. Clone the repository to `oh-my-zsh` custom plugin folder

   ```bash
   git clone https://github.com/kstopa/zsh-ollama-command.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ollama-command
   ```

2. Enable the plugin in ~/.zshrc:

   ```bash
   plugins=(
     [plugins...]
     zsh-ollama-command
   )
   ```

3. Set the desirable variables

   ```bash
   ZSH_OLLAMA_MODEL="qwen2.5-coder:3b"
   ZSH_OLLAMA_HOTKEY="^o"
   ZSH_OLLAMA_COMMAND_COUNT=5
   ZSH_OLLAMA_URL="http://localhost:11434"
   ZSH_OLLAMA_KEEP_ALIVE="1h"
   ZSH_OLLAMA_PYTHON3="python3"
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
