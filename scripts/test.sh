#!/bin/env bash

if ! command -v nvim &>/dev/null; then
	echo "nvim is not installed"
	exit 1
fi

nvim -l tests/minit.lua tests
