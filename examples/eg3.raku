#!/usr/bin/env raku

use Terminal::KeyReader;

sub MAIN {
    my $TKR = Terminal::KeyReader.new: 'us';

    True && say $TKR.display(
        {$^a.rank cmp $^b.rank},
        -> $kd { sprintf "%20s   %s%s%s %-10s %s\n",
              $kd.name,
              $kd.ctrl ?? 'c' !! '_',
              $kd.altt ?? 'a' !! '_',
              $kd.shft ?? 's' !! '_',
              $kd.root,
              $kd.nums.map({sprintf '%s', $_}).join(" "),
             # $kd.nums.join("\t"),
        ; },
    );

    False && say $TKR.display(
        {$^a.rank cmp $^b.rank},
        -> $kd { sprintf "%s\t%s\t%s\t%s\t%s\t%s\n",
              $kd.name.subst('"', '""', :g),
              $kd.root.subst('"', '""', :g),
              $kd.ctrl ?? 'x' !! '',
              $kd.altt ?? 'x' !! '',
              $kd.shft ?? 'x' !! '',
              $kd.nums.join("\t"),
        ; },
    );

}

