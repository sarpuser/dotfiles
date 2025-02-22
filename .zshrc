### Antidote installer
if [[ ! -d "$HOME/.antidote" ]]; then
  echo Installing Antidote...
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$HOME/.antidote"
fi
source "$HOME/.antidote/antidote.zsh"
zstyle ':antidote:bundle' file "$HOME/.config/zsh/zsh-plugins.txt"
antidote load
### End of Antidote installer

### Oh My Posh Installer
[[ ! -f "$HOME/.local/bin/oh-my-posh" ]] && curl -s https://ohmyposh.dev/install.sh | bash -s

# Add binary directories to path
export PATH=$PATH:~/.local/bin

# Set Cargo and Rust home directories
export CARGO_HOME="/opt/cargo"
export RUSTUP_HOME="/opt/rustup"

# Add Homebrew apps to path
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Activate Oh My Posh
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  if [[ $(tty) =~ /dev/pts || -n $TERM_PROGRAM ]]; then
    eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/omp-emulator.toml)"
  else
    eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/omp-tty.toml)"
  fi
fi

# Load plugin settings
source "$HOME/.config/zsh/zsh-tab-title.zsh"

# if [[ "$OSTYPE" == "darwin"* ]]; then
#   # This snippet will only be installed on mac
#   antidote install ohmyzsh/ohmyzsh path:plugins/macos
# fi

# Load completions
autoload -Uz compinit && compinit

# FIXME: This deletes the whole line rather than before cursor
# Keybindings
function backward-kill-line() {
  zle set-mark-command -w
  zle beginning-of-line
  zle kill-region -w
}

zle -N backward-kill-line

# bindkey '^[[3;9?' backward-kill-line
bindkey '^[[3;9~' backward-kill-line
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word
bindkey '^[[1;9D' beginning-of-line
bindkey '^[[1;9C' end-of-line

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
[[ -f $HOME/.config/zsh/aliases.zsh ]] && source "$HOME/.config/zsh/aliases.zsh"
alias ls='eza -laa --color=always --icons=auto'
alias aliases='nano $HOME/.config/zsh/aliases.zsh && source $HOME/.config/zsh/aliases.zsh'
alias venv-new="python -m venv .venv"
alias venv="source .venv/bin/activate"
alias diff='delta'
alias colortest='curl -sS https://raw.githubusercontent.com/pablopunk/colortest/master/colortest | bash'

# Shell integrations
fzfVersion=$(fzf --version | awk '{print $1}')
if printf '0.48.0\n%s\n' "$fzfVersion" | sort -V -C; then
  # If fzf version is greater than 0.48.0
  source <(fzf --zsh)
else
  source "/usr/share/doc/fzf/examples/completion.zsh"
fi

zsh-defer eval "$(pyenv init -)"
eval "$(zoxide init --cmd cd zsh)"
