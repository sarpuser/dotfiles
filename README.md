## Overview
This repository includes configuration files for various programs, as well as setup scripts for Mac and Debian that download all the dependencies and any desired applications, set settings, and copy this dotfiles repository.

### Using the dotfiles without any additional setup
```bash
git clone https://www.github.com/sarpuser/dotfiles ~/dotfiles
stow -d ~/dotfiles .
```

#### Requirements
  - [GNU Stow](#gnu-stow)
  - [Hack Nerd Font](https://www.nerdfonts.com/)
  - [Oh-My-Posh](https://ohmyposh.dev/)

> [!IMPORTANT]
> If using a different terminal emulator, its font should be changed to the Nerd font.

## Setup Scripts

### Mac
This script will install Homebrew (if not already installed), install brew & App Store apps, set up terminal environment by cloning this repository, and change settings. The Homebrew apps include desktop apps and if these are found on the Applications directory (installed from a website perhaps), the script will replace the executables with the Homebrew version without app data loss. Each of the script components (Homebrew & apps, terminal, and settings) are opt-in and safe to run multiple times.

```bash
bash <(curl -fsS https://raw.githubusercontent.com/sarpuser/dotfiles/main/scripts/mac-setup.sh)
```

<details>
<summary>Installed Apps</summary>

  - [1Password](https://1password.com/)
  - [1Password CLI](https://developer.1password.com/docs/cli/get-started/) # needed for Alfred
  - [Alacritty](https://alacritty.org/index.html)
  - [AlDente](https://apphousekitchen.com/)
  - [Alfred](https://www.alfredapp.com/)
  - [Arc Browser](https://arc.net/)
  - [App Cleaner](https://freemacsoft.net/appcleaner/)
  - [Balena Etcher](https://etcher.balena.io/)
  - [Bartender](https://www.macbartender.com/Bartender5/)
  - [Better Display](https://github.com/waydabber/BetterDisplay)
  - \[Optional\] [Discord](https://www.discord.com)
  - [defaultbrowser](https://github.com/kerma/defaultbrowser)
  - [eza](https://github.com/eza-community/eza)
  - [Hack Nerd Font](https://www.nerdfonts.com/)
  - [Hand Mirror](https://handmirror.app/)
  - [fping](https://fping.org/)
  - [fzf](https://github.com/junegunn/fzf)
  - [gh](https://cli.github.com/)
  - git
  - [git-delta](https://github.com/dandavison/delta)
  - \[Optional\] [KeepingYouAwake](https://keepingyouawake.app/)
  - [Keyboard Clean Tool](https://folivora.ai/keyboardcleantool)
  - [Logi Options+](https://www.logitech.com/en-us/software/logi-options-plus.html)
  - [mas](https://github.com/mas-cli/mas)
  - [Mission Control Plus](https://www.fadel.io/missioncontrolplus)
  - [neofetch](https://github.com/dylanaraps/neofetch)
  - [Oh My Posh](https://ohmyposh.dev/)
  - [picocom](https://github.com/npat-efault/picocom)
  - \[Optional\] [Private Internet Access](https://www.privateinternetaccess.com/)
  - pyenv
  - [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
  - [Rust & Rustup](https://www.rust-lang.org/)
  - [shellcheck](https://www.shellcheck.net/)
  - [Spark Mail](https://sparkmailapp.com/)
  - [Speedtest CLI](https://www.speedtest.net/apps/cli)
  - [Spotify](https://open.spotify.com/)
  - \[Optional\] [Steam](https://www.steamdeck.com/en/)
  - [Things](https://apps.apple.com/us/app/things-3/id904280696?mt=12)
  - [GNU Stow](https://www.gnu.org/software/stow/)
  - [Visual Studio Code](https://code.visualstudio.com/)
  - [UTM](https://mac.getutm.app/)
  - [Wireguard Go](https://github.com/WireGuard/wireguard-go)
  - [zoxide](https://github.com/ajeetdsouza/zoxide)
</details>

## Reference
### [GNU Stow](https://www.gnu.org/software/stow/manual/stow.html)
Stow manages symlinks for all the files in the dotfiles repository. By default it creates symlinks for the selected "packages" (the dotfiles in this case) in the parent directory. For `~/dotfiles/.zshrc`, stow would create the symlink `~/.zshrc`. Likewise, for `~/dotfiles/.config/alacritty` it would create `~/.config/alacritty`.

Any files/folders that stow should not create symlinks for can be placed in [`.stow-local-ignore`](/.stow-local-ignore)

#### Syntax
```bash
stow [options] package
```
> [!NOTE]
> The `package` in the stow syntax is in relation to the stow directory (see below). Using `.` would mean all the packages in the stow directory, NOT the current directory.

#### Options
- `-d`: Stow directory (directory where all the "packages" are stored)
  - Default: Current directory
- `-t`: Target directory (where all the symlinks will be created)
  - Default: Parent of stow directory
- `-R`: Restow (delete all symlinks and recreate them)
- `-D`: Delete all symlinks