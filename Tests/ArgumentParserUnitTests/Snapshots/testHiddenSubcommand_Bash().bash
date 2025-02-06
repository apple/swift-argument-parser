#!/bin/bash

_parent() {
    export SAP_SHELL=bash
    SAP_SHELL_VERSION="$(IFS='.'; printf %s "${BASH_VERSINFO[*]}")"
    export SAP_SHELL_VERSION
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    COMPREPLY=()
    opts="-h --help"
    if [[ $COMP_CWORD == "1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}


complete -F _parent parent
