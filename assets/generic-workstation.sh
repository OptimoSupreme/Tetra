#!/bin/bash

# Placeholder script for the Generic Workstation profile
# Ultimately this script will handle tasks like installing flatpaks and configuring GNOME extensions

echo "======================================"
echo " Starting Generic Workstation Profile "
echo "======================================"
echo ""

echo "[INFO] Installing Flatpaks..."
# flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
# flatpak install -y flathub ...
com.github.k4zmu2a.spacecadetpinball \
com.spotify.Client \
org.mozilla.firefox \
org.onlyoffice.desktopeditors
echo "[INFO] Configuring GNOME Extensions..."
# dconf load /org/gnome/shell/extensions/ < /usr/share/tetra/extensions.ini

echo ""
echo "[SUCCESS] Generic Workstation configuration applied successfully!"
