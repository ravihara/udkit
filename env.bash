#!/bin/bash

## UDKit configuration
export PATH="$HOME/.udkit/bin:$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH"
export LD_LIBRARY_PATH="$HOME/.local/lib:/usr/local/lib:/usr/local/lib64:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

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
export COMPOSE_BAKE=true

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
	unset rc
fi

## Rust/cargo configuration
[ -d ~/.cargo ] && source "$HOME/.cargo/env"

## Fuzzy finder configuration
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

## Starship prompt configuration
if [ -n "$(command -v starship 2>/dev/null)" ]; then
	eval "$(starship init bash)"
fi

## Custom python installation (locally compiled)
py_udkdir="${HOME}/.udkit/dist/py-udk"

if [ -L "${py_udkdir}" ]; then
	export PATH="${py_udkdir}/bin:$PATH"
	export LD_LIBRARY_PATH="${py_udkdir}/lib:$LD_LIBRARY_PATH"
	export PKG_CONFIG_PATH="${py_udkdir}/lib/pkgconfig:$PKG_CONFIG_PATH"
fi

######### DO NOT EDIT ANYTHING BELOW THIS LINE #########
### direnv configuration - This should be at the end ###
if [ -n "$(command -v direnv 2>/dev/null)" ]; then
	export DIRENV_LOG_FORMAT=""
	eval "$(direnv hook bash)"
fi
