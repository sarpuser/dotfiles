### Antidote installer
if [[ ! -d "$HOME/.antidote" ]]; then
  echo Installing Antidote...
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$HOME/.antidote"
fi
source "$HOME/.antidote/antidote.zsh"
zstyle ':antidote:bundle' file "$HOME/.config/zsh/zsh-plugins.txt"
antidote load
### End of Antidote installer

# Check and install Alacritty terminfo if needed
if [[ "$TERM_PROGRAM" == "alacritty" && ! $(infocmp alacritty &>/dev/null) ]]; then
  mkdir -p ~/.terminfo
  export TERMINFO_DIRS=$HOME/.terminfo:/usr/share/terminfo
  if ! curl -sSL https://raw.githubusercontent.com/alacritty/alacritty/master/extra/alacritty.info | tic -xe alacritty,alacritty-direct -o ~/.terminfo - &>/dev/null; then
    export TERM=xterm-256color
  fi
fi

### Set git global config directory
export GIT_CONFIG_GLOBAL=$HOME/.config/git/public.gitconfig

# Add binary directories to path
export PATH=$PATH:~/.local/bin

# Set Cargo and Rust home directories
export CARGO_HOME="/opt/cargo"
export RUSTUP_HOME="/opt/rustup"

# Source system dependent env vars
[[ -f "$HOME/.shellenv" ]] && source "$HOME/.shellenv"

### Tool Installer
[[ ! -f "$HOME/.local/bin/oh-my-posh" ]] && curl -s https://ohmyposh.dev/install.sh | bash -s
[[ ! -f "$HOME/.local/bin/zoxide" ]] && curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# Add Homebrew apps to path
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Log out after 20 mins of inactivity
if [[ "$(uname)" == Linux ]]; then
  export TMOUT=1200
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

# Basic ZSH options for better completion experience
setopt AUTO_MENU
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt AUTO_PARAM_SLASH
setopt NO_FLOW_CONTROL

# FIXME: This deletes the whole line rather than before cursor
# Keybindings
# function backward-kill-line() {
#   zle set-mark-command -w
#   zle beginning-of-line
#   zle kill-region -w
# }

# zle -N backward-kill-line

# bindkey '^[[3;9?' backward-kill-line
bindkey '^[[3;9~' backward-kill-line
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word
bindkey '^[[1;9D' beginning-of-line
bindkey '^[[1;9C' end-of-line

# Key bindings for accepting autosuggestions
bindkey '^[[C' autosuggest-accept  # Right arrow

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

# Real-time autosuggestions configuration
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zcompcache"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}%B--- %d%b%f'
zstyle ':completion:*:warnings' format '%F{red}no matches found%f'

# fzf-tab configuration
zstyle ':fzf-tab:complete:*' fzf-flags --height=40% --layout=reverse --info=inline --border
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color=always $realpath'

# Disable preview in SSH sessions if needed
if [[ -n $SSH_CONNECTION ]]; then
  zstyle ':fzf-tab:*' fzf-preview ''
  zstyle ':fzf-tab:*' fzf-flags --height=30% --layout=reverse
fi

# Enable menu selection
zmodload -i zsh/complist

# Aliases
[[ -f $HOME/.config/zsh/aliases.zsh ]] && source "$HOME/.config/zsh/aliases.zsh"
alias ls='eza -laa --color=always --icons=auto'
alias aliases='nano $HOME/.config/zsh/aliases.zsh && source $HOME/.config/zsh/aliases.zsh'
alias gitignore='cp $HOME/.config/git/gitignore .gitignore'
alias venv-new="python -m venv .venv"
alias pip="echo pip is aliased to uv pip. Use pip3 for default pip. && uv pip"
alias venv="source .venv/bin/activate"
alias py-ignore="curl -sSoL https://gist.githubusercontent.com/sarpuser/799069ce3c377f437645c5f6200f87dd/raw/.gitignore"
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

eval "$(zoxide init --cmd cd zsh)"
