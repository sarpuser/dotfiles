### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit's installer chunk

# Add Homebrew apps to path
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Add local binaries (OMP, Zoxide, etc. to PATH)
export PATH=$PATH:~/.local/bin

# Activate Oh My Posh
if [[ $(tty) =~ /dev/pts || -n $TERM_PROGRAM ]]; then
  eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/omp-emulator.toml)"
else
  eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/omp-tty.toml)"
fi

# Load plugin settings
source "$HOME/.config/zsh/zsh-tab-title.zsh"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light trystan2k/zsh-tab-title
zinit light sarpuser/zsh-shift-select

# Add OMZ Plugins
# zinit snippet OMZP::git
zinit snippet OMZP::sudo
if [[ "$OSTYPE" == "darwin"* ]]; then
  # This snippet will only be installed on mac
  zinit snippet OMZP::macos
fi

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

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
alias python='python3'
alias pip='pip3'
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
