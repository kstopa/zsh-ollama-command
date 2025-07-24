#!/usr/bin/env python3
import logging
import os
import sys

from ollama import Client
from pydantic import BaseModel


class Command(BaseModel):
    command: str
    description: str


class CommandList(BaseModel):
    commands: list[Command]


# Configure logging
LOG_FILE = "/tmp/zsh_ollama_debug.log"
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.DEBUG,
    format="[%(asctime)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)


def log_debug(message, data=None):
    """Log debug message with optional data."""
    if data:
        logging.debug(
            f"{message}\nData: {data}\n----------------------------------------"
        )
    else:
        logging.debug(message)


def interact_with_ollama(user_query):
    """Interact with the Ollama server and retrieve command suggestions."""
    client = Client(host=os.environ["ZSH_OLLAMA_URL"])
    log_debug("Sending query to Ollama:", user_query)

    # Format the user query to focus on shell commands
    formatted_query = (
        f"Generate shell commands for the following task: {user_query}. \n"
        "Provide multiple relevant commands if available. \n"
        "Output in JSON format with markdown-wrapped JSON. \n"
        "The JSON needs to include a key named 'commands' with a list of commands. \n"
    )

    try:
        response = client.chat(
            model=os.environ["ZSH_OLLAMA_MODEL"],
            keep_alive=os.environ["ZSH_OLLAMA_KEEP_ALIVE"],
            messages=[{"role": "user", "content": formatted_query}],
            stream=False,
            format=CommandList.model_json_schema(),
        )
        log_debug("Received response from Ollama:", response)

        # Fallback to parsing content if no tool calls
        content = (
            response.message.content if hasattr(response.message, "content") else ""
        )
        if content:
            log_debug("No tool calls found, falling back to content parsing")
            return parse_ollama_response(content)

        log_debug("No valid commands found in response")
        return []

    except Exception as e:
        log_debug(f"Error interacting with Ollama: {str(e)}")
        return []


def parse_ollama_response(content):
    cleaned_commands = []
    commands = CommandList.model_validate_json(content)
    for cmd in commands.commands:
        cleaned_commands.append(normalize_json_string(cmd.command))
    return cleaned_commands


def normalize_json_string(content):
    """Normalize JSON string by handling escapes and newlines."""
    # Handle control characters
    content = content.replace("\n", " ")
    content = content.replace("\r", " ")
    content = content.replace("\t", " ")

    # Remove prompt characters
    if content.startswith("$") or content.startswith(">") or content.startswith("#"):
        content = content[1:]

    # Handle escaped characters
    content = content.replace('\\"', '"')  # Temporarily unescape quotes
    content = content.replace("\\\\", "\\")  # Fix double escapes
    content = content.replace('"', '\\"')  # Re-escape all quotes

    # Clean up whitespace
    content = " ".join(content.split())

    log_debug("Normalized JSON string:", content)
    return content


if __name__ == "__main__":
    if len(sys.argv) != 2:
        log_debug("Usage: ollama_util.py <user_query>")
        sys.exit(1)

    user_query = sys.argv[1]
    commands = interact_with_ollama(user_query)

    if not commands:
        log_debug("No valid commands found")
        sys.exit(1)

    # Print each command on a new line
    for cmd in commands:
        print(cmd)

    log_debug("Successfully output commands")
