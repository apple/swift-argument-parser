function _swift_math_commands_and_positionals -S
    switch $positionals[1]
    case 'math'
        _swift_math_commands_and_positionals_helper '-s' 'version h/help'
        switch $positionals[1]
        case 'add'
            _swift_math_commands_and_positionals_helper '' 'x/hex-output version h/help'
        case 'multiply'
            _swift_math_commands_and_positionals_helper '' 'x/hex-output version h/help'
        case 'stats'
            _swift_math_commands_and_positionals_helper '-s' 'version h/help'
            switch $positionals[1]
            case 'average'
                _swift_math_commands_and_positionals_helper '' 'kind= version h/help'
            case 'stdev'
                _swift_math_commands_and_positionals_helper '' 'version h/help'
            case 'quantiles'
                _swift_math_commands_and_positionals_helper '' 'file= directory= shell= custom= version h/help'
            end
        case 'help'
            _swift_math_commands_and_positionals_helper '' 'version'
        end
    case '*'
        set commands $positionals[1]
        set -e positionals[1]
    end
end

function _swift_math_commands_and_positionals_helper -S -a argparse_options -a option_specs
    set -a commands $positionals[1]
    set -e positionals[1]
    if test -z $argparse_options
        argparse -n (string join -- ' ' $commands) (string split -- ' ' $option_specs) -- $positionals 2> /dev/null
        set positionals $argv
    else
        argparse (string split -- ' ' $argparse_options) -n (string join -- ' ' $commands) (string split -- ' ' $option_specs) -- $positionals 2> /dev/null
        set positionals $argv
    end
end

function _swift_math_tokens
    if test (string split -m 1 -f 1 . $FISH_VERSION) -gt 3
        commandline --tokens-raw $argv
    else
        commandline -o $argv
    end
end

function _swift_math_using_command -a expected_commands
    set commands
    set positionals (_swift_math_tokens -pc)
    _swift_math_commands_and_positionals
    test "$commands" = $expected_commands
end

function _swift_math_positional_index
    set positionals (_swift_math_tokens -pc)
    _swift_math_commands_and_positionals
    math (count $positionals) + 1
end

function _swift_math_complete_directories
    set token (commandline -t)
    string match -- '*/' $token
    set subdirs $token*/
    printf '%s\n' $subdirs
end

function _swift_math_custom_completion
    set -x SAP_SHELL fish
    set -x SAP_SHELL_VERSION $FISH_VERSION

    set tokens (_swift_math_tokens -p)
    if test -z (_swift_math_tokens -t)
        set index (count (_swift_math_tokens -pc))
        set tokens $tokens[..$index] \'\' $tokens[$(math $index + 1)..]
    end
    command $tokens[1] $argv $tokens
end

complete -c math -f
complete -c math -n '_swift_math_using_command "math add"' -l hex-output -s x -d 'Use hexadecimal notation for the result.'
complete -c math -n '_swift_math_using_command "math add"' -l version -d 'Show the version.'
complete -c math -n '_swift_math_using_command "math add"' -s h -l help -d 'Show help information.'
complete -c math -n '_swift_math_using_command "math multiply"' -l hex-output -s x -d 'Use hexadecimal notation for the result.'
complete -c math -n '_swift_math_using_command "math multiply"' -l version -d 'Show the version.'
complete -c math -n '_swift_math_using_command "math multiply"' -s h -l help -d 'Show help information.'
complete -c math -n '_swift_math_using_command "math stats average"' -l kind -d 'The kind of average to provide.' -rfka 'mean median mode'
complete -c math -n '_swift_math_using_command "math stats average"' -l version -d 'Show the version.'
complete -c math -n '_swift_math_using_command "math stats average"' -s h -l help -d 'Show help information.'
complete -c math -n '_swift_math_using_command "math stats stdev"' -l version -d 'Show the version.'
complete -c math -n '_swift_math_using_command "math stats stdev"' -s h -l help -d 'Show help information.'
complete -c math -n '_swift_math_using_command "math stats quantiles";and test (_swift_math_positional_index) -eq 1' -rfka 'alphabet alligator branch braggart'
complete -c math -n '_swift_math_using_command "math stats quantiles";and test (_swift_math_positional_index) -eq 2' -rfka '(_swift_math_custom_completion ---completion stats quantiles -- customArg)'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -l file -rfa '(set exts \'txt\' \'md\';for p in (string match -e -- \'*/\' (commandline -t);or printf \n)*.{$exts};printf %s\n $p;end;__fish_complete_directories (commandline -t) \'\')'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -l directory -rfa '(_swift_math_complete_directories)'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -l shell -rfka '(head -100 /usr/share/dict/words | tail -50)'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -l custom -rfka '(_swift_math_custom_completion ---completion stats quantiles -- --custom)'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -l version -d 'Show the version.'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -s h -l help -d 'Show help information.'
complete -c math -n '_swift_math_using_command "math stats"' -l version -d 'Show the version.'
complete -c math -n '_swift_math_using_command "math stats"' -s h -l help -d 'Show help information.'
complete -c math -n '_swift_math_using_command "math stats"' -fa 'average' -d 'Print the average of the values.'
complete -c math -n '_swift_math_using_command "math stats"' -fa 'stdev' -d 'Print the standard deviation of the values.'
complete -c math -n '_swift_math_using_command "math stats"' -fa 'quantiles' -d 'Print the quantiles of the values (TBD).'
complete -c math -n '_swift_math_using_command "math help"' -l version -d 'Show the version.'
complete -c math -n '_swift_math_using_command "math"' -l version -d 'Show the version.'
complete -c math -n '_swift_math_using_command "math"' -s h -l help -d 'Show help information.'
complete -c math -n '_swift_math_using_command "math"' -fa 'add' -d 'Print the sum of the values.'
complete -c math -n '_swift_math_using_command "math"' -fa 'multiply' -d 'Print the product of the values.'
complete -c math -n '_swift_math_using_command "math"' -fa 'stats' -d 'Calculate descriptive statistics.'
complete -c math -n '_swift_math_using_command "math"' -fa 'help' -d 'Show subcommand help information.'
