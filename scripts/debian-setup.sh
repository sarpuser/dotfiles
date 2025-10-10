#!/bin/bash
# Note: This script is intended to be run with sudo privileges
# This script is idempotent - it can be safely re-executed multiple times

LOCATION=New_York
TIMEZONE="America/$LOCATION"
LOCALE="US/$LOCATION"

PACKAGES="git curl stow fontconfig fzf unzip zsh"

# Check if script is run with sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run with sudo privileges."
    echo "Please run as: sudo bash $0"
    exit 1
fi

# Exit on any error
set -e

# Display message function
showMessage() {
    echo ""
    echo "===================================="
    echo "$1"
    echo "===================================="
}

confirm() {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure?} [y/N] " response </dev/tty
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

# Get the username of the actual user (not root)
ACTUAL_USER=$(logname || echo "${SUDO_USER:-${USER}}")
USER_HOME=$(eval echo ~${ACTUAL_USER})

showMessage "Setting up system for user: ${ACTUAL_USER}"
showMessage "User home directory: ${USER_HOME}"

# Set locale
showMessage "Setting locale to $LOCALE"
if ! locale -a | grep -q "en_US.UTF-8"; then
    apt install -y locales
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen
    locale-gen en_US.UTF-8
    update-locale LANG=en_US.UTF-8
else
    echo "Locale en_US.UTF-8 already configured"
fi

# Update and upgrade packages
showMessage "Updating and upgrading packages"
apt update && apt -y upgrade

# Set timezone if not already set
if [ "$(timedatectl show --property=Timezone --value)" != "$TIMEZONE" ]; then
    timedatectl set-timezone $TIMEZONE
    echo "Timezone set to $TIMEZONE"
else
    echo "Timezone already set to $TIMEZONE"
fi

# Install required packages
showMessage "Installing required packages"
apt install -y $PACKAGES

# Install eza (modern ls replacement)
showMessage "Installing eza"
if ! command -v eza &> /dev/null; then
    apt install -y gpg
    mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    apt update
    apt install -y eza
else
    echo eza already installed. Skipping...
fi

showMessage "Installing uv"
if ! command -v uv &> /dev/null; then
    if confirm "Install uv?"; then
        curl -LsSf https://astral.sh/uv/install.sh | XDG_BIN_HOME=/usr/local/bin sudo -E sh
        chown root:root /usr/local/bin/uv*
    else
        echo "Skipping uv installation"
    fi
else
    echo uv already installed. Skipping...
fi

# Install Speedtest CLI
showMessage "Installing Speedtest CLI"
if ! command -v speedtest &> /dev/null; then
    if confirm "Install Speedtest CLI?"; then
        curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
    else
        echo "Skipping Speedtest installation"
    fi
else
    echo Speedtest already installed. Skipping...
fi

# Install Nerd Hack Font
showMessage "Installing Nerd Hack Font"
FONT_DIR="/usr/local/share/fonts/NerdFonts"
FONT_SAMPLE="${FONT_DIR}/Hack Regular Nerd Font Complete.ttf"

if [ ! -f "${FONT_SAMPLE}" ]; then
    mkdir -p ${FONT_DIR}
    cd /tmp
    curl -sLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip
    unzip -o Hack.zip -d ${FONT_DIR}
    chmod 644 ${FONT_DIR}/*.ttf
    fc-cache -fv
    rm -f Hack.zip
fi

# Clone dotfiles repository
showMessage "Setting up dotfiles"
DOTFILES_DIR="${USER_HOME}/dotfiles"

if [ ! -d "${DOTFILES_DIR}" ]; then
    # Make sure we run git commands as the actual user
	sudo -u ${ACTUAL_USER} git clone https://github.com/sarpuser/dotfiles.git ${DOTFILES_DIR}
    chown -R ${ACTUAL_USER}:${ACTUAL_USER} ${DOTFILES_DIR}
    echo "Dotfiles repository cloned"
else

    echo "Dotfiles repository already exists"
fi

# Change remote URL to SSH
cd ${DOTFILES_DIR} && git remote set-url origin git@github.com:sarpuser/dotfiles.git && cd "$USER_HOME"
echo Changed dotfiles URL to SSH

# Stow dotfiles - safely
showMessage "Stowing dotfiles"
sudo -u "${ACTUAL_USER}" stow -R -d "${USER_HOME}/dotfiles" .

# Set zsh as default shell for the actual user
showMessage "Setting zsh as default shell for ${ACTUAL_USER}"
chsh -s "$(which zsh)" "${ACTUAL_USER}"

showMessage "Setup completed. Run 'exec zsh' to switch to zsh."
