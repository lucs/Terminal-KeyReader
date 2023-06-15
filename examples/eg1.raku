#!/usr/bin/env raku

use Terminal::KeyReader;

sub MAIN {

        # Create instance from a supplied resource file.
    my $TKR = Terminal::KeyReader.new: :resource('test.layout');

        # Echo a number of keypresses and stop.
    my $num = 4;
    say "After you will have pressed $num keys. the program will end.";
    say "Got ", $TKR.read-key for ^$num;
}

