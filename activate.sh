#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

nix flake update $SCRIPT_DIR
home-manager switch --flake $SCRIPT_DIR
sudo nixos-rebuild switch --flake $SCRIPT_DIR
