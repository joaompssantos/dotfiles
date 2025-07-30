#!/usr/bin/env bash

set -e

# List of required packages
REQUIRED="stow git zsh neovim tmux"
MISSING=""

# Detect Linux distribution
if [ -f /etc/gentoo-release ]; then
    DISTRO="gentoo"
elif [ -f /etc/debian_version ]; then
    DISTRO="debian"
elif [ -f /etc/arch-release ]; then
    DISTRO="arch"
else
    DISTRO="unknown"
fi

echo "Detected distribution: $DISTRO"

echo "Checking for required packages..."
for pkg in $REQUIRED; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
        echo "Missing: $pkg"
        MISSING="$MISSING $pkg"
    fi
done

if [ -n "$MISSING" ]; then
    echo "The following packages are missing:$MISSING"
    case "$DISTRO" in
        gentoo)
            echo "Attempting to install with emerge..."
            sudo emerge --ask --noreplace $MISSING
            ;;
        debian)
            echo "Attempting to install with apt..."
            sudo apt update
            sudo apt install -y $MISSING
            ;;
        arch)
            echo "Attempting to install with pacman..."
            sudo pacman -Syu --needed $MISSING
            ;;
        *)
            echo "Unknown distribution. Please install the missing packages manually."
            exit 1
            ;;
    esac
else
    echo "All required packages are installed."
fi

echo "Symlinking dotfiles with stow..."
stow bash vim git tmux

echo "Done! Your environment is bootstrapped."
