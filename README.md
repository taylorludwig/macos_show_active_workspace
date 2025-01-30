# macOS Show Active Workspace

A lightweight menubar utility that displays your current macOS workspace number.

## Quick Installation

1. Make the install script executable:

chmod +x ./install.sh

2. Run the installer:

./install.sh

This will:
- Compile the application
- Install it to ~/.release/bin
- Set up and load the LaunchAgent

## Uninstallation

To remove the application:

# Unload the LaunchAgent
launchctl unload ~/Library/LaunchAgents/com.workspace.monitor.plist

# Remove the files
rm ~/Library/LaunchAgents/com.workspace.monitor.plist
rm ~/.release/bin/workspace_monitor

## Development

The application is built using Swift and AppKit. Main components:
- Status bar integration
- Workspace monitoring
- Dynamic updates

## Manual Installation

For advanced users who prefer manual installation, see the individual scripts:
- `compile.sh` - Compiles the application
- `create_agent.sh` - Creates and loads the LaunchAgent