##### zsh configuration file #####

export GPG_TTY=$(tty)

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

## Inspired by: https://thevaluable.dev/zsh-install-configure-mouseless/

### Aliases ###
source ~/.config/aliases

### History options ###
setopt hist_ignore_all_dups    # Keep only the most recent occurrence of a command 
setopt hist_ignore_space       # Commands starting with space are not saved
setopt inc_append_history      # Write to history file immediately, not just on shell exit
setopt share_history           # Share history between all running Zsh sessions

### zsh completion ###
autoload -U compinit
compinit
_comp_options+=(globdots) # With hidden files
source ~/.config/zsh/completion.zsh

source ~/.config/zsh/powerlevel10k/powerlevel10k.zsh-theme

setopt correctall

# Set keys to emacs ("normal" mode)
bindkey -e

# Manipulate directory stack
setopt AUTO_PUSHD           # Push the current directory visited on the stack.
setopt PUSHD_IGNORE_DUPS    # Do not store duplicates in the stack.
setopt PUSHD_SILENT         # Do not print the directory stack after pushd or popd.

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
