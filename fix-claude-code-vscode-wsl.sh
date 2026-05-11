#!/bin/bash
set -ue

# Base directory for VS Code Server extensions
EXT_BASE_DIR="$HOME/.vscode-server/extensions"

# Check if base directory exists
if [ ! -d "$EXT_BASE_DIR" ]; then
    echo "Error: Extensions directory not found at $EXT_BASE_DIR"
    exit 1
fi

echo "Looking for the latest Claude Code extension..."

# Find the latest installed version directory (full path)
EXT_DIR=$(ls -d "$EXT_BASE_DIR"/anthropic.claude-code-*/ 2>/dev/null | sort -V | tail -1)

if [ -z "$EXT_DIR" ]; then
    echo "Error: No Claude Code extension directory found."
    exit 1
fi

echo "Found extension: $EXT_DIR"

# Target file
TARGET_FILE="$EXT_DIR/extension.js"
BACKUP_FILE="$EXT_DIR/extension.js.backup"

# Create backup if not already present
if [ ! -f "$TARGET_FILE" ]; then
    echo "Error: extension.js not found in $EXT_DIR"
    exit 1
fi

if [ -f "$BACKUP_FILE" ]; then
    echo "Backup file already exists, skipping backup."
else
    cp "$TARGET_FILE" "$BACKUP_FILE"
    echo "Backup created: $BACKUP_FILE"
fi

# Apply patch
echo "Applying patch..."
sed -i 's/includePartialMessages:![A-Za-z0-9]*\.env\.remoteName/includePartialMessages:!0/' "$TARGET_FILE"
echo "Patch applied."

# Verification
echo "Verifying patch..."

# Test-A: new pattern should be present
if grep -q 'includePartialMessages:!0' "$TARGET_FILE"; then
    echo "Test-A: PASS - New pattern 'includePartialMessages:!0' is present."
else
    echo "Test-A: FAIL - New pattern not found."
    exit 1
fi

# Test-B: old pattern should be absent
if grep -q 'includePartialMessages:![A-Za-z0-9]*\.env\.remoteName' "$TARGET_FILE"; then
    echo "Test-B: FAIL - Old pattern still exists. Manual intervention required."
    exit 1
else
    echo "Test-B: PASS - Old pattern has been removed."
fi

echo "All checks passed. Claude Code extension is now patched."
echo "Reload target VS Code instance(s) for the patch to take effect."
