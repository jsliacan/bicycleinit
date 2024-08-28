#!/bin/bash
# Arguments:
# 1. Branch name (optional): The Git branch to check for updates.
#    Defaults to 'main'.
# 2. Server REST API URL (optional): The base URL for the server's
#    REST API. Defaults to 'https://bicycledata.ochel.se:80'.

#
# Update this script - bicycleinit.sh

# Navigate to the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Define the branch to check for updates (default to main)
BRANCH=${1:-main}

# REST API URL (replace with your actual API endpoint)
API_URL=${2:-"https://bicycledata.ochel.se:80"}"/api"

# Fetch the latest changes from the remote repository
if ! git fetch origin; then
    echo "Failed to fetch updates. Check your network or Git configuration."
    exit 1
fi

# Check if the local branch is behind the remote branch
LOCAL_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse origin/$BRANCH)

if [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
    echo "Updates available. Pulling latest changes..."
    if ! git pull origin "$BRANCH"; then
        echo "Failed to pull updates. Resolve conflicts and retry."
        exit 1
    fi
    # Execute the script after updating
    echo "Executing the updated script..."
    exec "$SCRIPT_DIR/bicycleinit.sh"
    exit $?
else
    echo "No updates available. The repository is up to date."
fi

#
# Update the config file

# Check if the .bicycledata file exists
if [ ! -f .bicycledata ]; then
    echo ".bicycledata file not found. Registering the device."

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

    # Validate the response using jq and ensure it contains the hash
    if echo "$RESPONSE" | jq -e '.hash' > /dev/null 2>&1; then
        echo "Registration successful. Saving .bicycledata file."
        echo "$RESPONSE" > .bicycledata
    else
        echo "Registration failed. Response was: $RESPONSE"
        exit 1
    fi
fi

# Now check if the .bicycledata file exists
if [ -f .bicycledata ]; then
    echo ".bicycledata file found. Updating config file."

    # Extract the hash from the .bicycledata file
    HASH=$(jq -r '.hash' < .bicycledata)

    # Send the hash to the API to get the config.json file
    CONFIG_RESPONSE=$(curl -s -X GET "$API_URL/config?hash=$HASH")

    # Validate the config response
    if echo "$CONFIG_RESPONSE" | jq -e '.config' > /dev/null 2>&1; then
        echo "Config received. Saving config.json."
        echo "$CONFIG_RESPONSE" > config.json
    else
        echo "Failed to retrieve config.json. Response was: $CONFIG_RESPONSE"
        exit 1
    fi
else
    echo "Error: .bicycledata file not found or failed to register."
    exit 1
fi
