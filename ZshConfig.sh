#!/usr/bin/env sh

cd ~/;

echo "Verifying the default shell..." &&
if [[ "$SHELL" == "$(which zsh)" ]]; then
    echo "Zsh is the default shell!";
else
    echo "Zsh is not the default shell." &&
    echo "Setting Zsh as the default shell..." &&
	sudo chsh -s $(which zsh) $USER </dev/tty;
fi

echo "Installing Oh My Zsh...";
if [ -d "$HOME/.oh-my-zsh" ]; then
	echo "Oh My Zsh has been already installed."
else
	RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "Installing custom zsh theme...";
mkdir -p ~/.oh-my-zsh/custom/themes
cat << 'catEND' > ~/.oh-my-zsh/custom/themes/pedrorochaosx.zsh-theme
# pedrorochaosx-zsh-theme
# Use with a dark background and 256-color terminal!

function virtualenv_info {
    [ $CONDA_DEFAULT_ENV ] && echo "($CONDA_DEFAULT_ENV) "
    [ $VIRTUAL_ENV ] && echo '('`basename $VIRTUAL_ENV`') '
}

function prompt_char {
    echo ''
}

function box_name {
  local box="${SHORT_HOST:-$HOST}"
  [[ -f ~/.box-name ]] && box="$(< ~/.box-name)"
  echo "${box:gs/%/%%}"
}

PROMPT="%B%{$FG[208]%}%n %{$FG[239]%}at %{$FG[220]%}%D{%Y-%m-%d} %* %{$FG[239]%}in %{$FG[226]%}%~%{$reset_color%}\$(git_prompt_info)\$(ruby_prompt_info) \$(virtualenv_info)>%b "

ZSH_THEME_GIT_PROMPT_PREFIX="%B%{$FG[239]%}->%{$FG[255]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}%b"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$FG[202]%} x"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$FG[040]%}"
ZSH_THEME_RUBY_PROMPT_PREFIX=" %{$FG[239]%}using%{$FG[243]%} ‹"
ZSH_THEME_RUBY_PROMPT_SUFFIX="›%{$reset_color%}"
catEND

cat << 'catEND' > ~/.zshrc
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export PATH="$HOME/.local/bin:$PATH"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="pedrorochaosx"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh

# For a full list of active aliases, run `alias`.

alias lsblkk='echo "lsblk -o NAME,TYPE,FSTYPE,FSUSE%,FSAVAIL,SIZE,MOUNTPOINTS"; lsblk -o NAME,TYPE,FSTYPE,FSUSE%,FSAVAIL,SIZE,MOUNTPOINTS'
alias lzg='lazygit'
alias lzd='lazydocker'
alias gac='git add --all && git commit -m'
alias gst='git status -s'
alias gshow='echo "git show -U0"; git show -U0'
alias gshows='echo "git show --stat"; git show --stat'
alias gdiff='echo "git diff -U0"; git diff -U0'
alias gdiffs='echo "git diff --stat"; git diff --stat'
alias glog="git log --pretty=format:'%C(red)%h %C(yellow)%cn | %C(yellow)%cd (%cr) %C(reset)%C(white)%s' --date=format:'%a %Y/%m/%d %H:%M:%S'"

if [ -z "$ZELLIJ" ] && [ -z "$SSH_CONNECTION" ] && [[ $- == *i* ]] && command -v zellij >/dev/null; then
  	exec zellij
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

catEND

if [ -n "$ZSH_VERSION" ]; then
	source ~/.zshrc;
	echo "Please restart your terminal or log out and log back in to apply the changes."
else
	echo "Zsh configuration written to ~/.zshrc. Start a zsh session (exec zsh) or restart your terminal to apply the changes."
fi
