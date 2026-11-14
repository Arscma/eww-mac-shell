#!/usr/bin/env bash
set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}"
echo "  ███████╗██╗    ██╗██╗    ██╗    ███╗   ███╗ █████╗  ██████╗"
echo "  ██╔════╝██║    ██║██║    ██║    ████╗ ████║██╔══██╗██╔════╝"
echo "  █████╗  ██║ █╗ ██║██║ █╗ ██║    ██╔████╔██║███████║██║"
echo "  ██╔══╝  ██║███╗██║██║███╗██║    ██║╚██╔╝██║██╔══██║██║"
echo "  ███████╗╚███╔███╔╝╚███╔███╔╝    ██║ ╚═╝ ██║██║  ██║╚██████╗"
echo "  ╚══════╝ ╚══╝╚══╝  ╚══╝╚══╝    ╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝"
echo -e "${NC}"
echo -e "${BOLD}  macOS Shell for Hyprland — Installer${NC}"
echo ""

echo -e "${YELLOW}⚠  This installer is for Arch Linux + yay only.${NC}"
echo -e "${YELLOW}⚠  A fresh Hyprland install is recommended.${NC}"
echo ""

# --- Package lists ---

PACMAN_PKGS=(
    # Core
    eww jq socat foot
    # Apps
    swaync nwg-drawer hyprlock hypridle waybar pavucontrol pcmanfm
    # Network & System
    networkmanager bluez brightnessctl pipewire-pulse
    playerctl power-profiles-daemon pacman-contrib curl
    # Wayland / Hyprland utils
    grim hyprpolkitagent
    # Fonts
    ttf-jetbrains-mono-nerd
)

AUR_PKGS=(
    # Theming
    whitesur-icon-theme bibata-cursor-theme
    # Fonts
    ttf-inter ttf-bebas-neue
    nerd-fonts-symbols-only
)

FLATPAK_OPTIONAL=(
    # Optional: sticky notes (right-click on clock)
    # com.betterstickies.BetterStickies
)

# --- Display dry run ---

echo -e "${BOLD}The following packages will be installed:${NC}"
echo ""
echo -e "${CYAN}[pacman]${NC}"
echo "  ${PACMAN_PKGS[*]}"
echo ""
echo -e "${CYAN}[yay / AUR]${NC}"
echo "  ${AUR_PKGS[*]}"
echo ""
echo -e "${YELLOW}[flatpak — optional, commented out by default]${NC}"
echo "  com.betterstickies.BetterStickies"
echo ""
echo -e "${BOLD}Notes:${NC}"
echo -e "  ${YELLOW}•${NC} Pinned apps in the dock are configured by YOU after install."
echo -e "    Edit: ${CYAN}~/.config/eww/scripts/status/pinned.json${NC}"
echo -e "  ${YELLOW}•${NC} To install BetterStickies, uncomment it in this script and rerun,"
echo -e "    or run: ${CYAN}flatpak install com.betterstickies.BetterStickies${NC}"
echo ""

read -rp "$(echo -e "${BOLD}Proceed with installation? [y/N]${NC} ")" confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

echo ""

# --- Install ---

echo -e "${BOLD}Installing pacman packages...${NC}"
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

echo -e "${BOLD}Installing AUR packages...${NC}"
yay -S --needed --noconfirm "${AUR_PKGS[@]}"

# Optional flatpak (uncomment to enable)
# flatpak install -y com.betterstickies.BetterStickies

echo ""
echo -e "${GREEN}${BOLD}✓ Dependencies installed.${NC}"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo -e "  1. Copy the ${CYAN}eww/${NC} folder to ${CYAN}~/.config/${NC}"
echo -e "  2. Set up symlinks (see README)"
echo -e "  3. chmod +x all scripts:"
echo -e "     ${CYAN}chmod +x ~/.config/eww/scripts/bin/*${NC}"
echo -e "     ${CYAN}chmod +x ~/.config/eww/scripts/*.sh${NC}"
echo -e "     ${CYAN}chmod +x ~/.config/eww/apps/swaync/scripts/*.sh${NC}"
echo ""
echo -e "${YELLOW}⚠  Don't forget to configure your pinned dock apps!${NC}"
echo -e "   ${CYAN}~/.config/eww/scripts/status/pinned.json${NC}"
