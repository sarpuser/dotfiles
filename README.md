# Sarp's Linux and Mac dotfiles and setup scripts

- [Overview](#overview)
- [Setup](#setup)
- [Reference](#reference)
  - [Installed Applications](#installed-applications)
  - [GNU Stow](#gnu-stow)

## Overview
The scripts in the [dotfiles/scripts](/scripts) directory will install all required dependencies, clone this repository and symlink the configuration files using [GNU Stow.](https://www.gnu.org/software/stow/manual/stow.html) Linux scripts that have `desktop` in the name should be used for setting up new desktop environments. To run the scripts go to [setup.](#setup)

## Setup

<details>
  <summary>Only CLI Applications</summary>

  ```bash
  sudo -E curl -S https://raw.githubusercontent.com/sarpuser/dotfiles/main/scripts/setup.sh | bash
  ```

</details>

<details>
  <summary>CLI & Desktop Applications (No Desktop Environment)</summary>

  ```bash
  sudo -E curl -S https://raw.githubusercontent.com/sarpuser/dotfiles/main/scripts/setup.sh | bash /dev/stdin --desktop-apps
  ```

</details>

<details>
  <summary>Desktop Environment & All Apps</summary>
  <br>

  This script will set up brand new desktop environment. This should only be used for headless systems that will be transitioned to a monitor setup.
  ```bash
  sudo -E curl -S https://raw.githubusercontent.com/sarpuser/dotfiles/main/scripts/setup.sh | bash /dev/stdin --desktop-env
  ```

</details>

## Reference
### Installed Applications
<details>
<summary>CLI Applications</summary>

  - git
  - Python3
  - Python3-venv
  - zsh
  - [Zinit](https://zdharma-continuum.github.io/zinit/wiki/INTRODUCTION/) - zsh plugin manager
  - [Oh My Posh](https://ohmyposh.dev/docs) - multi shell prompt manager
  - [zoxide](https://github.com/ajeetdsouza/zoxide/tree/main) - Better `cd`
  - [fzf](https://github.com/junegunn/fzf) - Fuzzy search
  - [git-delta](https://github.com/dandavison/delta) - CLI diff tool
  - [eza](https://github.com/eza-community/eza?tab=readme-ov-file) - Better `ls`
  - [GNU Stow](#gnu-stow) - Dotfile management
  - Speedtest CLI
  - [Hack Nerd Font](https://github.com/source-foundry/Hack)
  - Homebrew **(Mac only)** - Mac package manager

</details>

<details>
<summary>zsh plugins</summary>

  - zsh syntax highlighting
  - zsh completions
  - zsh autosuggestions
  - fzf-tab
  - zsh shift select
  - [Oh My Zsh: git](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git)
  - [Oh My Zsh: sudo](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/sudo) - Double tap `Esc` to add sudo to last command if prompt empty or current command that is being typed
  - [Oh My Zsh: macos](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/macos) **(Mac only)**
    - `ofd`: Open passed directories (or $PWD by default) in Finder
    - `cdf`: `cd` to the current Finder directory
    - `pfd`: Return the path of the frontmost Finder window
    - `quick-look`: Quick-Look a specified file
    - `man-preview`: Open man pages in Preview app
    - `rmdsstore`: Remove `.DS_Store` files recursively in a directory

</details>

<details>
  <summary>Desktop Applications</summary>

  - [Alacritty Terminal](https://alacritty.org/)
  - p4merge - Merge & diff tool
    - Despite git-delta being installed, p4merge is set as git diff tool, since it is graphical
  - Arc Browser (Mac only)
  - Alfred (Mac only)
  - Keeping you awake (Mac only)
  - Bartender (Mac only)
  - 1Password (Mac only)
  - UTM (Mac only) - VM Hypervisor
  - Discord (Mac only)
  - Spotify (Mac only)
</details>

<details>
  <summary>Desktop Environment</summary>

  WIP

</details>

### GNU Stow