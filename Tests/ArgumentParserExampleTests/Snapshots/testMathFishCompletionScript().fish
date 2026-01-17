function __math_should_offer_completions_for_flags_or_options -a expected_commands
    set -l non_repeating_flags_or_options $argv[2..]

    set -l non_repeating_flags_or_options_absent 0
    set -l positional_index 0
    set -l commands
    __math_parse_tokens
    test "$commands" = "$expected_commands"; and return $non_repeating_flags_or_options_absent
end

function __math_should_offer_completions_for_positional -a expected_commands expected_positional_index positional_index_comparison
    if test -z $positional_index_comparison
        set positional_index_comparison -eq
    end

    set -l non_repeating_flags_or_options
    set -l non_repeating_flags_or_options_absent 0
    set -l positional_index 0
    set -l commands
    __math_parse_tokens
    test "$commands" = "$expected_commands" -a \( "$positional_index" "$positional_index_comparison" "$expected_positional_index" \)
end

function __math_parse_tokens -S
    set -l unparsed_tokens (__math_tokens -pc)
    set -l present_flags_and_options

    switch $unparsed_tokens[1]
    case 'math'
        __math_parse_subcommand 0 'v/version' 'h/help'
        switch $unparsed_tokens[1]
        case 'add'
            __math_parse_subcommand -r 1 'x/hex-output' 'v/version' 'h/help'
        case 'multiply'
            __math_parse_subcommand -r 1 'x/hex-output' 'v/version' 'h/help'
        case 'stats'
            __math_parse_subcommand 0 'v/version' 'h/help'
            switch $unparsed_tokens[1]
            case 'average'
                __math_parse_subcommand -r 1 'kind=' 'v/version' 'h/help'
            case 'stdev'
                __math_parse_subcommand -r 1 'v/version' 'h/help'
            case 'quantiles'
                __math_parse_subcommand -r 4 'file=' 'directory=' 'shell=' 'custom=' 'custom-deprecated=' 'v/version' 'h/help'
            end
        case 'help'
            __math_parse_subcommand -r 1 'v/version'
        end
    end
end

function __math_tokens
    if test (string split -m 1 -f 1 -- . "$FISH_VERSION") -gt 3
        commandline --tokens-raw $argv
    else
        commandline -o $argv
    end
end

function __math_parse_subcommand -S -a positional_count
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

function __math_complete_directories
    set -l token (commandline -t)
    string match -- '*/' $token
    set -l subdirs $token*/
    printf '%s\n' $subdirs
end

function __math_custom_completion
    set -x SAP_SHELL fish
    set -x SAP_SHELL_VERSION $FISH_VERSION

    set -l tokens (__math_tokens -p)
    if test -z (__math_tokens -t)
        set -l index (count (__math_tokens -pc))
        set tokens $tokens[..$index] \'\' $tokens[(math $index + 1)..]
    end
    command $tokens[1] $argv $tokens
end

complete -c 'math' -f
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math" v version' -s 'v' -l 'version' -d 'Show the version.'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'math' -n '__math_should_offer_completions_for_positional "math" 1' -fa 'add' -d 'Print the sum of the values.'
complete -c 'math' -n '__math_should_offer_completions_for_positional "math" 1' -fa 'multiply' -d 'Print the product of the values.'
complete -c 'math' -n '__math_should_offer_completions_for_positional "math" 1' -fa 'stats' -d 'Calculate descriptive statistics.'
complete -c 'math' -n '__math_should_offer_completions_for_positional "math" 1' -fa 'help' -d 'Show subcommand help information.'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math add" hex-output x' -l 'hex-output' -s 'x' -d 'Use hexadecimal notation for the result.'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math add" v version' -s 'v' -l 'version' -d 'Show the version.'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math add" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math multiply" hex-output x' -l 'hex-output' -s 'x' -d 'Use hexadecimal notation for the result.'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math multiply" v version' -s 'v' -l 'version' -d 'Show the version.'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math multiply" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math stats" v version' -s 'v' -l 'version' -d 'Show the version.'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math stats" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'math' -n '__math_should_offer_completions_for_positional "math stats" 1' -fa 'average' -d 'Print the average of the values.'
complete -c 'math' -n '__math_should_offer_completions_for_positional "math stats" 1' -fa 'stdev' -d 'Print the standard deviation of the values.'
complete -c 'math' -n '__math_should_offer_completions_for_positional "math stats" 1' -fa 'quantiles' -d 'Print the quantiles of the values (TBD).'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math stats average" kind' -l 'kind' -d 'The kind of average to provide.' -rfka 'mean median mode'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math stats average" v version' -s 'v' -l 'version' -d 'Show the version.'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math stats average" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math stats stdev" v version' -s 'v' -l 'version' -d 'Show the version.'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math stats stdev" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'math' -n '__math_should_offer_completions_for_positional "math stats quantiles" 1' -fka 'alphabet alligator branch braggart'
complete -c 'math' -n '__math_should_offer_completions_for_positional "math stats quantiles" 2' -fka '(__math_custom_completion ---completion stats quantiles -- positional@1 (count (__math_tokens -pc)) (__math_tokens -tC))'
complete -c 'math' -n '__math_should_offer_completions_for_positional "math stats quantiles" 3' -fka '(__math_custom_completion ---completion stats quantiles -- positional@2)'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math stats quantiles" file' -l 'file' -rfa '(set -l exts \'txt\' \'md\';for p in (string match -e -- \'*/\' (commandline -t);or printf \n)*.{$exts};printf %s\n $p;end;__fish_complete_directories (commandline -t) \'\')'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math stats quantiles" directory' -l 'directory' -rfa '(__math_complete_directories)'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math stats quantiles" shell' -l 'shell' -rfka '(head -100 \'/usr/share/dict/words\' | tail -50)'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math stats quantiles" custom' -l 'custom' -rfka '(__math_custom_completion ---completion stats quantiles -- --custom (count (__math_tokens -pc)) (__math_tokens -tC))'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math stats quantiles" custom-deprecated' -l 'custom-deprecated' -rfka '(__math_custom_completion ---completion stats quantiles -- --custom-deprecated)'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math stats quantiles" v version' -s 'v' -l 'version' -d 'Show the version.'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math stats quantiles" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'math' -n '__math_should_offer_completions_for_flags_or_options "math help" v version' -s 'v' -l 'version' -d 'Show the version.'
