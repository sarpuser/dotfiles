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
	if [[ ! -d /Library/Developer/CommandLineTools ]]; then
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
	if [[ -f "/opt/homebrew/bin/brew" ]]; then
		echo Homebrew found at "$(which brew), skipping installation"
	else
		echo Installing Homebrew...
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		# Add Homebrew apps to PATH
		echo Adding Homebrew apps to PATH...
		eval "$(/opt/homebrew/bin/brew shellenv)"
	fi


	brewFormulae="defaultbrowser eza fping fzf gh git git-delta mas neofetch picocom pyenv rustup shellcheck speedtest stow wireguard-tools xz zoxide"
	brewCasks="1password 1password-cli alacritty alfred arc appcleaner balenaetcher bartender betterdisplay dropzone font-hack-nerd-font keyboardcleantool logi-options+ mission-control-plus raspberry-pi-imager spotify visual-studio-code utm zoom"

	# Problematic for work
	confirm "Do you want to install Discord?" && brewCasks=$brewCasks" discord" || echo skipping Discord...
	confirm "Do you want to install KeepingYouAwake?" && brewCasks=$brewCasks" keepingyouawake" || echo skipping KeepingYouAwake...
	confirm "Do you want to install PIA VPN?" && brewCasks=$brewCasks" private-internet-access" || echo skipping PIA VPN...
	confirm "Do you want to install Prism Launcher?" && brewCasks=$brewCasks" prismlauncher" || echo skipping Prism Launcher...
	confirm "Do you want to install Steam?" && brewCasks=$brewCasks" steam" || echo skipping Steam...
	confirm "Do you want to install Copilot Money?" && brewCasks=$brewCasks" copilot" || echo Skipping Copilot...

	# Install Homebrew apps
	echo "Installing Homebrew apps..."
	brew tap teamookla/speedtest
	brew update
	brew install $brewFormulae # --force replaces self downloaded apps
	brew install --cask $brewCasks

	# Install App Store Apps
	echo "Installing App Store Apps..."
	mas install 1502839586 # Hand Mirror
	mas install 1176895641 # Spark Mail
	mas install 904280696 # Things 3

	echo Installed brew apps:
	brew list

	echo ""
	echo "Installed App Store Apps:"
	mas list | while read -r app; do
		echo "    - $app"
	done
	echo ""
}


# Remove junk apps
removeDefaultUnusedApps() {
	sudo mas uninstall 682658836 && echo Uninstalled GarageBand # GarageBand
}

# Set up terminal environment
setUpTerminal() {
	if [[ -d "${HOME}/dotfiles" ]]; then
		echo dotfiles directory found. Skipping cloning...
	else
		echo Cloning dotfiles repository...
		git clone https://github.com/sarpuser/dotfiles.git "${HOME}/dotfiles"
	fi

	if ! command -v stow > /dev/null 2>&1; then
		echo "Stow not installed. Skipping..."
	else
		# A placeholder file is needed in ~/.config before stowing so stow has to symlink individual directories.
		# This is so that if an app creates configs in ~/.config, it does not show up in the dotfiles directory.
		[[ ! -d "$HOME/.config" ]] && mkdir -p "$HOME/.config"
		touch "$HOME/.config/.stowblockdirectsymlink"
		stow -Rd "${HOME}/dotfiles" . && echo Configuration files cloned and stowed
	fi

	echo Setting up git...
	git config --global include.path "$HOME/.config/git/public.gitconfig"

	read -r -p "Set name for git? ($(git config --global user.name)) " gitname
	[[ -n "$gitname" ]] && git config --global user.name "$gitname"

	read -r -p "Set email for git? ($(git config --global user.email)) " gitemail
	[[ -n "$gitemail" ]] && git config --global user.email "$gitemail"

	if ! gh auth status > /dev/null 2>&1; then
		confirm "Do you want to authenticate with GitHub" && gh auth login
	fi

	confirm "Change ownership of /opt to $USER:staff?" && sudo chown -R "$USER":staff /opt

	[[ ! -d /opt/rustup ]] && confirm "Do you want to install Rust?" && RUSTUP_HOME="/opt/rustup" CARGO_HOME="/opt/cargo" bash -c 'curl https://sh.rustup.rs -sSf | sh -s -- -y'

	confirm "Do you want to install the latest Python 3 version? ($(pyenv latest 3))" && pyenv install 3 && pyenv global "$(pyenv latest 3)" && echo "Default python set to $(pyenv global)"

	[[ ! -d "$HOME/development" ]] && confirm "Do you want to create a ~/development directory?" && mkdir -p "$HOME/development" && echo Created ~/development directory

	[[ -d "$HOME/development" ]] && confirm "Would you like to clone repositories to the ~/development directory?" && cloneReposIntoDevelopmentDir

	[[ ! -d "$HOME/sandbox" ]] && confirm "Do you want to create the ~/sandbox directory?" && mkdir -p "$HOME/sandbox" && echo Created ~/sandbox directory
}

cloneReposIntoDevelopmentDir() {
	if [[ -d "$HOME/development" ]] && which fzf > /dev/null && gh auth status > /dev/null 2>&1; then
		gh repo list | fzf -m | while read -r repoInfo; do
			repo=$(echo "$repoInfo" | head -n1 | awk '{print $1;}')
			repoName="$(echo "$repo" | cut -d/ -f2)"
			git clone "https://github.com/$repo" "$HOME/development/$repoName"
		done
	else
		echo "There was a problem with cloning into ~/development - dir: $([[ -d "$HOME/development" ]] && echo true || echo false), fzf: $(which fzf), gh auth: $(gh auth status)"
	fi
}

setDefaultBrowser() {
	if [[ -f /opt/homebrew/bin/defaultbrowser && -d /Applications/Arc.app ]]; then
		echo Setting default browser to Arc...
		defaultbrowser browser
	else
		echo Could not set default browser to Arc. Either defaultbrowser or Arc is missing. Skipping...
	fi
}

changeSystemPreferences() {
	if [[ -f "$HOME/dotfiles/scripts/mac-settings.sh" ]]; then
		bash "$HOME/dotfiles/scripts/mac-settings.sh"
	else
		bash <(curl -s https://raw.githubusercontent.com/sarpuser/dotfiles/refs/heads/main/scripts/mac-settings.sh)
	fi
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

[[ -z "$(which brew)" && -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

while true; do
	echo "Options: "
	echo "   x: Install XCode Command Line Tools & Rosetta 2"
	echo "   h: Install Homebrew and App Store apps"
	echo "   d: Setup dotfiles, terminal environment, & git"
	echo "   r: Clone repositories into ~/development"
	echo "   u: Remove default unused apps"
	echo "   b: Set default browser to Arc"
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
		[rR])
			cloneReposIntoDevelopmentDir
			;;
		[pP])
			changeSystemPreferences
			;;
		[uU])
			removeDefaultUnusedApps
			;;
		[bB])
			setDefaultBrowser
			;;
		[qQ])
			exit
			;;
		*)
			;;
	esac
done
