#!/usr/bin/env raku

use Terminal::KeyReader;

sub MAIN {
    my $key;
    my $str = '';
    say q:to/EoMsg/
        Press keys. Single character ones will be echoed and concatenated
        into a string that will be output when you press Enter.
        The program will end when you Enter an empty string.
        EoMsg
    ;
        # Create instance from a supplied default resource file.
    my $TKR = Terminal::KeyReader.new: 'us';
    $TKR.claim: "CtrlG", "Bel";
    $TKR.claim: "CtrlH", "Bs";
    $TKR.claim: "CtrlI", "Ht";
    $TKR.claim: "CtrlJ", "Lf";
    $TKR.claim: "CtrlK", "Vt";
    $TKR.claim: "CtrlL", "Ff";
    $TKR.claim: "CtrlM", "Enter";

    loop {
        loop {
            $key = $TKR.read-key;
            last if $key eq 'Enter' | 'Lf';
            
                # Ignore anything but single character results.
            next unless $key.chars == 1;
            say "key: $key";
            $str ~= $key;
        }
        last if $str eq '';
        say "   : $str";
        $str = '';
    }
}

