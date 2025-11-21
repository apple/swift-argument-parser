function __defaultasflag-test_should_offer_completions_for_flags_or_options -a expected_commands
    set -l non_repeating_flags_or_options $argv[2..]

    set -l non_repeating_flags_or_options_absent 0
    set -l positional_index 0
    set -l commands
    __defaultasflag-test_parse_tokens
    test "$commands" = "$expected_commands"; and return $non_repeating_flags_or_options_absent
end

function __defaultasflag-test_should_offer_completions_for_positional -a expected_commands expected_positional_index positional_index_comparison
    if test -z $positional_index_comparison
        set positional_index_comparison -eq
    end

    set -l non_repeating_flags_or_options
    set -l non_repeating_flags_or_options_absent 0
    set -l positional_index 0
    set -l commands
    __defaultasflag-test_parse_tokens
    test "$commands" = "$expected_commands" -a \( "$positional_index" "$positional_index_comparison" "$expected_positional_index" \)
end

function __defaultasflag-test_parse_tokens -S
    set -l unparsed_tokens (__defaultasflag-test_tokens -pc)
    set -l present_flags_and_options

    switch $unparsed_tokens[1]
    case 'defaultasflag-test'
        __defaultasflag-test_parse_subcommand 1 'bin-path=' 'count=' 'verbose=' 'log-level=' 'help' 'h/help'
        switch $unparsed_tokens[1]
        case 'help'
            __defaultasflag-test_parse_subcommand -r 1 
        end
    end
end

function __defaultasflag-test_tokens
    if test (string split -m 1 -f 1 -- . "$FISH_VERSION") -gt 3
        commandline --tokens-raw $argv
    else
        commandline -o $argv
    end
end

function __defaultasflag-test_parse_subcommand -S -a positional_count
    argparse -s r -- $argv
    set -l option_specs $argv[2..]

    set -a commands $unparsed_tokens[1]
    set -e unparsed_tokens[1]

    set positional_index 0

    while true
        argparse -sn "$commands" $option_specs -- $unparsed_tokens 2> /dev/null
        set unparsed_tokens $argv
        set positional_index (math $positional_index + 1)

        for non_repeating_flag_or_option in $non_repeating_flags_or_options
            if set -ql _flag_$non_repeating_flag_or_option
                set non_repeating_flags_or_options_absent 1
                break
            end
        end

        if test (count $unparsed_tokens) -eq 0 -o \( -z "$_flag_r" -a "$positional_index" -gt "$positional_count" \)
            break
        end
        set -e unparsed_tokens[1]
    end
end

function __defaultasflag-test_complete_directories
    set -l token (commandline -t)
    string match -- '*/' $token
    set -l subdirs $token*/
    printf '%s\n' $subdirs
end

function __defaultasflag-test_custom_completion
    set -x SAP_SHELL fish
    set -x SAP_SHELL_VERSION $FISH_VERSION

    set -l tokens (__defaultasflag-test_tokens -p)
    if test -z (__defaultasflag-test_tokens -t)
        set -l index (count (__defaultasflag-test_tokens -pc))
        set tokens $tokens[..$index] \'\' $tokens[(math $index + 1)..]
    end
    command $tokens[1] $argv $tokens
end

complete -c 'defaultasflag-test' -f
complete -c 'defaultasflag-test' -n '__defaultasflag-test_should_offer_completions_for_flags_or_options "defaultasflag-test" bin-path' -l 'bin-path' -rfa '(__defaultasflag-test_complete_directories)'
complete -c 'defaultasflag-test' -n '__defaultasflag-test_should_offer_completions_for_flags_or_options "defaultasflag-test" count' -l 'count' -rfka ''
complete -c 'defaultasflag-test' -n '__defaultasflag-test_should_offer_completions_for_flags_or_options "defaultasflag-test" verbose' -l 'verbose' -rfka ''
complete -c 'defaultasflag-test' -n '__defaultasflag-test_should_offer_completions_for_flags_or_options "defaultasflag-test" log-level' -l 'log-level' -rfka 'DEBUG INFO WARN ERROR'
complete -c 'defaultasflag-test' -n '__defaultasflag-test_should_offer_completions_for_flags_or_options "defaultasflag-test" help' -l 'help'
complete -c 'defaultasflag-test' -n '__defaultasflag-test_should_offer_completions_for_positional "defaultasflag-test" 1' -F
complete -c 'defaultasflag-test' -n '__defaultasflag-test_should_offer_completions_for_flags_or_options "defaultasflag-test" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'defaultasflag-test' -n '__defaultasflag-test_should_offer_completions_for_positional "defaultasflag-test" 2' -fa 'help' -d 'Show subcommand help information.'