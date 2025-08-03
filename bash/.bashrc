# /etc/skel/.bashrc
#
# This file is sourced by all *interactive* bash shells on startup,
# including some apparently interactive shells such as scp and rcp
# that can't tolerate any output.  So make sure this doesn't display
# anything or bad things will happen !


# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* ]] ; then
	# Shell is non-interactive.  Be done now!
	return
fi

# My aliases:
# MATLAB:
alias matlab-cli='matlab -nosplash -nodesktop -nojvm -nodisplay'

# List directory contents 
alias ls='ls --color=auto'
alias ll='ls -lFh'           # size,show type,human readable
alias la='ls -lAFh'          # long list,show almost all,show type,human readable
alias lr='ls -tRFh'          # sorted by date,recursive,show type,human readable
alias lt='ls -ltFh'          # long list,sorted by date,show type,human readable
alias l='ls -l'              # long list
alias ldot='ls -ld .*'
alias lS='ls -1FSsh'
alias lart='ls -1Fcart'
alias lrt='ls -1Fcrt'

# User htop
alias utop='htop -u $USER'

# Sudo Edit
alias sudoedit='SUDO_EDITOR=kate sudoedit'

# Put your fun stuff here.
PATH="$HOME/.scripts:$HOME/.local/bin:$PATH"

export GPG_TTY=$(tty)
