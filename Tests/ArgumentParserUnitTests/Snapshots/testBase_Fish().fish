# A function which filters options which starts with "-" from $argv.
function _swift_base-test_preprocessor
    set -l results
    for i in (seq (count $argv))
        switch (echo $argv[$i] | string sub -l 1)
            case '-'
            case '*'
                echo $argv[$i]
        end
    end
end

function _swift_base-test_using_command
    set -gx SAP_SHELL fish
    set -gx SAP_SHELL_VERSION "$FISH_VERSION"
    set -l currentCommands (_swift_base-test_preprocessor (commandline -opc))
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

complete -c base-test -n '_swift_base-test_using_command "base-test sub-command"' -s h -l help -d 'Show help information.'
complete -c base-test -n '_swift_base-test_using_command "base-test escaped-command"' -l one -d 'Escaped chars: \'[]\\.'
complete -c base-test -n '_swift_base-test_using_command "base-test escaped-command"' -r -f -a '(command base-test ---completion escaped-command -- two (commandline -opc)[1..-1])'
complete -c base-test -n '_swift_base-test_using_command "base-test escaped-command"' -s h -l help -d 'Show help information.'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l name -d 'The user\'s name.'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l kind -r -f -k -a 'one two custom-three'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l other-kind -r -f -k -a 'b1_fish b2_fish b3_fish'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l path1 -r -f -a '(for i in *.{}; echo $i;end)'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l path2 -r -f -a '(for i in *.{}; echo $i;end)'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l path3 -r -f -k -a 'c1_fish c2_fish c3_fish'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l one
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l two
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l three
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l kind-counter
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l rep1
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -s r -l rep2
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -r -f -a '(command base-test ---completion  -- argument (commandline -opc)[1..-1])'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -r -f -a '(command base-test ---completion  -- nested.nestedArgument (commandline -opc)[1..-1])'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -s h -l help -d 'Show help information.'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -f -a 'sub-command' -d ''
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -f -a 'escaped-command' -d ''
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -f -a 'help' -d 'Show subcommand help information.'