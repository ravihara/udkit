#!/bin/bash

export UDKIT_BASE=$HOME/.udkit

## Set line coloring
export TRML_HL='\033[1;35m'
export TRML_NC='\033[0m'

## Set default editor (Ex., for direnv)
if [ -z "$EDITOR" ]; then
  export EDITOR=vim
fi

## Export common environment variables needed by libraries and executables
export PATH="$UDKIT_BASE/bin:$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH"
export LD_LIBRARY_PATH="/usr/local/lib:/usr/local/lib64:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

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
if [ -n "$(command -v pyenv 2>/dev/null)" ]; then
  export PYENV_ROOT=$(pyenv root)
  export PATH="${PYENV_ROOT}/bin:$PATH"

  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

## Array to string conversion with given separator
join_list_items_by() {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

## Normalize build related environment variables
normalize_build_env() {
  local path_parts=$(echo $LD_LIBRARY_PATH | tr ":" "\n" | sort | uniq)
  path_parts=$(join_list_items_by ':' ${path_parts[@]})
  export LD_LIBRARY_PATH="$path_parts"

  path_parts=$(echo $PKG_CONFIG_PATH | tr ":" "\n" | sort | uniq)
  path_parts=$(join_list_items_by ':' ${path_parts[@]})
  export PKG_CONFIG_PATH="$path_parts"

  path_parts=$(echo $CPATH | tr ":" "\n" | sort | uniq)
  path_parts=$(join_list_items_by ':' ${path_parts[@]})
  export CPATH="$path_parts"

  path_parts=$(echo $PATH | tr ":" "\n" | sort | uniq)
  path_parts=$(join_list_items_by ':' ${path_parts[@]})
  path_parts="$(echo $path_parts | sed -e 's|^/bin:||')"
  export PATH="${path_parts}:/bin"

  unset path_parts
}

######### DO NOT EDIT ANYTHING BELOW THIS LINE #########
### direnv configuration - This should be at the end ###
if [ -n "$(which direnv)" ]; then
  export DIRENV_LOG_FORMAT=""
  eval "$(direnv hook bash)"
fi
