#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting installation...${NC}"

# Create .release directory in home directory
HOME_DIR=$(eval echo ~$USER)
RELEASE_DIR="${HOME_DIR}/.release"

# Run compile script
echo -e "${BLUE}Compiling application...${NC}"
./shell/compile.sh

# Create .release directory and move binary
echo -e "${BLUE}Setting up .release directory...${NC}"
mkdir -p "${RELEASE_DIR}/bin"
mv release/bin/workspace_monitor "${RELEASE_DIR}/bin/"
rm -rf release

# Create and load LaunchAgent
echo -e "${BLUE}Creating and loading LaunchAgent...${NC}"
./shell/create_agent.sh

echo -e "${GREEN}Installation complete!${NC}"
echo -e "Binary location: ${RELEASE_DIR}/bin/workspace_monitor"
echo -e "LaunchAgent location: ~/Library/LaunchAgents/com.workspace.monitor.plist"

chmod +x install.sh 