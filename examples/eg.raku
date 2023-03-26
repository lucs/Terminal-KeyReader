#!/usr/bin/env raku

use Terminal::KeyReader :read-key;
#use Terminal::KeyReader;

# --------------------------------------------------------------------
multi sub MAIN ('a') {
    my $num = 20;
    say "After you will have pressed $num keys. the program will end.";
    say "Got ", read-key for ^$num;
   # say "Got ", Terminal::KeyReader::read-key for ^$num;
}

# --------------------------------------------------------------------
multi sub MAIN ('b') {
    my $key;
    my $str = '';
    say q:to/EoMsg/
        Press keys. Single character ones will be echoed and concatenated
        into a string that will be output when you press Enter.
        The program will end when you Enter an empty string.
        EoMsg
    ;
    loop {
        loop {
            $key = read-key;
           # $key = Terminal::KeyReader::read-key;
            last if $key eq 'CR' | 'LF';
            
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

