#!/usr/bin/env raku

use Terminal::KeyReader;

sub MAIN {
    my $num = 20;
    say "After you will have pressed $num keys. the program will end.";
    say "Got ", Terminal::KeyReader::read-key for ^$num;
}

