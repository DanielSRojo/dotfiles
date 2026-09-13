function __surround_with_parens --description 'Wrap the command under the cursor in () and jump in front of it'
    set -l proc (commandline --current-process)
    set -l body (string trim -l -- $proc)
    test -n "$body"; or return

    # Whatever separator preceded the command (the space after a |) stays
    # outside the parens, normalised to exactly one space so there is always
    # room to type the outer command the parens are being opened for.
    set -l lead (string sub -l (math (string length -- $proc) - (string length -- $body)) -- $proc)
    set -l prefix (string replace -r '[ \t]*$' ' ' -- $lead)

    commandline --replace --current-process -- $prefix"($body)"
    commandline --cursor --current-process 0
end
