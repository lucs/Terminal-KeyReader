#!/usr/bin/env raku

use Terminal::KeyReader;

sub MAIN {

        # This tells the constructor to use no resource file, so no
        # keys will be defined and only keycodes can be reported.
    my $TKR = Terminal::KeyReader.new: :resource('');

        # Echo a number of keypresses and stop.
    my $num = 12;
    say "After you will have pressed $num keys. the program will end.";
    say "Got ", $TKR.read-key for ^$num;
}

