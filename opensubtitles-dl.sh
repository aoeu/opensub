#!/usr/bin/env bash
#
# Download subtitles from opensubtitles.org
#
#/ Usage:
#/   ./opensubtitles-dl.sh [-n <name>] [-l <lang>] [-d]
#/
#/ Options:
#/   -n <name>               TV series or Movie name
#/   -l <lang>               optional, language
#/                           e.g.: eng, spa, fre...
#/                           default: eng
#/   -a                      optional, download all available subtitles
#/   -d                      enable debug mode
#/   -h | --help             display this help message

set -e
set -u

usage() {
    printf "%b\n" "$(grep '^#/' "$0" | cut -c4-)" && exit 1
}

set_vars() {
    _CURL="$(command -v curl)" || command_not_found "curl"
    _PUP="$(command -v pup)" || command_not_found "pup"
    _FZF="$(command -v fzf)" || command_not_found "fzf"
    _UNZIP="$(command -v unzip)" || command_not_found "unzip"

    _SEARCH_URL="https://www.opensubtitles.org/en/search/sublanguageid-"
    _DOWNLOAD_URL="https://dl.opensubtitles.org/en/download/sub/"
}

set_args() {
    expr "$*" : ".*--help" > /dev/null && usage
    while getopts ":hdal:n:" opt; do
        case $opt in
            n)
                _INPUT_NAME="$OPTARG"
                ;;
            l)
                _LANG="$OPTARG"
                ;;
            a)
                _DOWNLOAD_ALL=true
                ;;
            d)
                set -x
                ;;
            h)
                usage
                ;;
            \?)
                print_error "Invalid option: -$OPTARG"
                ;;
        esac
    done
}

print_error() {
    # $1: error message
    printf "%b\n" "\033[31m[ERROR]\033[0m $1" >&2
    exit 1
}

command_not_found() {
    # $1: command name
    print_error "$1 command not found!"
}

get_subtitle_list () {
    # $1: id
    local d ul nl len n l
    d="$("$_CURL" -sSL "${_SEARCH_URL}${_LANG:-eng}/imdbid-${1}")"
    ul="$("$_PUP" '.bnone attr{href}' <<< "$d" \
        | sed -E 's/.*\/subtitles\///' \
        | awk -F '/' '{print $1}')"
    if [[ -z "${ul:-}" ]]; then
        "$_PUP" 'link attr{href}' <<< "$d" \
            | grep -E '^/en/subtitles/' \
            | sed -E 's/.*\/subtitles\///' \
            | awk -F '/' '{print $1}'
    else
        nl="$("$_PUP" ':parent-of(strong)' <<< "$d" \
            | sed -n "/<br>/,/<br>/p" \
            | sed -E 's/<br>.*//' \
            | sed -E '/<span /d;/<\/span>/d' \
            | awk '{$1=$1};1' \
            | awk '{if (NF!=0) {prev=$0;getline;print prev,$0}}')"
        len="$(wc -l <<< "$nl")"
        for i in $(seq 1 "$len"); do
            u="$(head -"$i" <<< "$ul" | tail -1)"
            n="$(head -"$i" <<< "$nl" | tail -1)"
            echo "[$u] $n"
        done
    fi
}

get_imdb_id() {
    # $1: media name
    local resp url id
    resp="$("$_CURL" -sSL -A 'google' "https://html.duckduckgo.com/html/?q=${1// /+}+site%3Aimdb.com%2Ftitle")"
    url="$("$_PUP" 'div.result:nth-child(1) > div:nth-child(1) > div:nth-child(2) > div:nth-child(1) > a:nth-child(2) text{}' <<< "$resp")"
    id="$(echo "$url" | sed -z 's/\n//g; s/ //g; s#^.*title/\([a-z0-9]*\)/$#\1#')"
    echo "$id"
}

download_subtitle() {
    # $1: subtitle id
    while read -r id; do
        "$_CURL" "$_DOWNLOAD_URL{$id}" -o "./${id}.zip"
        "$_UNZIP" -o "${id}.zip" -x "*.nfo"
        rm -f "${id}.zip"
    done <<< "$1"
}

fzf_prompt() {
    # $1: input
    echo -n "$1" \
        | "$_FZF" -1 -0 \
        | awk -F']' '{print $1}' \
        | sed -E 's/^\[//'
}

main() {
    set_args "$@"
    set_vars

    [[ -z "${_INPUT_NAME:-}" ]] && print_error "Missing -n <name>!"

    mid="$(get_imdb_id "${_INPUT_NAME:-}")"

    [[ -z "${mid:-}" ]] && print_error "IMDb ID not found!"
    [[ "${mid:-}" =~ tt[0-9]{7,} ]] || print_error "expected an IMDb ID value like 'tt0113243' but received '$mid'"

    slist="$(get_subtitle_list "$mid")"
    if [[ -z "${_DOWNLOAD_ALL:-}" ]]; then
        sid="$(fzf_prompt "$slist")"
    else
        sid="$(awk -F ']' '{print $1}' <<< "$slist" | awk -F '[' '{print $2}')"
    fi

    [[ -z "${sid:-}" ]] && print_error "Subtitle not found!"
    download_subtitle "$sid"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
