#!/bin/env bash

if ! command -v nvim &>/dev/null; then
	echo "nvim is not installed"
	exit 1
fi

declare -r plugins_dir="./.tests/site/pack/vendor/start"

while [[ $# -gt 0 ]]; do
	case "${1}" in
	--clean)
		shift
		echo "[test] cleaning up environment"
		rm -rf "${plugins_dir}"
		echo "[test] envionment cleaned"
		;;
	*)
		shift
		;;
	esac
done

function setup_environment() {
	echo
	echo "[test] setting up environment"
	echo

	if [[ ! -d "${plugins_dir}" ]]; then
		mkdir -p "${plugins_dir}"
	fi

	if [[ ! -d "${plugins_dir}/nui.nvim" ]]; then
		echo "[plugins] nui.nvim: installing..."
		git clone https://github.com/MunifTanjim/nui.nvim "${plugins_dir}/nui.nvim"
		echo "[plugins] nui.nvim: installed"
		echo
	fi

	if [[ ! -d "${plugins_dir}/plenary.nvim" ]]; then
		echo "[plugins] plenary.nvim: installing..."
		git clone https://github.com/nvim-lua/plenary.nvim "${plugins_dir}/plenary.nvim"
		echo "[plugins] plenary.nvim: installed"
		echo
	fi

	echo "[test] environment ready"
	echo
}

setup_environment

nvim -l tests/minit.lua tests
