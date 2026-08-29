#!/bin/bash
# ./scripts/open-android-emulator.sh
# 2026-04-19 | CR
# Open the Android Simulator. If the AVD_NAME envvar is not supplied, looks for the first device in the AVD list
#
if [ -z "${AVD_NAME}" ]; then
	${HOME}/Library/Android/sdk/emulator/emulator -list-avds
	AVD_NAME=$(${HOME}/Library/Android/sdk/emulator/emulator -list-avds | head -n 1)
fi
echo ""
echo "Running: ${AVD_NAME}"
echo ""
${HOME}/Library/Android/sdk/emulator/emulator -avd "${AVD_NAME}"
