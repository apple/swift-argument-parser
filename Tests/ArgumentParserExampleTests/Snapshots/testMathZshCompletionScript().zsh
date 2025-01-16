#compdef math
local context state state_descr line
_math_commandname="${words[1]}"
typeset -A opt_args

_math() {
    export SAP_SHELL=zsh
    SAP_SHELL_VERSION="$(builtin emulate zsh -c 'printf %s "${ZSH_VERSION}"')"
    export SAP_SHELL_VERSION
    integer ret=1
    local -a args
    args+=(
        '--version[Show the version.]'
        '(-h --help)'{-h,--help}'[Show help information.]'
        '(-): :->command'
        '(-)*:: :->arg'
    )
    _arguments -w -s -S "${args[@]}" && ret=0
    case "${state}" in
    command)
        local subcommands
        subcommands=(
            'add:Print the sum of the values.'
            'multiply:Print the product of the values.'
            'stats:Calculate descriptive statistics.'
            'help:Show subcommand help information.'
        )
        _describe "subcommand" subcommands
        ;;
    arg)
        case "${words[1]}" in
        add)
            _math_add
            ;;
        multiply)
            _math_multiply
            ;;
        stats)
            _math_stats
            ;;
        help)
            _math_help
            ;;
        esac
        ;;
    esac

    return "${ret}"
}

_math_add() {
    integer ret=1
    local -a args
    args+=(
        '(--hex-output -x)'{--hex-output,-x}'[Use hexadecimal notation for the result.]'
        ':values:'
        '--version[Show the version.]'
        '(-h --help)'{-h,--help}'[Show help information.]'
    )
    _arguments -w -s -S "${args[@]}" && ret=0

    return "${ret}"
}

_math_multiply() {
    integer ret=1
    local -a args
    args+=(
        '(--hex-output -x)'{--hex-output,-x}'[Use hexadecimal notation for the result.]'
        ':values:'
        '--version[Show the version.]'
        '(-h --help)'{-h,--help}'[Show help information.]'
    )
    _arguments -w -s -S "${args[@]}" && ret=0

    return "${ret}"
}

_math_stats() {
    integer ret=1
    local -a args
    args+=(
        '--version[Show the version.]'
        '(-h --help)'{-h,--help}'[Show help information.]'
        '(-): :->command'
        '(-)*:: :->arg'
    )
    _arguments -w -s -S "${args[@]}" && ret=0
    case "${state}" in
    command)
        local subcommands
        subcommands=(
            'average:Print the average of the values.'
            'stdev:Print the standard deviation of the values.'
            'quantiles:Print the quantiles of the values (TBD).'
        )
        _describe "subcommand" subcommands
        ;;
    arg)
        case "${words[1]}" in
        average)
            _math_stats_average
            ;;
        stdev)
            _math_stats_stdev
            ;;
        quantiles)
            _math_stats_quantiles
            ;;
        esac
        ;;
    esac

    return "${ret}"
}

_math_stats_average() {
    integer ret=1
    local -a args
    args+=(
        '--kind[The kind of average to provide.]:kind:(mean median mode)'
        ':values:'
        '--version[Show the version.]'
        '(-h --help)'{-h,--help}'[Show help information.]'
    )
    _arguments -w -s -S "${args[@]}" && ret=0

    return "${ret}"
}

_math_stats_stdev() {
    integer ret=1
    local -a args
    args+=(
        ':values:'
        '--version[Show the version.]'
        '(-h --help)'{-h,--help}'[Show help information.]'
    )
    _arguments -w -s -S "${args[@]}" && ret=0

    return "${ret}"
}

_math_stats_quantiles() {
    integer ret=1
    local -a args
    args+=(
        ':one-of-four:(alphabet alligator branch braggart)'
        ':custom-arg:{_custom_completion "${_math_commandname}" ---completion stats quantiles -- customArg "${words[@]}"}'
        ':values:'
        '--file:file:_files -g '"'"'*.txt *.md'"'"''
        '--directory:directory:_files -/'
        '--shell:shell:{local -a list;list=(${(f)"$(head -100 /usr/share/dict/words | tail -50)"});_describe "" list}'
        '--custom:custom:{_custom_completion "${_math_commandname}" ---completion stats quantiles -- --custom "${words[@]}"}'
        '--version[Show the version.]'
        '(-h --help)'{-h,--help}'[Show help information.]'
    )
    _arguments -w -s -S "${args[@]}" && ret=0

    return "${ret}"
}

_math_help() {
    integer ret=1
    local -a args
    args+=(
        ':subcommands:'
        '--version[Show the version.]'
    )
    _arguments -w -s -S "${args[@]}" && ret=0

    return "${ret}"
}


_custom_completion() {
    local completions=("${(@f)$($*)}")
    _describe '' completions
}

_math
