status is-interactive || exit

# config.fish sets fish_key_bindings, and fish erases every binding when that
# variable changes — so re-apply on the event instead of binding just once.
function _surround_key_bindings --on-variable fish_key_bindings
    for mode in insert default
        # Ghostty speaks the kitty keyboard protocol, which reports a shifted
        # key by its physical position: the same chord arrives as alt-shift-9
        # there and as alt-( on terminals without it. Bind both.
        bind --mode $mode alt-shift-9 __surround_with_parens
        bind --mode $mode alt-'(' __surround_with_parens
    end
end

_surround_key_bindings
