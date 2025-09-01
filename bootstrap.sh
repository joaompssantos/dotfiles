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

manually_install_packages() {
    printf "Manually installing packages...\n"
    mkdir -p "$HOME/.local/bin"

    for pkg in $@; do
        case "$pkg" in
            nvim)
                printf "Downloading Neovim AppImage...\n"
                curl -fLo "$HOME/.local/bin/nvim" https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
                chmod +x "$HOME/.local/bin/nvim"
                ;;
            zellij)
                printf "Downloading Zellij binary...\n"
                curl -fLo "$HOME/.local/bin/zellij" https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl
                chmod +x "$HOME/.local/bin/zellij"
                ;;
            stow)
                printf "Installing GNU Stow locally...\n"
                git clone https://git.savannah.gnu.org/git/stow.git /tmp/stow-src
                cd /tmp/stow-src
                perl Makefile.PL PREFIX="$HOME/.local"
                make install
                cd -
                rm -rf /tmp/stow-src
                ;;
            zsh)
                printf "Installing Zsh locally...\n"

                # Download and build latest ncurses in /tmp if not present
                if ! (find "$HOME/.local/lib" "$HOME/.local/include" -name '*ncurses*' | grep -q ncurses); then
                    printf "ncurses not found locally, compiling latest ncurses in /tmp...\n"
                    wget -q https://ftp.gnu.org/pub/gnu/ncurses/ncurses-latest.tar.gz -O /tmp/ncurses-latest.tar.gz
                    tar -xzf /tmp/ncurses-latest.tar.gz -C /tmp
                    NCURSES_DIR=$(tar -tzf /tmp/ncurses-latest.tar.gz | head -1 | cut -f1 -d"/")
                    cd "/tmp/$NCURSES_DIR"
                    ./configure --prefix="$HOME/.local" --enable-shared --with-termlib --with-ticlib --with-install-prefix="$HOME/.local"
                    make -j"$(nproc)"
                    make install
                    cd -
                    rm -rf "/tmp/$NCURSES_DIR" /tmp/ncurses-latest.tar.gz
                fi

                # Download and build latest Zsh in /tmp
                wget -qO /tmp/zsh.tar.xz https://sourceforge.net/projects/zsh/files/latest/download
                mkdir -p /tmp/zsh-src
                unxz /tmp/zsh.tar.xz
                tar -xf /tmp/zsh.tar -C /tmp/zsh-src --strip-components 1
                cd /tmp/zsh-src

                export CPPFLAGS="-I$HOME/.local/include"
                export LDFLAGS="-L$HOME/.local/lib"
                ./configure --prefix="$HOME/.local"
                make -j"$(nproc)"
                make install
                cd -
                rm -rf /tmp/zsh-src /tmp/zsh.tar

                printf "Official Zsh installed to \$HOME/.local/bin/zsh\n"
                ;;
            curl|git)
                printf "Please install %s manually or via your package manager (no user-level installer available).\n" "$pkg"
                ;;
            *)
                printf "No manual install instructions for %s. Please install it manually.\n" "$pkg"
                ;;
        esac
    done

    printf "Manual installation complete. Ensure \$HOME/.local/bin is in your PATH.\n\n"
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
        if sudo -v &> /dev/null; then
            printf "Installing missing packages: %s\n\n" "$MISSING"
            eval "$INSTALL $MISSING"
        else
            printf "Missing packages but no sudo access available.\n"
            manually_install_packages $MISSING
        fi
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
    local zsh_path="$HOME/.local/bin/zsh"
    if ! echo "$SHELL" | grep -q "zsh$"; then
        printf "Changing default shell to zsh...\n"
        if chsh -s "$zsh_path"; then
            printf "Default shell changed to %s.\n\n" "$zsh_path"
        else
            printf "Failed to change shell. You may need to add\n"
            printf "  %s\n" "$zsh_path"
            printf "to /etc/shells (requires root), then run:\n"
            printf "  chsh -s %s\n" "$zsh_path"
            printf "Or, add 'exec %s -l' to your ~/.bash_profile or ~/.profile.\n\n" "$zsh_path"
        fi
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
