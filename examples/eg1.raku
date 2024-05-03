#!/usr/bin/env raku

use Terminal::KeyReader;

sub MAIN {

        # The constructor will use a test resource file,
        # where only a few keys are defined.
    my $TKR = Terminal::KeyReader.new: :resource('test');

        # Echo a number of keypresses and stop.
    my $num = 10;
    say "After you will have pressed $num keys. the program will end.";
    say "Got ", $TKR.read-key for ^$num;
}

