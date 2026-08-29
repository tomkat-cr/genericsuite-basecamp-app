#!/bin/bash

# Create virtual environment and install dependencies
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
    .venv/bin/pip install pyyaml openai
fi

# Run the translation script
.venv/bin/python3 scripts/translate_uncommitted.py
