###### Set environment variables ######

### XDG directories ###
export XDG_CONFIG_HOME="$HOME/.config"

### Location of zsh config files
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

### zsh history variables ###
export HISTFILE="$ZDOTDIR/.zsh_history" # History filepath
export HISTSIZE=1000000000              # Maximum events for internal history
export SAVEHIST=1000000000              # Maximum events in history file

### For inspiration : https://github.com/Phantas0s/.dotfiles/blob/master/zsh/zshenv
