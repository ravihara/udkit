#!/bin/bash

export UDKIT_BASE=$HOME/.udkit

## Set line coloring
export TRML_HL='\033[1;35m'
export TRML_NC='\033[0m'

#################################################################
################## udk custom bash functions ####################
#################################################################

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

#################################################################
################# udk custom package settings ###################
#################################################################

## udk bin utilities
export PATH="$UDKIT_BASE/bin:$PATH"

## Golang configuration
if [ -d "$UDKIT_BASE/sdk/golang" ]; then
  export GOPATH="$UDKIT_BASE/sdk/golang/1.19"
  export PATH="$GOPATH/bin:$PATH"
fi

## Android configuration
if [ -d "$UDKIT_BASE/ide/android" ]; then
  export ANDROID_HOME="$UDKIT_BASE/ide/android"
  export PATH="$ANDROID_HOME/bin:$HOME/Android/Sdk/platform-tools:$PATH"
fi

## aws-cli with bash autocomplete
if [ -n "$(which aws_completer)" ]; then
  complete -C $(which aws_completer) aws
fi

## direnv configuration - THIS MUST BE TO THE END ##
if [ -n "$(which direnv)" ]; then
  export DIRENV_LOG_FORMAT=""
  eval "$(direnv hook bash)"
fi
