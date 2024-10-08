# Set to true to disable auto titling
ZSH_TAB_TITLE_DISABLE_AUTO_TITLE=false

# Setting this to true will only display the current directory
# instead of the full path (truncated at 20 characters)
ZSH_TAB_TITLE_ONLY_FOLDER=true

# When set to true the running command will be displayed
# along with the folder name: 'ls' in ~/dotfiles will display "dotfiles:ls"
ZSH_TAB_TITLE_CONCAT_FOLDER_PROCESS=false

# Set to true to display full command with arguments (nano .zshrc vs nano)
ZSH_TAB_TITLE_ENABLE_FULL_COMMAND=true

# Uncomment to use custom prefix before folder
# Default: "username@host:"
ZSH_TAB_TITLE_PREFIX='%m: '

# If set to true, no prefix will be displayed
ZSH_TAB_TITLE_DEFAULT_DISABLE_PREFIX=false

# Uncomment to enable suffix after folder and command
# ZSH_TAB_TITLE_SUFFIX=' in %m'

# By default the tab title is set for iTerm, Hyper, and where $TERM
# is set to one of cygwin,xterm*,putty*,rxvt*,ansi,screen*,tmux*.
# To set additional terms add them to the following variable
ZSH_TAB_TITLE_ADDITIONAL_TERMS='alacritty|kitty|foot'