#! /bin/bash

############################################################################################
# Helper Functions                                                                         #
############################################################################################

# Confirmation Prompt
confirm() {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure?} [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

############################################################################################
# Setup Functions                                                                          #
############################################################################################

# Install Dev Tools
installDevTools() {
	echo Installing XCode CLI...
	if [[ -d /Library/Developer/CommandLineTools ]]; then
		xcode-select --install
		confirm "Did you accept XCode EULA in the new window?"
	else
		echo "Command Line Tools found at $(xcode-select -p). Skipping install."
	fi

	if [[ "$(/usr/bin/arch)" == "arm64" ]]; then
		echo Installing Rosetta 2...
		softwareupdate --install-rosetta --agree-to-license
	fi
}

# Install Homebrew + apps
installApps() {
	# Install homebrew
	if [[ -f "$(which brew)" ]]; then
		echo Homebrew found at "$(which brew), skipping installation"
	else
		echo Installing Homebrew...
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		# Add Homebrew apps to PATH
		echo Adding Homebrew apps to PATH...
		eval "$(/opt/homebrew/bin/brew shellenv)"
	fi

	brewApps="1password 1password-cli alacritty aldente alfred arc appcleaner balenaetcher bartender bettedisplay eza font-hack-nerd-font fping fzf gh git git-delta keyboardcleantool logi-options+ mas mission-control-plus neofetch oh-my-posh picocom pyenv raspberry-pi-imager rust rustup shellcheck speedtest spotify stow visual-studio-code utm wireguard-go zoxide"

	# Problematic for work
	confirm "Do you want to install Discord?" && brewApps=$brewApps" discord" || echo skipping Discord...
	confirm "Do you want to install KeepingYouAwake?" && brewApps=$brewApps" keepingyouawake" || echo skipping KeepingYouAwake...
	confirm "Do you want to install PIA VPN?" && brewApps=$brewApps" private-internet-access" || echo skipping PIA VPN...
	confirm "Do you want to install Prism Launcher?" && brewApps=$brewApps" prismlauncher" || echo skipping Prism Launcher...
	confirm "Do you want to install Steam?" && brewApps=$brewApps" steam" || echo skipping Steam...

	# Sort apps
	brewApps=$(echo "$brewApps" | xargs -n1 | sort -d | xargs)

	# Install Homebrew apps
	echo "Installing Homebrew apps..."
	brew install --force "$brewApps" # --force replaces self downloaded apps

	# Install App Store Apps
	echo "Installing App Store Apps..."
	mas install 1502839586 # Hand Mirror
	mas install 1176895641 # Spark Mail
	mas install 904280696 # Things 3

	echo ""
	echo "Installed brew apps:"
	for package in $brewApps; do
		packageInfo=$(brew info "$package")
		if echo "$packageInfo" | grep -q "bottled"; then
			packageDesc="$(echo "$packageInfo" | awk 'NR==2 {print}')"
		else
			packageDesc="$(echo "$packageInfo" | grep -A1 "Description" | tail -n1)"
		fi

		echo "    - $package: $packageDesc"
	done

	echo ""
	echo "Installed App Store Apps:"
	mas list | while read -r app; do
		echo "    - $app"
	done
	echo ""
}


# Set up terminal environment
setUpTerminal() {
	if [[ -d "${HOME}/dotfiles" ]]; then
		echo dotfiles directory found. Skipping cloning...
	else
		echo Cloning dotfiles repository...
		git clone https://github.com/sarpuser/dotfiles.git "${HOME}"
	fi

	if ! command -v stow > /dev/null 2>&1; then
		echo "Stow not installed. Skipping..."
	else
		stow -Rd "${HOME}/dotfiles" . && echo Configuration files cloned and stowed
	fi

	echo Setting up git...
	git config --global include.path "$HOME/.config/git/public.gitconfig"

	confirm "Set name for git? ($(git config --global user.name)) " && {
		read -r -p "What name would you like to use for git? " gitname
		git config --global user.name "$gitname"
		echo "Set name in git to $(git config --global user.name)"
	}

	confirm "Set email for git? ($(git config --global user.email)) " && {
		read -r -p "What email would you like to use for git? " gitemail
		git config --global user.email "$gitemail"
		echo "Set email in git to $(git config --global user.email)"
	}

	confirm "Do you want to authenticate with GitHub" && gh auth login

	confirm "Do you want to change ownership of /usr/local to $USER:staff?" && sudo chown -R "$USER":staff /usr/local
}

# TODO: Change System Preferences
changeSystemPreferences() {
	echo Not yet implemented
}

############################################################################################
# Entry Point                                                                              #
############################################################################################

echo "   _____                  _       __  __               _____      _               ";
echo "  / ____|                ( )     |  \/  |             / ____|    | |              ";
echo " | (___   __ _ _ __ _ __ |/ ___  | \  / | __ _  ___  | (___   ___| |_ _   _ _ __  ";
echo "  \___ \ / _\` | '__| '_ \  / __| | |\/| |/ _\` |/ __|  \___ \ / _ \ __| | | | '_ \ ";
echo "  ____) | (_| | |  | |_) | \__ \ | |  | | (_| | (__   ____) |  __/ |_| |_| | |_) |";
echo " |_____/ \__,_|_|  | .__/  |___/ |_|  |_|\__,_|\___| |_____/ \___|\__|\__,_| .__/ ";
echo "                   | |                                                     | |    ";
echo "                   |_|                                                     |_|    ";


echo "

This is a script to set up a brand new mac. It installs apps, downloads dotfile configs, and sets preferences. If apps have been installed from a website, this script will reinstall them through brew without any loss in data.
"

while true; do
	echo "Options: "
	echo "   x: Install XCode Command Line Tools & Rosetta 2"
	echo "   h: Install Homebrew and App Store apps"
	echo "   d: Setup dotfiles, terminal environment, & git"
	echo "   p: Set system preferences"
	echo "   q: Quit"

	read -r -p "Select an option: " selection
	case "$selection" in
		[xX])
			installDevTools
			;;
		[hH])
			installApps
			;;
		[dD])
			setUpTerminal
			;;
		[pP])
			changeSystemPreferences
			;;
		[qQ])
			exit
			;;
		*)
			;;
	esac
done