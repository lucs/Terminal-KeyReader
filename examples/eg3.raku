#!/usr/bin/env raku

use Terminal::KeyReader;

sub MAIN {
    my $TKR = Terminal::KeyReader.new: 'us';

    True && say $TKR.display(
        {$^a.rank cmp $^b.rank},
        -> $kdef { sprintf "%20s   %s%s%s %-10s %s\n",
              $kdef.name,
              $kdef.ctrl ?? 'c' !! '_',
              $kdef.altt ?? 'a' !! '_',
              $kdef.shft ?? 's' !! '_',
              $kdef.root,
              $kdef.nums.map({sprintf '%s', $_}).join(" "),
             # $kdef.nums.join("\t"),
        ; },
    );

    False && say $TKR.display(
        {$^a.rank cmp $^b.rank},
        -> $kdef { sprintf "%s\t%s\t%s\t%s\t%s\t%s\n",
              $kdef.name.subst('"', '""', :g),
              $kdef.root.subst('"', '""', :g),
              $kdef.ctrl ?? 'x' !! '',
              $kdef.altt ?? 'x' !! '',
              $kdef.shft ?? 'x' !! '',
              $kdef.nums.join("\t"),
        ; },
    );

}

