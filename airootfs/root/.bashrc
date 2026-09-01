# Colors
RESET='\[\e[0m\]'

CYAN='\[\e[38;2;180;190;254m\]'
PINK='\[\e[38;2;245;194;231m\]'
BLUE='\[\e[38;2;137;180;250m\]'

GREEN='\[\e[38;2;166;227;161m\]'
YELLOW='\[\e[38;2;249;226;175m\]'
RED='\[\e[38;2;243;139;168m\]'

# Git prompt
git_prompt() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return

    local branch marks ahead behind

    branch=$(git branch --show-current)

    git diff --quiet --ignore-submodules || marks+="● "
    git diff --cached --quiet --ignore-submodules || marks+="+ "
    [[ -n $(git ls-files --others --exclude-standard) ]] && marks+="? "

    ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo 0)
    behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)

    (( ahead > 0 )) && marks+="⇡$ahead "
    (( behind > 0 )) && marks+="⇣$behind "

    printf "  %s %s" "$branch" "$marks"
}

# Prompt
export PS1="\n${CYAN}\w ${BLUE}\$(git_prompt) ${RESET}\n${RED}❯ ${RESET}"
fetch
# ~/.bashrc
if [[ -d $HOME/winegames ]]; then
    source $HOME/winegames/env.sh
    alias game=$HOME/winegames/run-game
fi

if [[ -d $HOME/winest ]]; then
    source $HOME/winest/env.sh
    alias app=$HOME/winest/run-app
fi

APP=$HOME/.local/share/applications

export PATH="$HOME/sayarchi/scripts:$PATH"
export PATH="$HOME/sayarchi/bin:$PATH"
export PATH="$HOME/.dotfiles:$PATH"
export PATH="$HOME/Music:$PATH"

source $HOME/bashconf/bashcomp.sh
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

eval "$(fzf --bash)"

pb(){
    cd "$HOME/penboot"
    vim $(fzf)
}

ts2mp4() {
    local input="$1"
    local output="${2:-${input%.ts}.mp4}"

    ffmpeg -hide_banner -y \
        -fflags +genpts \
        -i "$input" \
        -map 0:v:0 -map 0:a? \
        -c:v copy \
        -c:a aac -b:a 192k \
        -movflags +faststart \
        "$output"
}

dk() {
    docker ps
    read -p "Kill: " h
    docker stop $h
    docker kill $h
}

replace-word() {
  find . -type d -name .git -prune -o -type f -exec sed -i "s/$1/$2/g" {} +
}

if command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1; then
    alias wgcc='x86_64-w64-mingw32-gcc'
fi

# File system
if command -v eza &> /dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
  alias l='lt -lh -T -L 2'
fi

if command -v noice &> /dev/null; then
    alias n="noice"
fi

alias ff="fzf --preview 'bat --style=numbers --color=always {}'"

if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash)"
    alias cd="zd"
zo(){
    local items
    items=("..")
    while IFS= read -r line; do
        items+=("$line")
    done < <(ls -1)
    local selected_item
    selected_item=$(printf '%s\n' "${items[@]}" | fzf --layout=reverse --header "$(pwd)" --height 90% --preview "eza --color=always {} -T")
    if [[ -n "$selected_item" ]]; then
        if [[ -d "$selected_item" ]]; then
            cd "$selected_item" || return
            zo  # recursively call zo
        else
            xdg-open "$selected_item" &>/dev/null &
        fi
    fi
}
zd() {
    if [ $# -eq 0 ]; then
        builtin cd ~ && return
    elif [ -d "$1" ]; then
        builtin cd "$1"
    else
        z "$@" && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
    fi
}
fi
clean_packages(){
    read -p "Wanna Clean Packages With config? [y/n]" $opt
    if [[ $opt == y || $opt = yes ]]; then
        sudo pacman -Rns $(pacman -Qdtq)
    else
        sudo pacman -Rs $(pacman -Qdtq)
    fi
    echo "Wanna Clean Caches?"
    read -r
    sudo pacman -Scc
}
open() {
    xdg-open "$@" >/dev/null 2>&1 &
}
alias cmus='cmus-init'

fs() {
    ls | grep "$@"
}

update() {
    notify-send "System Update!" "Started system Update"
    sudo pacman -Syyu
    notify-send "System Update!" "System Update Completed"
}

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias sx="rsxiv"
alias grep='grep --color=auto'
alias I="sudo pacman -S"
alias F="sudo pacman -q"
alias B="baph -in"
alias U="update"
alias S="sudo pacman -Sy"

PWD=$(pwd)
alias exp="nvim $PWD"
alias Exp="rdfm $PWD & disown"

alias ep="$EDITOR ~/.bashrc"
alias so="source $HOME/.bashrc"
alias cd="z"

alias i="sudo pacman -S"

alias v="nvim"
alias nano="nvim"
alias q="exit"
alias c="clear"
#alias gg="nvim -c Git"
alias gg="lazygit"

alias fst="fastfetch"
alias reset="rm ~/.cache/app_launcher_cache"
alias czf="fzf --layout=reverse --header "selector" --height 50%"

cx(){
    chmod +x $(fzf)
}

gitcl(){
    repo="$1"
    path="$2"
    if [[ $1 ]]; then
        if [[ $2 ]]; then
            git clone https://github.com/$repo $2
            cd $2
        else
            git clone https://github.com/$repo
        fi
    else
        repos=$(gh repo list --limit 100 --json name --jq '.[].name' | fzf)
        git clone https://github.com/HimadriChakra12/$repos
        cd $repo
    fi
}

gogit(){
    dir=$(ls ~/.git| fzf)
    cd ~/.git/$dir
    file=$(fzf)
    nvim $file
}
flac(){
    read -p "Name of the song: " filename
    read -p "Enter the URL: " url
    yt-dlp -f bestaudio --extract-audio --audio-format flac --audio-quality 0 -o "~/Music/${filename}.flac" "$url"
}

#git aliases
alias gs="git status --short"
#!/bin/bash


# Optionally, you can run it directly by calling:
# zo
# Add this to ~/.bashrc
reg(){
    url="$1"
    if [ -z "$url" ]; then
        echo "Usage: $0 <url>"
        exit 1
    fi

    # Escape regex special characters
    escaped=$(printf '%s' "$url" | sed -e 's/[.[\*^$()+?{|]/\\&/g' -e 's/\\/\\\\/g')

    # Output anchored regex
    echo "^${escaped}\$"
}
ez() {
    # Find common archive formats and list them in fzf
    archive=$(find . -maxdepth 1 -type f \
        \( -iname "*.zip" -o -iname "*.7z" -o -iname "*.rar" -o -iname "*.tar" -o -iname "*.tar.gz" -o -iname "*.tgz" \) \
        | fzf)

        # Exit if no file selected
        [ -z "$archive" ] && return

        # Make output directory named after archive (without extension)
        dir="${archive%.*}"
        mkdir -p "$dir"

        # Extract using 7z
        7z x "$archive" -o"$dir"
    }

mkcd(){
    location="$1"
    if [ -z "$location" ]; then
        echo "Usage: $0 <url>"
        exit 1
    fi
    mkdir $location && cd $location
    # Output anchored regex
    pwd
}

gcn() {
    name="$1"
    email="$2"
    git config --global user.name "$1"
    git config --global user.email "$2"
}
export PATH="$HOME/.local/bin:$PATH"

mountit() {
    if [ -z "$1" ]; then
        echo "Usage: mountit <iso-file> [mount-name]"
        return 1
    fi

    iso="$1"
    name="${2:-$(basename "$iso" .iso)}"
    dir="/mnt/$name"

    sudo mkdir -p "$dir" || return 1

    sudo mount -o loop,ro "$iso" "$dir" && \
    echo "Mounted $iso at $dir"
}
compress(){
    if [[ -z "$1" ]]; then
        echo "Usage: compress [folder] [ext]"
        return 1
    fi
    folder="$1"
    ext="${2#\.}"
    arc="$folder.$ext"
    if [[ "$ext" == "zip" ]]; then
        flags="-m0=deflate -mx=9"
        type_flag="-tzip"
    else
        flags="-m0=lzma2 -mx=9 -md=32m -mfb=64 -ms=on"
        type_flag="-t7z"
    fi
    echo "Compressing '$folder' to '$arc'..."
    7z a $type_flag $flags "$arc" "$folder"
}

# pkgback - Automatic package tracking
if [[ -f "$HOME/.local/bin/pkgback" ]]; then
    source "$HOME/.local/bin/pkgback"
fi

mp42mp3() {
    ffmpeg -i "$1" -vn -acodec libmp3lame -ab 192k "$2"
}

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
