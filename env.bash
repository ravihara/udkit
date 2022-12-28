#!/bin/bash

export UDKIT_BASE=$HOME/.udkit

## Set line coloring
export TRML_HL='\033[1;35m'
export TRML_NC='\033[0m'

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

## udk bin utilities
export PATH="$UDKIT_BASE/bin:$PATH"

#########################################################
################# udk custom settings ###################
#########################################################

######### DO NOT EDIT ANYTHING BELOW THIS LINE #########
### direnv configuration - This should be at the end ###
if [ -n "$(which direnv)" ]; then
  export DIRENV_LOG_FORMAT=""
  eval "$(direnv hook bash)"
fi
