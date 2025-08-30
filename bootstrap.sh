#!/usr/bin/env bash

set -euo pipefail

REQUIRED_PACKAGES="curl git nvim stow zellij zsh"
STOW_DIRS="aliases vim zsh"
NERD_FONTS=("Meslo" "JetBrainsMono")
DOTFILES_DIR="$HOME/.dotfiles"
FONT_DIR="$HOME/.local/share/fonts"

print_help() {
    cat <<EOF
==== Dotfiles Bootstrap Script ====

Usage: $0 [OPTIONS]

Options:
  --stow        Symlink dotfiles using GNU stow
  --fonts       Install Nerd Fonts locally and refresh font cache
  -h, --help    Show this help message and exit

You can combine options. Example:
  $0 --stow --fonts

If no options are given, only package installation and shell setup are performed.

EOF
}

print_header() {
    LOGFILE="/tmp/bootstrap.log"
    exec > >(tee -a "$LOGFILE") 2>&1
    printf "==== Dotfiles Bootstrap Script ====\n"
    printf "Started at: %s\n" "$(date)"
    printf "Log: %s\n" "$LOGFILE"
}

detect_os() {
    if [ -f /etc/arch-release ]; then
        DISTRO="arch"
        INSTALL="sudo pacman -Syu --needed"
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
        INSTALL="sudo apt update && sudo apt install -y"
    elif [ -f /etc/gentoo-release ]; then
        DISTRO="gentoo"
        INSTALL="sudo emerge --ask --noreplace --oneshot"
    else
        printf "Unsupported or unknown distribution.\n"
        exit 1
    fi
    printf "\nDetected distribution: %s\n" "$DISTRO"
}

install_packages() {
    local MISSING=""
    local pkg
    for pkg in $REQUIRED_PACKAGES; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            printf "Missing: %s\n" "$pkg"
            MISSING="$MISSING $pkg"
        fi
    done

    if [ -n "$MISSING" ]; then
        printf "Installing missing packages: %s\n\n" "$MISSING"
        eval "$INSTALL $MISSING"
    else
        printf "All required packages are installed.\n\n"
    fi
}

stow_dotfiles() {
    printf "Symlinking dotfiles with stow...\n"
    cd "$DOTFILES_DIR"
    local dir
    for dir in $STOW_DIRS; do
        if [ -d "$dir" ]; then
            stow "$dir"
        fi
    done
    printf "Done symlinking dotfiles.\n\n"
}

install_nerd_fonts() {
    printf "Installing Nerd Fonts locally...\n"
    local NERD_FONTS_REPO="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
    mkdir -p "$FONT_DIR"
    local font TAR URL TMP_FONT_DIR
    for font in "${NERD_FONTS[@]}"; do
        # Check if font already exists (either .otf or .ttf)
        if compgen -G "$FONT_DIR/${font}*.otf" > /dev/null || compgen -G "$FONT_DIR/${font}*.ttf" > /dev/null; then
            printf "%s Nerd Font already installed, skipping.\n\n" "$font"
            continue
        fi

        TAR="${font}.tar.xz"
        URL="$NERD_FONTS_REPO/${TAR}"

        printf "Downloading %s Nerd Font...\n" "$font"
        curl -fLo "/tmp/$TAR" --retry 3 --retry-delay 2 "$URL"

        printf "Extracting %s...\n" "$font"
        TMP_FONT_DIR="/tmp/${font}-extract"
        mkdir -p "$TMP_FONT_DIR"
        tar --wildcards --no-anchored -xJf "/tmp/$TAR" -C "$TMP_FONT_DIR" '*.ttf' '*.otf' 2>/dev/null || true

        printf "Installing %s font files...\n" "$font"
        # Prefer .otf if present, otherwise .ttf
        if compgen -G "$TMP_FONT_DIR/*.otf" > /dev/null; then
            mv "$TMP_FONT_DIR"/*.otf "$FONT_DIR"/
        elif compgen -G "$TMP_FONT_DIR/*.ttf" > /dev/null; then
            mv "$TMP_FONT_DIR"/*.ttf "$FONT_DIR"/
        fi

        rm -rf "$TMP_FONT_DIR" "/tmp/$TAR"

        printf "Installed %s Nerd Font.\n\n" "$font"
    done
}

refresh_font_cache() {
    if command -v fc-cache >/dev/null 2>&1; then
        printf "Refreshing font cache...\n"
        fc-cache -fv "$FONT_DIR"
    fi
    printf "\n"
}

set_default_shell() {
    if ! echo "$SHELL" | grep -q "zsh$"; then
        printf "Changing default shell to zsh...\n"
        chsh -s "$(command -v zsh)"
        printf "\n"
    fi
}

main() {
    local DO_STOW=0
    local DO_FONTS=0

    for arg in "$@"; do
        case "$arg" in
            --stow) DO_STOW=1 ;;
            --fonts) DO_FONTS=1 ;;
            -h|--help)
                print_help
                exit 0
                ;;
        esac
    done

    print_header
    detect_os
    install_packages

    if [ "$DO_FONTS" -eq 1 ]; then
        install_nerd_fonts
        refresh_font_cache
    fi

    if [ "$DO_STOW" -eq 1 ]; then
        stow_dotfiles
    fi

    set_default_shell

    printf "Bootstrap complete! Please restart your terminal.\n"
    printf "==== End of Bootstrap Script ====\n"
}

main "$@"
