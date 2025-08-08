##### zsh configuration file #####

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export GPG_TTY=$(tty)

## Inspired by: https://thevaluable.dev/zsh-install-configure-mouseless/

### Antidote plugin manager ###
# source antidote
source ${ZDOTDIR}/antidote/antidote.zsh

# initialize plugins statically with ${ZDOTDIR:-~}/.zsh_plugins.txt
antidote load

### Aliases ###
source ~/.config/aliases

### Key binds ###
case "$TERM" in
  xterm-256color)
    source "${ZDOTDIR}/.zkbd/xterm-256color-:1"
    ;;
  xterm-ghostty)
    source "${ZDOTDIR}/.zkbd/xterm-ghostty-:1"
    ;;
  *)
    echo "No .zkbd file for TERM=$TERM"
    ;;
esac

source ${ZDOTDIR}/keybinds.zsh

### History options ###
setopt hist_ignore_all_dups    # Keep only the most recent occurrence of a command 
setopt hist_ignore_space       # Commands starting with space are not saved
setopt inc_append_history      # Write to history file immediately, not just on shell exit
setopt share_history           # Share history between all running Zsh sessions
setopt hist_verify

### zsh completion ###
autoload -U compinit
compinit
_comp_options+=(globdots) # With hidden files
source ${ZDOTDIR}/completion.zsh

source ${ZDOTDIR}/powerlevel10k/powerlevel10k.zsh-theme

setopt correctall

# Manipulate directory stack
setopt AUTO_PUSHD           # Push the current directory visited on the stack.
setopt PUSHD_IGNORE_DUPS    # Do not store duplicates in the stack.
setopt PUSHD_SILENT         # Do not print the directory stack after pushd or popd.

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ${ZDOTDIR}/.p10k.zsh ]] || source ${ZDOTDIR}/.p10k.zsh
