#!/bin/bash

## UDKit configuration
export UDKIT_BASE=$HOME/.udkit
export PATH="$UDKIT_BASE/bin:$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH"
export LD_LIBRARY_PATH="/usr/local/lib:/usr/local/lib64:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

## Set line coloring
export TRML_HL='\033[1;35m'
export TRML_NC='\033[0m'

## Set default editor (Ex., for direnv)
if [ -z "$EDITOR" ]; then
  export EDITOR=vim
fi

## Terminal settings for system debug related params
ulimit -c unlimited

## For GNUPG v2.0
export GPG_TTY=$(tty)

## Docker settings
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=0

## Starship prompt configuration
if [ -n "$(command -v starship 2>/dev/null)" ]; then
  eval "$(starship init bash)"
fi

## Fuzzy finder configuration
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

## Rust/cargo configuration
[ -d ~/.cargo ] && source "$HOME/.cargo/env"

## Pyenv configuration
if [ -x "$HOME/.pyenv/bin/pyenv" ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="${PYENV_ROOT}/bin:$PATH"

  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

######### DO NOT EDIT ANYTHING BELOW THIS LINE #########
### direnv configuration - This should be at the end ###
if [ -n "$(command -v direnv 2>/dev/null)" ]; then
  export DIRENV_LOG_FORMAT=""
  eval "$(direnv hook bash)"
fi
