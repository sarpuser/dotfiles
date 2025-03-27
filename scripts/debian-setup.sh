#!/bin/bash
# Note: This script is intended to be run with sudo privileges
# This script is idempotent - it can be safely re-executed multiple times

LOCATION=New_York
TIMEZONE="America/$LOCATION"
LOCALE="US/$LOCATION"

PACKAGES="git curl stow fontconfig python3 python3-pip fzf zsh"

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
    echo "===================================="
    echo "$1"
    echo "===================================="
}

# Function to check if a package is installed
isPackageInstalled() {
    dpkg -l "$1" | grep -q "^ii" > /dev/null 2>&1
    return $?
}

# Get the username of the actual user (not root)
ACTUAL_USER=$(logname || echo "${SUDO_USER:-${USER}}")
USER_HOME=$(eval echo ~${ACTUAL_USER})

showMessage "Setting up system for user: ${ACTUAL_USER}"
showMessage "User home directory: ${USER_HOME}"

# Update and upgrade packages
showMessage "Updating and upgrading packages"
apt update && apt -y upgrade

# Set locale
showMessage "Setting locale to $LOCALE"
if ! locale -a | grep -q "en_US.UTF-8"; then
    apt install -y locales
    locale-gen en_US.UTF-8
    update-locale LANG=en_US.UTF-8
else
    echo "Locale en_US.UTF-8 already configured"
fi

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
if ! isPackageInstalled "eza"; then
    # Check if repository is already configured
    if [ ! -f /etc/apt/sources.list.d/eza.list ]; then
        apt install -y gpg
        mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/eza.gpg
        echo "deb [signed-by=/etc/apt/keyrings/eza.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/eza.list
        chmod 644 /etc/apt/keyrings/eza.gpg
        apt update
    fi
    apt install -y eza
fi

# Install uv (fast Python package installer)
showMessage "Installing uv"
if ! command -v uv &> /dev/null; then
    # Create directories with proper permissions
    mkdir -p /opt/cargo/bin /opt/rustup

    # Option 1: Use the official installer with custom paths
    curl -sSf https://astral.sh/uv/install.sh > /tmp/uv-install.sh
    chmod +x /tmp/uv-install.sh
    CARGO_HOME=/opt/cargo RUSTUP_HOME=/opt/rustup /tmp/uv-install.sh
    rm /tmp/uv-install.sh

    # Create symlink to make uv available in PATH
    ln -sf /opt/cargo/bin/uv /usr/local/bin/uv

    # Set permissions so all users can access
    chmod -R 755 /opt/cargo /opt/rustup
fi

# Install Speedtest CLI
showMessage "Installing Speedtest CLI"
if ! isPackageInstalled "speedtest"; then
    apt install -y gnupg1 apt-transport-https dirmngr
    # Check if repository is already configured
    if [ ! -f /etc/apt/sources.list.d/ookla_speedtest-cli.list ]; then
        # Download the script first instead of piping directly to bash
        curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh > /tmp/speedtest-repo.sh
        chmod +x /tmp/speedtest-repo.sh
        /tmp/speedtest-repo.sh
        rm /tmp/speedtest-repo.sh
    fi
    apt install -y speedtest
fi

# Install Nerd Hack Font
showMessage "Installing Nerd Hack Font"
FONT_DIR="/usr/local/share/fonts/NerdFonts"
FONT_SAMPLE="${FONT_DIR}/Hack Regular Nerd Font Complete.ttf"

if [ ! -f "${FONT_SAMPLE}" ]; then
    mkdir -p ${FONT_DIR}
    cd /tmp
    curl -LO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip
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
	git clone https://github.com/sarpuser/dotfiles.git ${DOTFILES_DIR}
    echo "Dotfiles repository cloned"
else

    echo "Dotfiles repository already exists"
fi

# Change remote URL to SSH
cd ${DOTFILES_DIR} && git remote set-url origin git@github.com:sarpuser/dotfiles.git && cd $USER_HOME
echo Changed dotfiles URL to SSH

# Stow dotfiles - safely
showMessage "Stowing dotfiles"
stow -R -d ${USER_HOME}/dotfiles .

# Disable unwanted MOTD components but keep update notifications
showMessage "Configuring MOTD settings"
# Disable the news, ads, help text and other unwanted motd components
MOTD_FILES=(
    "/etc/update-motd.d/10-help-text"
    "/etc/update-motd.d/50-motd-news"
    "/etc/update-motd.d/88-esm-announce"
    "/etc/update-motd.d/91-contract-ua-esm-status"
    "/etc/update-motd.d/80-livepatch"
    "/etc/update-motd.d/98-reboot-required"
)

for file in "${MOTD_FILES[@]}"; do
    if [ -f "$file" ] && [ -x "$file" ]; then
        chmod -x "$file"
        echo "Disabled MOTD component: $file"
    elif [ -f "$file" ]; then
        echo "MOTD component already disabled: $file"
    else
        echo "MOTD component not found: $file"
    fi
done
# Keep update notifications (20-updates-available, 90-updates-available, etc.)

# Set zsh as default shell for the actual user
showMessage "Setting zsh as default shell for ${ACTUAL_USER}"
chsh -s "$(which zsh)" ${ACTUAL_USER}

showMessage "Setup completed successfully!"
# Switch to zsh shell to complete setup
echo "Switching to zsh shell..."
exec zsh