#!/usr/bin/env raku

use Terminal::KeyReader;

sub MAIN ($nb-keypress = 10) {

        # The constructor will use a test resource file,
        # where only a few keys are defined.
    my $TKR = Terminal::KeyReader.new: :resource('test');

        # Echo a number of keypresses and stop.
    my $nb-keypress = 10;
    say "After you will have pressed $nb-keypress keys, the program will end.";
    say "Got ", $TKR.read-key for ^$nb-keypress;
}

