#!/bin/bash
# Arguments:
# 1. Branch name (optional): The Git branch to check for updates.
#    Defaults to 'main'.
# 2. Server REST API URL (optional): The base URL for the server's
#    REST API. Defaults to 'https://bicycledata.ochel.se:80'.

#
# Update this script - bicycleinit.sh

sleep 10

# Navigate to the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Define the branch to check for updates (default to main)
BRANCH=${1:-main}

# REST API URL (replace with your actual API endpoint)
API_URL=${2:-"https://bicycledata.ochel.se:80"}"/api"

echo "" >> bicycleinit.log
date >> bicycleinit.log
echo "$SCRIPT_DIR/bicycleinit.sh $BRANCH $API_URL" | tee -a bicycleinit.log

# Ensure jq is installed (for parsing JSON)
if ! command -v jq &> /dev/null
then
    echo "jq could not be found. Please install jq (sudo apt install jq)." | tee -a bicycleinit.log
    echo "Exit" | tee -a bicycleinit.log
    exit 1
fi

# Check if server is available
RESPONSE=$(curl -s -X GET "$API_URL/time")
CURL_EXIT_CODE=$?

# Check if curl succeeded
if [ $CURL_EXIT_CODE -ne 0 ]; then
    echo "Server not available. Offline mode enabled." | tee -a bicycleinit.log
    exec "$SCRIPT_DIR/bicyclelaunch.sh"
    exit $?
else
    echo "Server time: $RESPONSE" | tee -a bicycleinit.log
fi

# Check if we force to run in offline mode
if [ -f .offline ]; then
    echo "Forced offline mode" | tee -a bicycleinit.log
    exec "$SCRIPT_DIR/bicyclelaunch.sh"
    exit $?
fi

# Name of the virtual environment directory
VENV_DIR=".env"

# Check if the virtual environment directory exists
if [ -d "$VENV_DIR" ]; then
    echo "Virtual environment already exists." | tee -a bicycleinit.log
else
    echo "Virtual environment not found. Setting it up..." | tee -a bicycleinit.log
    # Create the virtual environment
    python3 -m venv $VENV_DIR

    # Check if venv creation was successful
    if [ -d "$VENV_DIR" ]; then
        echo "Virtual environment successfully created." | tee -a bicycleinit.log
    else
        echo "Failed to create the virtual environment." | tee -a bicycleinit.log
        echo "Exit" | tee -a bicycleinit.log
        exit 1
    fi
fi

# Fetch the latest changes from the remote repository
if ! git fetch origin; then
    echo "Failed to fetch updates. Offline mode enabled." | tee -a bicycleinit.log
    exec "$SCRIPT_DIR/bicyclelaunch.sh"
    exit $?
fi

# Check if the local branch is behind the remote branch
LOCAL_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse origin/$BRANCH)

echo "local commit  $LOCAL_COMMIT" | tee -a bicycleinit.log
echo "remote commit $REMOTE_COMMIT" | tee -a bicycleinit.log

if [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
    echo "Updates available. Pulling latest changes..."
    if ! git pull origin "$BRANCH"; then
        echo "Failed to pull updates. Resolve conflicts and retry." | tee -a bicycleinit.log
        echo "Offline mode enabled." | tee -a bicycleinit.log
        exec "$SCRIPT_DIR/bicyclelaunch.sh"
        exit $?
    fi
    # Execute the script after updating
    echo "Executing the updated script..."
    exec "$SCRIPT_DIR/bicycleinit.sh" $BRANCH $API_URL
    exit $?
else
    echo "No updates available. The repository is up to date." | tee -a bicycleinit.log
fi

#
# Update the config file

# Check if the .bicycledata file exists
if [ ! -f .bicycledata ]; then
    echo ".bicycledata file not found. Registering the device." | tee -a bicycleinit.log

    HOSTNAME=$(hostname)
    USERNAME=$(whoami)
    MAC_ADDRESS=$(ip link show | awk '/ether/ {print $2}' | head -n 1)

    # Create a JSON payload with the device information
    PAYLOAD=$(cat <<EOF
{
    "hostname": "$HOSTNAME",
    "username": "$USERNAME",
    "mac_address": "$MAC_ADDRESS"
}
EOF
    )

    # Send the registration request to the REST API
    RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$PAYLOAD" "$API_URL/register")
    CURL_EXIT_CODE=$?

    # Check if curl succeeded
    if [ $CURL_EXIT_CODE -ne 0 ]; then
        echo "Curl failed with exit code $CURL_EXIT_CODE. Registration failed." | tee -a bicycleinit.log
        echo "Offline mode enabled." | tee -a bicycleinit.log
        exec "$SCRIPT_DIR/bicyclelaunch.sh"
        exit $?
    fi

    # Validate the response using jq and ensure it contains the hash
    if echo "$RESPONSE" | jq -e '.hash' > /dev/null 2>&1; then
        echo "Registration successful. Saving .bicycledata file." | tee -a bicycleinit.log
        echo "$RESPONSE" > .bicycledata
    else
        echo "Registration failed. Response was: $RESPONSE" | tee -a bicycleinit.log
        echo "Exit" | tee -a bicycleinit.log
        exit 1
    fi
fi

# Now check if the .bicycledata file exists
if [ -f .bicycledata ]; then
    echo ".bicycledata file found. Updating config file." | tee -a bicycleinit.log

    # Extract the hash from the .bicycledata file
    HASH=$(jq -r '.hash' < .bicycledata)

    # Send the hash to the API to get the config.json file
    CONFIG_RESPONSE=$(curl -s -X GET "$API_URL/config?hash=$HASH")
    CURL_EXIT_CODE=$?

    # Check if curl succeeded
    if [ $CURL_EXIT_CODE -ne 0 ]; then
        echo "Curl failed with exit code $CURL_EXIT_CODE. Failed to retrieve config." | tee -a bicycleinit.log
        echo "Offline mode enabled." | tee -a bicycleinit.log
        exec "$SCRIPT_DIR/bicyclelaunch.sh"
        exit $?
    fi

    # Validate the config response
    if echo "$CONFIG_RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
        echo "Failed to retrieve config.json. Response was: $CONFIG_RESPONSE" | tee -a bicycleinit.log
        echo "Exit" | tee -a bicycleinit.log
        exit 1
    else
        echo "Config received. Saving config.json." | tee -a bicycleinit.log
        echo "$CONFIG_RESPONSE" > config.json
    fi
else
    echo "Error: .bicycledata file not found or failed to register." | tee -a bicycleinit.log
    echo "Exit" | tee -a bicycleinit.log
    exit 1
fi

exec "$SCRIPT_DIR/bicyclelaunch.sh"
exit $?
