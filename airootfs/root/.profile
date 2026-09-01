command -v fastfetch >/dev/null 2>&1 && fastfetch
export PATH="$HOME/sayarchi/scripts:$PATH"
export PATH="$HOME/sayarchi/bin:$PATH"
APP=$HOME/.local/share/applications
export PATH="$HOME/.dotfiles:$PATH"
export PATH="$HOME/Music:$PATH"

FIREFOX="$HOME/.mozilla/firefox/8qj1h3mj.default-release"
STICKER_DIR1="$HOME/stickers-hspe/"
STICKER_DIR2="$HOME/stickers"

alias gg="nvim -c Git"
#alias gg="lazygit"

if [[ -d "$STICKER_DIR1" ]]; then
    st="$STICKER_DIR1"
elif [[ -d "$STICKER_DIR2" ]]; then
    st="$STICKER_DIR2"
else
    echo "❌ No sticker directory found"
    exit 1
fi

stpush() {
    cd $STICKER_DIR1 && bash git.sh
    cd $STICKER_DIR2 && bash git.sh
}
if [[ -f $HOME/wprfrc ]]; then
    source $HOME/wprfrc
else
    alias game="$HOME/.winegame/run-game"
    alias photo="$HOME/wine_profiles/photoshop/run-photoshop"
fi
mountit() {
    name="$1"
    mount="$2"
    sudo mkdir -p "/mnt/$2"
    sudo mount -o loop,ro "$1" "/mnt/$2"
}
reg() {
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
mkcd() {
    location="$1"
    if [ -z "$location" ]; then
        echo "Usage: $0 <url>"
        exit 1
    fi
    mkdir $location && cd $location
    # Output anchored regex
    pwd
}
replace-word() {
    find . -type d -name .git -prune -o -type f -exec sed -i "s/$1/$2/g" {} +
}
alias cmus='cmus-init'
alias i3dx='$HOME/sayarchi/bin/dx'

fs() {
    ls | grep "$@"
}
gcn() {
    name="$1"
    email="$2"
    git config --global user.name "$1"
    git config --global user.email "$2"
}
export PATH="$HOME/.local/bin:$PATH"
gitcl() {
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
get-age() {
    birth_install=$(stat -c %W /)
    current=$(date +%s)
    time_progression=$((current - birth_install))
    days_difference=$((time_progression / 86400))
    echo Only $days_difference days!
}
