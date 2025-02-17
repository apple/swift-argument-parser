function _swift_base-test_commands_and_positionals -S
    switch $positionals[1]
    case 'base-test'
        _swift_base-test_commands_and_positionals_helper '' 'name= kind= other-kind= path1= path2= path3= one two three kind-counter rep1= r/rep2= h/help'
    case '*'
        set commands $positionals[1]
        set -e positionals[1]
    end
end

function _swift_base-test_commands_and_positionals_helper -S -a argparse_options -a option_specs
    set -a commands $positionals[1]
    set -e positionals[1]
    if test -z $argparse_options
        argparse -n "$commands" (string split -- ' ' $option_specs) -- $positionals 2> /dev/null
        set positionals $argv
    else
        argparse (string split -- ' ' $argparse_options) -n "$commands" (string split -- ' ' $option_specs) -- $positionals 2> /dev/null
        set positionals $argv
    end
end

function _swift_base-test_tokens
    if test (string split -m 1 -f 1 -- . $FISH_VERSION) -gt 3
        commandline --tokens-raw $argv
    else
        commandline -o $argv
    end
end

function _swift_base-test_using_command -a expected_commands
    set commands
    set positionals (_swift_base-test_tokens -pc)
    _swift_base-test_commands_and_positionals
    test "$commands" = $expected_commands
end

function _swift_base-test_positional_index
    set positionals (_swift_base-test_tokens -pc)
    _swift_base-test_commands_and_positionals
    math (count $positionals) + 1
end

function _swift_base-test_complete_directories
    set token (commandline -t)
    string match -- '*/' $token
    set subdirs $token*/
    printf '%s\n' $subdirs
end

function _swift_base-test_custom_completion
    set -x SAP_SHELL fish
    set -x SAP_SHELL_VERSION $FISH_VERSION

    set tokens (_swift_base-test_tokens -p)
    if test -z (_swift_base-test_tokens -t)
        set index (count (_swift_base-test_tokens -pc))
        set tokens $tokens[..$index] \'\' $tokens[$(math $index + 1)..]
    end
    command $tokens[1] $argv $tokens
end

complete -c base-test -f
complete -c base-test -n '_swift_base-test_using_command "base-test"' -l name -d 'The user\'s name.'
complete -c base-test -n '_swift_base-test_using_command "base-test"' -l kind -rfka 'one two custom-three'
complete -c base-test -n '_swift_base-test_using_command "base-test"' -l other-kind -rfka 'b1_fish b2_fish b3_fish'
complete -c base-test -n '_swift_base-test_using_command "base-test"' -l path1 -rF
complete -c base-test -n '_swift_base-test_using_command "base-test"' -l path2 -rF
complete -c base-test -n '_swift_base-test_using_command "base-test"' -l path3 -rfka 'c1_fish c2_fish c3_fish'
complete -c base-test -n '_swift_base-test_using_command "base-test"' -l one
complete -c base-test -n '_swift_base-test_using_command "base-test"' -l two
complete -c base-test -n '_swift_base-test_using_command "base-test"' -l three
complete -c base-test -n '_swift_base-test_using_command "base-test"' -l kind-counter
complete -c base-test -n '_swift_base-test_using_command "base-test"' -l rep1
complete -c base-test -n '_swift_base-test_using_command "base-test"' -s r -l rep2
complete -c base-test -n '_swift_base-test_using_command "base-test";and test (_swift_base-test_positional_index) -eq 1' -rfka '(_swift_base-test_custom_completion ---completion  -- argument)'
complete -c base-test -n '_swift_base-test_using_command "base-test";and test (_swift_base-test_positional_index) -eq 2' -rfka '(_swift_base-test_custom_completion ---completion  -- nested.nestedArgument)'
complete -c base-test -n '_swift_base-test_using_command "base-test"' -s h -l help -d 'Show help information.'