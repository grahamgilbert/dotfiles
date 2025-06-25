#!/bin/bash

set -e
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin

chezmoi init https://github.com/grahamgilbert/dotfiles.git

chezmoi apply -v