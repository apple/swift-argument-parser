# A function which filters options which starts with "-" from $argv.
function _swift_math_commands_and_positionals
    set -l results
    for i in (seq (count $argv))
        switch (echo $argv[$i] | string sub -l 1)
            case '-'
            case '*'
                echo $argv[$i]
        end
    end
end

function _swift_math_using_command
    set -gx SAP_SHELL fish
    set -gx SAP_SHELL_VERSION "$FISH_VERSION"
    set -l commands_and_positionals (_swift_math_commands_and_positionals (commandline -opc))
    set -l expected_commands (string split -- ' ' $argv[1])
    set -l subcommands (string split -- ' ' $argv[2])
    if [ (count $commands_and_positionals) -ge (count $expected_commands) ]
        for i in (seq (count $expected_commands))
            if [ $commands_and_positionals[$i] != $expected_commands[$i] ]
                return 1
            end
        end
        if [ (count $commands_and_positionals) -eq (count $expected_commands) ]
            return 0
        end
        if [ (count $subcommands) -gt 1 ]
            for i in (seq (count $subcommands))
                if [ $commands_and_positionals[(math (count $expected_commands) + 1)] = $subcommands[$i] ]
                    return 1
                end
            end
        end
        return 0
    end
    return 1
end

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
complete -c math -n '_swift_math_using_command "math stats quantiles"' -rfka 'alphabet alligator branch braggart'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -rfa '(command math ---completion stats quantiles -- customArg (commandline -opc)[1..-1])'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -l file -rfa '(for i in *.{txt,md}; echo $i;end)'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -l directory -rfa '(__fish_complete_directories)'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -l shell -rfa '(head -100 /usr/share/dict/words | tail -50)'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -l custom -rfa '(command math ---completion stats quantiles -- --custom (commandline -opc)[1..-1])'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -l version -d 'Show the version.'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -s h -l help -d 'Show help information.'
complete -c math -n '_swift_math_using_command "math stats" "average stdev quantiles"' -l version -d 'Show the version.'
complete -c math -n '_swift_math_using_command "math stats" "average stdev quantiles"' -s h -l help -d 'Show help information.'
complete -c math -n '_swift_math_using_command "math stats" "average stdev quantiles"' -fa 'average' -d 'Print the average of the values.'
complete -c math -n '_swift_math_using_command "math stats" "average stdev quantiles"' -fa 'stdev' -d 'Print the standard deviation of the values.'
complete -c math -n '_swift_math_using_command "math stats" "average stdev quantiles"' -fa 'quantiles' -d 'Print the quantiles of the values (TBD).'
complete -c math -n '_swift_math_using_command "math help"' -l version -d 'Show the version.'
complete -c math -n '_swift_math_using_command "math" "add multiply stats help"' -l version -d 'Show the version.'
complete -c math -n '_swift_math_using_command "math" "add multiply stats help"' -s h -l help -d 'Show help information.'
complete -c math -n '_swift_math_using_command "math" "add multiply stats help"' -fa 'add' -d 'Print the sum of the values.'
complete -c math -n '_swift_math_using_command "math" "add multiply stats help"' -fa 'multiply' -d 'Print the product of the values.'
complete -c math -n '_swift_math_using_command "math" "add multiply stats help"' -fa 'stats' -d 'Calculate descriptive statistics.'
complete -c math -n '_swift_math_using_command "math" "add multiply stats help"' -fa 'help' -d 'Show subcommand help information.'
