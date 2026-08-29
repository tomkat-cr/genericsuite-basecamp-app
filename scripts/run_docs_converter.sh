#!/bin/bash
# run_docs_converter.sh
# 2026-01-21 | CR

# Create virtual environment and install dependencies
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
    .venv/bin/pip install pyyaml openai
fi

# Update the git module
if [ "${GS_BASECAMP_PATH}" = "" ]; then
    GS_BASECAMP_REPO_URL="https://github.com/tomkat-cr/genericsuite-basecamp"
    GS_BASECAMP_PATH="./genericsuite-basecamp"
    BRANCH="${BRANCH:-develop}" # main or develop (default)
    SUBMODULE="${SUBMODULE:-0}" # 1 = add submodule, 0 = clone repository (default)
    if [ ! -d "${GS_BASECAMP_PATH}" ]; then
        if [ "${SUBMODULE}" = "1" ]; then
            if ! git submodule add "${GS_BASECAMP_REPO_URL}.git" "${GS_BASECAMP_PATH}"
            then
                echo "Error: Could not add submodule ${GS_BASECAMP_PATH}"
                exit 1
            fi
        else
            if ! git clone "${GS_BASECAMP_REPO_URL}.git" "${GS_BASECAMP_PATH}"
            then
                echo "Error: Could not clone repository ${GS_BASECAMP_PATH}"
                exit 1
            fi
        fi
        cd "${GS_BASECAMP_PATH}"
        git checkout "${BRANCH}"
        cd ..
    else
        cd "${GS_BASECAMP_PATH}"
        git pull
        cd ..
    fi
fi

# Load .env
if [ ! -f ".env" ]; then
    cp .env.example .env
fi
set -a
source ./.env
set +a

# Run the converter
.venv/bin/python3 scripts/docs_converter.py --repo_path "${GS_BASECAMP_PATH}"
