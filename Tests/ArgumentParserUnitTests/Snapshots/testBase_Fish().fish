# A function which filters options which starts with "-" from $argv.
function _swift_base-test_commands_and_positionals
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
    set -l commands_and_positionals (_swift_base-test_commands_and_positionals (commandline -opc))
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

complete -c base-test -n '_swift_base-test_using_command "base-test sub-command"' -s h -l help -d 'Show help information.'
complete -c base-test -n '_swift_base-test_using_command "base-test escaped-command"' -l one -d 'Escaped chars: \'[]\\.'
complete -c base-test -n '_swift_base-test_using_command "base-test escaped-command"' -rfa '(command base-test ---completion escaped-command -- two (commandline -opc)[1..-1])'
complete -c base-test -n '_swift_base-test_using_command "base-test escaped-command"' -s h -l help -d 'Show help information.'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l name -d 'The user\'s name.'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l kind -rfka 'one two custom-three'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l other-kind -rfka 'b1_fish b2_fish b3_fish'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l path1 -rfa '(for i in *.{}; echo $i;end)'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l path2 -rfa '(for i in *.{}; echo $i;end)'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l path3 -rfka 'c1_fish c2_fish c3_fish'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l one
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l two
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l three
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l kind-counter
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -l rep1
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -s r -l rep2
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -rfa '(command base-test ---completion  -- argument (commandline -opc)[1..-1])'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -rfa '(command base-test ---completion  -- nested.nestedArgument (commandline -opc)[1..-1])'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -s h -l help -d 'Show help information.'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -fa 'sub-command' -d ''
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -fa 'escaped-command' -d ''
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command escaped-command help"' -fa 'help' -d 'Show subcommand help information.'