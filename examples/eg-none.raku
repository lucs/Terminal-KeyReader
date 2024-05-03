#!/usr/bin/env raku

use Terminal::KeyReader;

sub MAIN ($nb-keypress = 10) {

        # This tells the constructor to use no resource file, so no
        # keys will be defined and only keycodes will be reported.
    my $tkr = Terminal::KeyReader.new: :resource('');

        # Echo a number of keypresses and stop.
    say "This program will display the keycodes of the keys you press.";
    say "After you will have pressed $nb-keypress keys. the program will end.";
    say $tkr.read-key for ^$nb-keypress;
}

