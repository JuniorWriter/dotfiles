#!/bin/bash

set -e

setup_colors() {
    if [ -t 1 ]; then
        YELLOW="\e[33m"
        BLUE="\e[34m"
        RED="\e[31m"
        GREEN="\e[32m"
        CYAN="\e[36m"
        BOLD="\e[1m"
        WHITE="\e[97m"
        RESET="\e[0m"
    fi
}


CONFIG="install.conf.yaml"
DOTBOT_DIR="dotbot"

DOTBOT_BIN="bin/dotbot"
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

setup_colors
dotfiles_prompt=$(less -FX img/dotfiles)
clear
echo -e "$BLUE$dotfiles_prompt$RESET"
sudo echo ""
echo -e "🚀️$WHITE" "Starting Installation"

cd "${BASEDIR}"
git -C "${DOTBOT_DIR}" submodule sync --quiet --recursive
git submodule update --init --recursive "${DOTBOT_DIR}"

"${BASEDIR}/${DOTBOT_DIR}/${DOTBOT_BIN}" -d "${BASEDIR}" -c "${CONFIG}" "${@}"
