#!/bin/bash
# run_docs_converter.sh
# 2026-01-21 | CR

# Create virtual environment and install dependencies
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
    .venv/bin/pip install pyyaml
fi

# Update the git module
if [ ! -d "./genericsuite-basecamp" ]; then
    git submodule add https://github.com/tomkat-cr/genericsuite-basecamp.git genericsuite-basecamp
    cd genericsuite-basecamp
    git checkout main
    cd ..
else
    cd genericsuite-basecamp
    git pull
    cd ..
fi

# Run the converter
.venv/bin/python3 scripts/docs_converter.py --repo_path ./genericsuite-basecamp
