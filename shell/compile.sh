#!/bin/bash

# Create release directory structure
mkdir -p release/bin

# Compile with optimizations
swiftc -O -o release/bin/workspace_monitor src/main.swift -framework AppKit

# Make binary executable
chmod +x release/bin/workspace_monitor

echo "Compilation complete! Binary located at release/bin/workspace_monitor" 