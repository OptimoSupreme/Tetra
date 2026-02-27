#!/bin/bash

# Configuration file indicating setup is complete
CONFIG_DIR="$HOME/.config/tetra"
DONE_FILE="$CONFIG_DIR/setup-done"

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"

# Check if already completed
if [ -f "$DONE_FILE" ]; then
    exit 0
fi

# TUI Loop
while true; do
    CHOICE=$(dialog --clear \
                --backtitle "Tetra OS First Boot Setup" \
                --title "Profile Selection" \
                --menu "Choose a profile to configure your system:" 15 50 4 \
                "1" "Generic Workstation" \
                "2" "Import Config" \
                "3" "Skip" \
                2>&1 >/dev/tty)

    clear

    case $CHOICE in
        1)
            echo "Applying Generic Workstation profile..."
            if [ -x "/usr/local/bin/generic-workstation.sh" ]; then
                /usr/local/bin/generic-workstation.sh
            else
                echo "Error: Profile script not found."
            fi
            # Mark as done
            touch "$DONE_FILE"
            echo "Setup complete. Press any key to close this window."
            read -n 1 -s
            break
            ;;
        2)
            # Use dialog to pick a file
            FILE=$(dialog --clear --title "Select Configuration File" --fselect "$HOME/" 14 48 2>&1 >/dev/tty)
            clear
            if [ -n "$FILE" ] && [ -f "$FILE" ]; then
                echo "Importing config from: $FILE"
                # TODO: Actually parse/apply the config here
                echo "Config import will be implemented in the future."
                echo "Press any key to return to the menu..."
                read -n 1 -s
            else
                echo "No valid file selected. Press any key to return to the menu..."
                read -n 1 -s
            fi
            ;;
        3)
            echo "Skipping setup."
            touch "$DONE_FILE"
            break
            ;;
        *)
            # Cancel/Escape pressed
            echo "Skipping setup."
            touch "$DONE_FILE"
            break
            ;;
    esac
done

clear
