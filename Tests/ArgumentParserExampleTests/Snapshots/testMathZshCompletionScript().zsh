#compdef math

_math() {
    local -xr SAP_SHELL=zsh
    local -x SAP_SHELL_VERSION
    SAP_SHELL_VERSION="$(builtin emulate zsh -c 'printf %s "${ZSH_VERSION}"')"
    local -r SAP_SHELL_VERSION

    local context state state_descr line
    local -A opt_args

    local -r command_name="${words[1]}"
    local -ar command_line=("${words[@]}")

    local -i ret=1
    local -ar args=(
        '--version[Show the version.]'
        '(-h --help)'{-h,--help}'[Show help information.]'
        '(-): :->command'
        '(-)*:: :->arg'
    )
    _arguments -w -s -S "${args[@]}" && ret=0
    case "${state}" in
    command)
        local -ar subcommands=(
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
    local -i ret=1
    local -ar args=(
        '(--hex-output -x)'{--hex-output,-x}'[Use hexadecimal notation for the result.]'
        ':values:'
        '--version[Show the version.]'
        '(-h --help)'{-h,--help}'[Show help information.]'
    )
    _arguments -w -s -S "${args[@]}" && ret=0

    return "${ret}"
}

_math_multiply() {
    local -i ret=1
    local -ar args=(
        '(--hex-output -x)'{--hex-output,-x}'[Use hexadecimal notation for the result.]'
        ':values:'
        '--version[Show the version.]'
        '(-h --help)'{-h,--help}'[Show help information.]'
    )
    _arguments -w -s -S "${args[@]}" && ret=0

    return "${ret}"
}

_math_stats() {
    local -i ret=1
    local -ar args=(
        '--version[Show the version.]'
        '(-h --help)'{-h,--help}'[Show help information.]'
        '(-): :->command'
        '(-)*:: :->arg'
    )
    _arguments -w -s -S "${args[@]}" && ret=0
    case "${state}" in
    command)
        local -ar subcommands=(
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
    local -i ret=1
    local -ar args=(
        '--kind[The kind of average to provide.]:kind:(mean median mode)'
        ':values:'
        '--version[Show the version.]'
        '(-h --help)'{-h,--help}'[Show help information.]'
    )
    _arguments -w -s -S "${args[@]}" && ret=0

    return "${ret}"
}

_math_stats_stdev() {
    local -i ret=1
    local -ar args=(
        ':values:'
        '--version[Show the version.]'
        '(-h --help)'{-h,--help}'[Show help information.]'
    )
    _arguments -w -s -S "${args[@]}" && ret=0

    return "${ret}"
}

_math_stats_quantiles() {
    local -i ret=1
    local -ar args=(
        ':one-of-four:(alphabet alligator branch braggart)'
        ':custom-arg:{_custom_completion "${command_name}" ---completion stats quantiles -- customArg "${command_line[@]}"}'
        ':values:'
        '--file:file:_files -g '"'"'*.txt *.md'"'"''
        '--directory:directory:_files -/'
        '--shell:shell:{local -a list;list=(${(f)"$(head -100 /usr/share/dict/words | tail -50)"});_describe "" list}'
        '--custom:custom:{_custom_completion "${command_name}" ---completion stats quantiles -- --custom "${command_line[@]}"}'
        '--version[Show the version.]'
        '(-h --help)'{-h,--help}'[Show help information.]'
    )
    _arguments -w -s -S "${args[@]}" && ret=0

    return "${ret}"
}

_math_help() {
    local -i ret=1
    local -ar args=(
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
