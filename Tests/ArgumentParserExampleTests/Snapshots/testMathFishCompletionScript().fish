# A function which filters options which starts with "-" from $argv.
function _swift_math_preprocessor
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
    set -l currentCommands (_swift_math_preprocessor (commandline -opc))
    set -l expectedCommands (string split " " $argv[1])
    set -l subcommands (string split " " $argv[2])
    if [ (count $currentCommands) -ge (count $expectedCommands) ]
        for i in (seq (count $expectedCommands))
            if [ $currentCommands[$i] != $expectedCommands[$i] ]
                return 1
            end
        end
        if [ (count $currentCommands) -eq (count $expectedCommands) ]
            return 0
        end
        if [ (count $subcommands) -gt 1 ]
            for i in (seq (count $subcommands))
                if [ $currentCommands[(math (count $expectedCommands) + 1)] = $subcommands[$i] ]
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
complete -c math -n '_swift_math_using_command "math stats average"' -l kind -d 'The kind of average to provide.' -r -f -k -a 'mean median mode'
complete -c math -n '_swift_math_using_command "math stats average"' -l version -d 'Show the version.'
complete -c math -n '_swift_math_using_command "math stats average"' -s h -l help -d 'Show help information.'
complete -c math -n '_swift_math_using_command "math stats stdev"' -l version -d 'Show the version.'
complete -c math -n '_swift_math_using_command "math stats stdev"' -s h -l help -d 'Show help information.'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -r -f -k -a 'alphabet alligator branch braggart'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -r -f -a '(command math ---completion stats quantiles -- customArg (commandline -opc)[1..-1])'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -l file -r -f -a '(for i in *.{txt,md}; echo $i;end)'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -l directory -r -f -a '(__fish_complete_directories)'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -l shell -r -f -a '(head -100 /usr/share/dict/words | tail -50)'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -l custom -r -f -a '(command math ---completion stats quantiles -- --custom (commandline -opc)[1..-1])'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -l version -d 'Show the version.'
complete -c math -n '_swift_math_using_command "math stats quantiles"' -s h -l help -d 'Show help information.'
complete -c math -n '_swift_math_using_command "math stats" "average stdev quantiles"' -l version -d 'Show the version.'
complete -c math -n '_swift_math_using_command "math stats" "average stdev quantiles"' -s h -l help -d 'Show help information.'
complete -c math -n '_swift_math_using_command "math stats" "average stdev quantiles"' -f -a 'average' -d 'Print the average of the values.'
complete -c math -n '_swift_math_using_command "math stats" "average stdev quantiles"' -f -a 'stdev' -d 'Print the standard deviation of the values.'
complete -c math -n '_swift_math_using_command "math stats" "average stdev quantiles"' -f -a 'quantiles' -d 'Print the quantiles of the values (TBD).'
complete -c math -n '_swift_math_using_command "math help"' -l version -d 'Show the version.'
complete -c math -n '_swift_math_using_command "math" "add multiply stats help"' -l version -d 'Show the version.'
complete -c math -n '_swift_math_using_command "math" "add multiply stats help"' -s h -l help -d 'Show help information.'
complete -c math -n '_swift_math_using_command "math" "add multiply stats help"' -f -a 'add' -d 'Print the sum of the values.'
complete -c math -n '_swift_math_using_command "math" "add multiply stats help"' -f -a 'multiply' -d 'Print the product of the values.'
complete -c math -n '_swift_math_using_command "math" "add multiply stats help"' -f -a 'stats' -d 'Calculate descriptive statistics.'
complete -c math -n '_swift_math_using_command "math" "add multiply stats help"' -f -a 'help' -d 'Show subcommand help information.'
