#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  Bash autocomplete enhancements
#  1. Up/Down arrow  →  history search filtered by current input
#  2. Tab            →  fzf picker when multiple candidates exist
#  3. cd + Tab       →  fzf directory picker (zoxide-aware)
#  4. sxiv/sxbv/mpv/nvim + Tab → fzf picker filtered to their file types
#
#  Requirements: fzf, zoxide
#  Source from ~/.bashrc:
#    source /path/to/bash_autocomplete.sh
# ─────────────────────────────────────────────────────────────


# ── 1. UP / DOWN ARROW  →  prefix-filtered history ───────────
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"


# ── Binary → file extensions it handles ──────────────────────
#  Used by Tab completion to filter only relevant files per command.
declare -A _CMD_EXTS=(
    [sxiv]="jpg jpeg png gif bmp tiff tif webp svg ico ppm pgm pbm xpm heic avif"
    [sxbv]="pdf djvu cbz cbr epub xps"
    [mpv]="mp4 mkv avi mov webm flv wmv m4v ts m2ts vob 3gp mp3 flac ogg wav aac m4a opus wma"
    [nvim]="txt md rst log conf ini toml yaml yml json xml sh py js ts c h cpp go rs lua vim css html"
    [libreoffice]="docx doc odt xlsx xls ods pptx ppt odp csv"
)

# Build a find -name pattern like: -name '*.jpg' -o -name '*.png' ...
_exts_to_find_pattern() {
    local exts="$1"
    local first=1
    local pat=""
    for ext in $exts; do
        if [[ $first -eq 1 ]]; then
            pat="-name '*.${ext}'"
            first=0
        else
            pat+=" -o -name '*.${ext}'"
        fi
    done
    echo "$pat"
}

# ── fzf helper — shared options ───────────────────────────────
_fzf_pick() {
    local prompt="$1"
    local query="$2"
    # reads candidates from stdin
    fzf \
        --height=50% \
        --layout=reverse \
        --border=rounded \
        --prompt=" ${prompt} ❯ " \
        --info=inline \
        --bind "tab:down,shift-tab:up" \
        --query="$query" \
        --select-1 \
        --exit-0 \
        2>/dev/tty
}

# ── Main Tab handler ──────────────────────────────────────────
_fzf_tab_complete() {
    local cur="${READLINE_LINE}"
    local point="${READLINE_POINT}"

    local before="${cur:0:$point}"
    local word="${before##* }"
    local prefix="${before:0:$((point - ${#word}))}"
    local after="${cur:$point}"

    # Grab the first token (the command being run)
    local cmd
    cmd=$(echo "$cur" | awk '{print $1}')

    # ── cd → local dirs first, zoxide only if no local match ────
    if [[ "$cmd" == "cd" ]]; then
        # Determine base dir and prefix to filter on
        local search_base search_prefix
        if [[ "$word" == */* ]]; then
            search_base="${word%/*}/"
            search_prefix="${word##*/}"
        else
            search_base="./"
            search_prefix="$word"
        fi

        # Find local subdirs matching typed prefix (case-insensitive)
        local local_dirs
        local_dirs=$(
            find "$search_base" -maxdepth 1 -mindepth 1 -type d 2>/dev/null \
            | sed 's|^\./||' \
            | grep -i "^${search_prefix}" \
            | sort
        )

        local count=0
        [[ -n "$local_dirs" ]] && count=$(echo "$local_dirs" | grep -c .)

        local chosen
        if [[ $count -eq 1 ]]; then
            # Only one local match — complete immediately, no fzf
            chosen="$local_dirs"
            chosen="${chosen%/}/"
            READLINE_LINE="${prefix}${chosen}${after}"
            READLINE_POINT=$(( ${#prefix} + ${#chosen} ))

        elif [[ $count -gt 1 ]]; then
            # Multiple local matches — fzf over just those
            chosen=$(echo "$local_dirs" | _fzf_pick "📁 cd" "$search_prefix")
            if [[ -n "$chosen" ]]; then
                chosen="${chosen%/}/"
                READLINE_LINE="${prefix}${chosen}${after}"
                READLINE_POINT=$(( ${#prefix} + ${#chosen} ))
            fi

        else
            # No local match — fall back to zoxide frecency list
            chosen=$(
                zoxide query -l 2>/dev/null \
                | grep -i "$word" \
                | _fzf_pick "📁 z" "$word"
            )
            if [[ -n "$chosen" ]]; then
                chosen="${chosen%/}/"
                READLINE_LINE="${prefix}${chosen}${after}"
                READLINE_POINT=$(( ${#prefix} + ${#chosen} ))
            fi
        fi
        return
    fi

    # ── known binaries → filter files by their extensions ─────
    if [[ -n "${_CMD_EXTS[$cmd]}" ]]; then
        local exts="${_CMD_EXTS[$cmd]}"
        local search_dir="${word:-.}"

        # Build find command dynamically from extension list
        local find_args=("find" "$search_dir" "-maxdepth" "4" "(")
        local first=1
        for ext in $exts; do
            if [[ $first -eq 1 ]]; then
                find_args+=("-iname" "*.${ext}")
                first=0
            else
                find_args+=("-o" "-iname" "*.${ext}")
            fi
        done
        find_args+=(")")

        local chosen
        chosen=$(
            "${find_args[@]}" 2>/dev/null \
            | sed 's|^\./||' \
            | sort \
            | _fzf_pick "$cmd" "$word"
        )

        if [[ -n "$chosen" ]]; then
            # Quote the filename if it contains spaces
            if [[ "$chosen" == *" "* ]]; then
                chosen="'${chosen}'"
            fi
            chosen="${chosen} "
            READLINE_LINE="${prefix}${chosen}${after}"
            READLINE_POINT=$(( ${#prefix} + ${#chosen} ))
        fi
        return
    fi

    # ── general completion ────────────────────────────────────
    local candidates
    if [[ -z "$prefix" || "$prefix" =~ ^[[:space:]]+$ ]]; then
        candidates=$(compgen -A function -A alias -A builtin -A command -- "$word" 2>/dev/null | sort -u)
    else
        candidates=$(compgen -f -- "$word" 2>/dev/null | sort -u)
    fi

    # Count lines safely
    local lines=0
    [[ -n "$candidates" ]] && lines=$(echo "$candidates" | grep -c .)

    if [[ $lines -eq 0 ]]; then
        echo -en "\a"
        return
    elif [[ $lines -eq 1 ]]; then
        local match="$candidates"
        [[ -d "$match" ]] && match="${match%/}/" || match="${match} "
        READLINE_LINE="${prefix}${match}${after}"
        READLINE_POINT=$(( ${#prefix} + ${#match} ))
    else
        local chosen
        chosen=$(echo "$candidates" | _fzf_pick "❯" "$word")

        if [[ -n "$chosen" ]]; then
            if [[ "$chosen" == *" "* ]]; then
                chosen="'${chosen}'"
            fi
            [[ -d "$chosen" ]] && chosen="${chosen%/}/" || chosen="${chosen} "
            READLINE_LINE="${prefix}${chosen}${after}"
            READLINE_POINT=$(( ${#prefix} + ${#chosen} ))
        fi
    fi
}

bind -x '"\t": _fzf_tab_complete'
