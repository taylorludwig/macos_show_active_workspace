#!/bin/bash

# Get the current username
USERNAME=$(whoami)
HOME_DIR=$(eval echo ~$USERNAME)

# Create LaunchAgents directory if it doesn't exist
mkdir -p ~/Library/LaunchAgents

# Create the plist file with dynamic username
cat > ~/Library/LaunchAgents/com.workspace.monitor.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.workspace.monitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>${HOME_DIR}/.release/bin/workspace_monitor</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

# Set correct permissions
chmod 644 ~/Library/LaunchAgents/com.workspace.monitor.plist

# Unload if exists
launchctl unload ~/Library/LaunchAgents/com.workspace.monitor.plist 2>/dev/null

# Load the agent
launchctl load ~/Library/LaunchAgents/com.workspace.monitor.plist

echo "LaunchAgent created and loaded for user: $USERNAME"
echo "Plist location: ~/Library/LaunchAgents/com.workspace.monitor.plist" 