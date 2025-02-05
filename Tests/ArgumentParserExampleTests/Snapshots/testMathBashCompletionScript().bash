#!/bin/bash

_math() {
    export SAP_SHELL=bash
    SAP_SHELL_VERSION="$(IFS='.'; printf %s "${BASH_VERSINFO[*]}")"
    export SAP_SHELL_VERSION
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    COMPREPLY=()
    opts="--version -h --help add multiply stats help"
    if [[ $COMP_CWORD == "1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    case ${COMP_WORDS[1]} in
        (add)
            _math_add 2
            return
            ;;
        (multiply)
            _math_multiply 2
            return
            ;;
        (stats)
            _math_stats 2
            return
            ;;
        (help)
            _math_help 2
            return
            ;;
    esac
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
_math_add() {
    opts="--hex-output -x --version -h --help"
    if [[ $COMP_CWORD == "$1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
_math_multiply() {
    opts="--hex-output -x --version -h --help"
    if [[ $COMP_CWORD == "$1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
_math_stats() {
    opts="--version -h --help average stdev quantiles"
    if [[ $COMP_CWORD == "$1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    case ${COMP_WORDS[$1]} in
        (average)
            _math_stats_average $(($1+1))
            return
            ;;
        (stdev)
            _math_stats_stdev $(($1+1))
            return
            ;;
        (quantiles)
            _math_stats_quantiles $(($1+1))
            return
            ;;
    esac
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
_math_stats_average() {
    opts="--kind --version -h --help"
    if [[ $COMP_CWORD == "$1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    case $prev in
        --kind)
            COMPREPLY=( $(compgen -W "mean median mode" -- "$cur") )
            return
        ;;
    esac
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
_math_stats_stdev() {
    opts="--version -h --help"
    if [[ $COMP_CWORD == "$1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
_math_stats_quantiles() {
    opts="--file --directory --shell --custom --version -h --help"
    opts="$opts alphabet alligator branch braggart"
    opts="$opts $("${COMP_WORDS[0]}" ---completion stats quantiles -- positional@1 "${COMP_WORDS[@]}")"
    if [[ $COMP_CWORD == "$1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    case $prev in
        --file)
            if declare -F _filedir >/dev/null; then
              _filedir 'txt'
              _filedir 'md'
              _filedir 'TXT'
              _filedir 'MD'
              _filedir -d
            else
              COMPREPLY=(
                $(compgen -f -X '!*.txt' -- "$cur")
                $(compgen -f -X '!*.md' -- "$cur")
                $(compgen -f -X '!*.TXT' -- "$cur")
                $(compgen -f -X '!*.MD' -- "$cur")
                $(compgen -d -- "$cur")
              )
            fi
            return
        ;;
        --directory)
            if declare -F _filedir >/dev/null; then
              _filedir -d
            else
              COMPREPLY=( $(compgen -d -- "$cur") )
            fi
            return
        ;;
        --shell)
            COMPREPLY=( $(head -100 /usr/share/dict/words | tail -50) )
            return
        ;;
        --custom)
            COMPREPLY=( $(compgen -W "$("${COMP_WORDS[0]}" ---completion stats quantiles -- --custom "${COMP_WORDS[@]}")" -- "$cur") )
            return
        ;;
    esac
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
_math_help() {
    opts=""
    if [[ $COMP_CWORD == "$1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}


complete -F _math math
