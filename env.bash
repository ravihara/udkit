#!/bin/bash

## UDKit configuration
export PATH="$HOME/.udkit/bin:$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH"
export LD_LIBRARY_PATH="$HOME/.local/lib:/usr/local/lib:/usr/local/lib64:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

## Create local directories if not present
mkdir -p "$HOME/.local/bin" "$HOME/.local/lib" "$HOME/.local/include" "$HOME/.local/share"

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

install_direnv() {
	echo_info "Installing direnv..."
	export bin_path=${HOME}/.local/bin
	mkdir -p ${bin_path}
	curl -fsSL https://direnv.net/install.sh | bash
	unset bin_path

	if [ ! -d ${HOME}/.config/direnv ]; then
		cp -r ${HOME}/.udkit/skel/direnv ${HOME}/.config/
	fi
}

install_starship() {
	echo_info "Installing starship..."
	mkdir -p ${HOME}/.local/bin
	curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir ${HOME}/.local/bin

	if [ ! -f ${HOME}/.config/starship.toml ]; then
		cp ${HOME}/.udkit/skel/starship.toml ${HOME}/.config/
	fi
}

## Install and configure direnv if not present
if [[ -z $(command -v direnv 2>/dev/null) ]]; then
	install_direnv
fi

## Install and configure starship prompt if not present
if [[ -z $(command -v starship 2>/dev/null) ]]; then
	install_starship
fi

## Starship prompt configuration
if [ -n "$(command -v starship 2>/dev/null)" ]; then
	eval "$(starship init bash)"
fi

## Fuzzy finder configuration
[ -f "${HOME}/.fzf.bash" ] && source "${HOME}/.fzf.bash"

## Rust/cargo configuration
[ -d "${HOME}/.cargo" ] && source "$HOME/.cargo/env"

## Bun configuration
if [ -d "${HOME}/.bun" ]; then
	export BUN_INSTALL="${HOME}/.bun"
	export PATH="${BUN_INSTALL}/bin:$PATH"
fi

######### DO NOT EDIT ANYTHING BELOW THIS LINE #########
### direnv configuration - This should be at the end ###
if [ -n "$(command -v direnv 2>/dev/null)" ]; then
	export DIRENV_LOG_FORMAT=""
	eval "$(direnv hook bash)"
fi
