#!/bin/bash

_base_test() {
    export SAP_SHELL=bash
    SAP_SHELL_VERSION="$(IFS='.'; printf %s "${BASH_VERSINFO[*]}")"
    export SAP_SHELL_VERSION
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    COMPREPLY=()
    opts="--name --kind --other-kind --path1 --path2 --path3 --one --two --three --kind-counter --rep1 -r --rep2 -h --help sub-command help"
    opts="$opts $("${COMP_WORDS[0]}" ---completion  -- argument "${COMP_WORDS[@]}")"
    opts="$opts $("${COMP_WORDS[0]}" ---completion  -- nested.nestedArgument "${COMP_WORDS[@]}")"
    if [[ $COMP_CWORD == "1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    case $prev in
        --name)

            return
        ;;
        --kind)
            COMPREPLY=( $(compgen -W "one two custom-three" -- "$cur") )
            return
        ;;
        --other-kind)
            COMPREPLY=( $(compgen -W "1 2 3" -- "$cur") )
            return
        ;;
        --path1)
            if declare -F _filedir >/dev/null; then
              _filedir
            else
              COMPREPLY=( $(compgen -f -- "$cur") )
            fi
            return
        ;;
        --path2)
            if declare -F _filedir >/dev/null; then
              _filedir
            else
              COMPREPLY=( $(compgen -f -- "$cur") )
            fi
            return
        ;;
        --path3)
            COMPREPLY=( $(compgen -W "a b c" -- "$cur") )
            return
        ;;
        --rep1)

            return
        ;;
        -r|--rep2)

            return
        ;;
    esac
    case ${COMP_WORDS[1]} in
        (sub-command)
            _base_test_sub-command 2
            return
            ;;
        (help)
            _base_test_help 2
            return
            ;;
    esac
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
_base_test_sub_command() {
    opts="-h --help"
    if [[ $COMP_CWORD == "$1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
_base_test_help() {
    opts=""
    if [[ $COMP_CWORD == "$1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}


complete -F _base_test base-test
