function __base-test_should_offer_completions_for_flags_or_options -a expected_commands
    set -l non_repeating_flags_or_options $argv[2..]

    set -l non_repeating_flags_or_options_absent 0
    set -l positional_index 0
    set -l commands
    __base-test_parse_tokens
    test "$commands" = "$expected_commands"; and return $non_repeating_flags_or_options_absent
end

function __base-test_should_offer_completions_for_positional -a expected_commands expected_positional_index positional_index_comparison
    if test -z $positional_index_comparison
        set positional_index_comparison -eq
    end

    set -l non_repeating_flags_or_options
    set -l non_repeating_flags_or_options_absent 0
    set -l positional_index 0
    set -l commands
    __base-test_parse_tokens
    test "$commands" = "$expected_commands" -a \( "$positional_index" "$positional_index_comparison" "$expected_positional_index" \)
end

function __base-test_parse_tokens -S
    set -l unparsed_tokens (__base-test_tokens -pc)
    set -l present_flags_and_options

    switch $unparsed_tokens[1]
    case 'base-test'
        __base-test_parse_subcommand 2 'name=' 'kind=' 'other-kind=' 'path1=' 'path2=' 'path3=' 'one' 'two' 'custom-three' 'kind-counter' 'rep1=+' 'r/rep2=+' 'h/help'
        switch $unparsed_tokens[1]
        case 'sub-command'
            __base-test_parse_subcommand 0 'h/help'
        case 'escaped-command'
            __base-test_parse_subcommand 1 'o:n[e=' 'h/help'
        case 'help'
            __base-test_parse_subcommand -r 1 
        end
    end
end

function __base-test_tokens
    if test (string split -m 1 -f 1 -- . "$FISH_VERSION") -gt 3
        commandline --tokens-raw $argv
    else
        commandline -o $argv
    end
end

function __base-test_parse_subcommand -S -a positional_count
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

function __base-test_complete_directories
    set -l token (commandline -t)
    string match -- '*/' $token
    set -l subdirs $token*/
    printf '%s\n' $subdirs
end

function __base-test_custom_completion
    set -x SAP_SHELL fish
    set -x SAP_SHELL_VERSION $FISH_VERSION

    set -l tokens (__base-test_tokens -p)
    if test -z (__base-test_tokens -t)
        set -l index (count (__base-test_tokens -pc))
        set tokens $tokens[..$index] \'\' $tokens[(math $index + 1)..]
    end
    command $tokens[1] $argv $tokens
end

complete -c 'base-test' -f
complete -c 'base-test' -n '__base-test_should_offer_completions_for_flags_or_options "base-test" name' -l 'name' -d 'The user\'s name.' -rfka ''
complete -c 'base-test' -n '__base-test_should_offer_completions_for_flags_or_options "base-test" kind' -l 'kind' -rfka 'one two custom-three'
complete -c 'base-test' -n '__base-test_should_offer_completions_for_flags_or_options "base-test" other-kind' -l 'other-kind' -rfka 'b1_fish b2_fish b3_fish'
complete -c 'base-test' -n '__base-test_should_offer_completions_for_flags_or_options "base-test" path1' -l 'path1' -rF
complete -c 'base-test' -n '__base-test_should_offer_completions_for_flags_or_options "base-test" path2' -l 'path2' -rF
complete -c 'base-test' -n '__base-test_should_offer_completions_for_flags_or_options "base-test" path3' -l 'path3' -rfka 'c1_fish c2_fish c3_fish'
complete -c 'base-test' -n '__base-test_should_offer_completions_for_flags_or_options "base-test" one' -l 'one'
complete -c 'base-test' -n '__base-test_should_offer_completions_for_flags_or_options "base-test" two' -l 'two'
complete -c 'base-test' -n '__base-test_should_offer_completions_for_flags_or_options "base-test" custom-three' -l 'custom-three'
complete -c 'base-test' -n '__base-test_should_offer_completions_for_flags_or_options "base-test"' -l 'kind-counter'
complete -c 'base-test' -n '__base-test_should_offer_completions_for_flags_or_options "base-test"' -l 'rep1' -rfka ''
complete -c 'base-test' -n '__base-test_should_offer_completions_for_flags_or_options "base-test"' -s 'r' -l 'rep2' -rfka ''
complete -c 'base-test' -n '__base-test_should_offer_completions_for_positional "base-test" 1' -fka '(__base-test_custom_completion ---completion -- positional@0 (count (__base-test_tokens -pc)) (__base-test_tokens -tC))'
complete -c 'base-test' -n '__base-test_should_offer_completions_for_positional "base-test" 2' -fka '(__base-test_custom_completion ---completion -- positional@1 (count (__base-test_tokens -pc)) (__base-test_tokens -tC))'
complete -c 'base-test' -n '__base-test_should_offer_completions_for_flags_or_options "base-test" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'base-test' -n '__base-test_should_offer_completions_for_positional "base-test" 3' -fa 'sub-command' -d ''
complete -c 'base-test' -n '__base-test_should_offer_completions_for_positional "base-test" 3' -fa 'escaped-command' -d ''
complete -c 'base-test' -n '__base-test_should_offer_completions_for_positional "base-test" 3' -fa 'help' -d 'Show subcommand help information.'
complete -c 'base-test' -n '__base-test_should_offer_completions_for_flags_or_options "base-test sub-command" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'base-test' -n '__base-test_should_offer_completions_for_flags_or_options "base-test escaped-command" o:n[e' -l 'o:n[e' -d 'Escaped chars: \'[]\\.' -rfka ''
complete -c 'base-test' -n '__base-test_should_offer_completions_for_positional "base-test escaped-command" 1' -fka '(__base-test_custom_completion ---completion escaped-command -- positional@0 (count (__base-test_tokens -pc)) (__base-test_tokens -tC))'
complete -c 'base-test' -n '__base-test_should_offer_completions_for_flags_or_options "base-test escaped-command" h help' -s 'h' -l 'help' -d 'Show help information.'