#!/usr/bin/env bash
set -euo pipefail  # エラー処理と未定義変数の扱いを強化

RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color (リセット)

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}This script is designed for macOS only.${NC}"
    exit 1
fi

echo -e "${BLUE}Setting up external keyboard key mappings...${NC}"

# Create or modify the key mapping plist
PLIST_PATH="$HOME/Library/LaunchAgents/com.apple.KeyRemapping.plist"

# Create the plist content
cat > "$PLIST_PATH" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.apple.KeyRemapping</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/hidutil</string>
        <string>property</string>
        <string>--set</string>
        <string>{"UserKeyMapping":[
            {"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0},
            {"HIDKeyboardModifierMappingSrc":0x7000000E2,"HIDKeyboardModifierMappingDst":0x7000000E3},
            {"HIDKeyboardModifierMappingSrc":0x7000000E3,"HIDKeyboardModifierMappingDst":0x7000000E2}
        ]}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

# Load the launch agent
launchctl load "$PLIST_PATH"

# Apply the key mapping immediately
hidutil property --set '{"UserKeyMapping":[
    {"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0},
    {"HIDKeyboardModifierMappingSrc":0x7000000E2,"HIDKeyboardModifierMappingDst":0x7000000E3},
    {"HIDKeyboardModifierMappingSrc":0x7000000E3,"HIDKeyboardModifierMappingDst":0x7000000E2}
]}'

echo -e "${BLUE}External keyboard key mapping configured successfully!${NC}"
echo -e "${BLUE}- Caps Lock is now mapped to Control${NC}"
echo -e "${BLUE}- Option (Alt) is now mapped to Command${NC}"
echo -e "${BLUE}- Command is now mapped to Option${NC}"
echo ""
echo -e "${BLUE}Changes will persist after reboot.${NC}"
echo -e "${BLUE}To disable, run: launchctl unload \"$PLIST_PATH\" && rm \"$PLIST_PATH\"${NC}"
