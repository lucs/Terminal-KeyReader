#!/usr/bin/env raku

use Terminal::KeyReader;

sub MAIN ($nb-keypress = 10) {

        # This constructor will use the default resource file
        # ('us.layout') and will report key names when known, keycodes
        # when not.
    my $tkr = Terminal::KeyReader.new;

        # Echo a number of keypresses and stop.
    say "This program will display the names of the keys you press,";
    say "but when the name is unknown, their keycodes instead.";
    say "After you will have pressed $nb-keypress keys, the program will end.";
    say $tkr.read-key for ^$nb-keypress;
}

