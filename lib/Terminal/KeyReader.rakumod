unit class Terminal::KeyReader;

=begin pod

=head1 NAME

Terminal::KeyReader - Read key presses from the keyboard buffer

=head1 SYNOPSIS

=begin code :lang<raku>

use Terminal::KeyReader;

=end code

=head1 DESCRIPTION

Terminal::KeyReader is ...

=head1 AUTHOR

Luc St-Louis <lucs@pobox.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Luc St-Louis

This library is free software; you can redistribute it and/or modify
it under the Artistic License 2.0.

=end pod

# --------------------------------------------------------------------
class KeyDef {
        
    has $.name; # ⦃"Ctrl F12"⦄ ⦃"Alt Shift &"⦄
    has $.root; # ⌊F12⌉        ⌊&⌉
    has $.ctrl; # ⌊True⌉       ⌊False⌉
    has $.altt; # ⌊False⌉      ⌊True⌉
    has $.shft; # ⌊False⌉      ⌊True⌉

        # The keycode numbers (okay, not the best name, but I like it
        # for the four-letter symmetry).
        # ⦃(27, 3, 126)⦄
    has @.nums;

        # ⦃"027003126000000000000"⦄, used for sorting.
    has $.rank;

    method style1-new (
            # "⟨name⟩ ¦ ⟨nums⟩"
            # ⦃"Ctrl F12 ¦ 27 91"⦄
        $str
    ) {
        $str ~~ /
            ^ \s*
            $<name> = [ .*? ] \s* '¦' \s*
            $<nums> = [ .*? ]
            \s* $
        /;
        my $name = $/<name>;
        my @nums = $/<nums>.comb: /\d+/;

            # Out of the nums, rank. Something like:
            #   ⦃127⦄        <127000000000000000000>
            #   ⦃27, 3, 126⦄ <027003126000000000000>
        my $rank = sprintf(
            '<%-21s>',
            @nums.map({sprintf '%03d', $_}).join,
        ).subst(' ', "0", :g);

       # note "｢$name｣ " ~ @nums.join(".") ~ " $rank";
        my $root = $name
            .subst('Ctrl')
            .subst('Alt')
            .subst('Shift')
            .subst(' ', :g)
        ;
        my $ctrl = $name ~~ /Ctrl/;
        my $altt = $name ~~ /Alt/;
        my $shft = $name ~~ /Shift/;

       # note sprintf "%10s %1s%1s%1s : %s",
       #     $root,
       #     $ctrl ?? 'C' !! ' ',
       #     $altt ?? 'A' !! ' ',
       #     $shft ?? 'S' !! ' ',
       #     $name,
       # ;

        return self.bless:
            :$name,
            :@nums,
            :$rank,
            :$root,
            :$ctrl,
            :$altt,
            :$shft,
       ;
    }

}

# --------------------------------------------------------------------
class Keyboard {

    has @.key-def;

    method new ($lines, $line-style) {
        my @key-def;
        for $lines.lines -> $line {
            next if $line ~~ /^ \s* '#' /;
            @key-def.push: KeyDef.new: $line;
        }
        return self.bless: :@key-def;
    }

    method add (KeyDef $key-def) {
        @!key-def.push: $key-def;
    }

    method display (
            # {$^a.rank cmp $^b.rank}.
        &sort-how,

            # -> $kd { sprintf "%s\t%s\t%s\t%s\t%s\t%s\n",
            #       $kd.name.subst('"', '""', :g),
            #       $kd.root.subst('"', '""', :g),
            #       $kd.ctrl ?? 'X' !! '',
            #       $kd.altt ?? 'X' !! '',
            #       $kd.shft ?? 'X' !! '',
            #       $kd.nums.join("\t"),
            # ; }
        &show-how,
    ) {
        my @sorted_key-def = sort {
            &sort-how($^a, $^b)
        }, @.key-def;
        my $ret-str;
        for @sorted_key-def -> $kd {
            $ret-str ~= &show-how($kd);
        }
        return $ret-str;
    }

}

# --------------------------------------------------------------------
use Term::termios;

my $in-terminal = $*IN.t && $*OUT.t;

my $orig-tty-state;
my $want-tty-state;

if $in-terminal {
    my $tty-fd = $*IN.native-descriptor;

        # Save the original tty state.
    $orig-tty-state = Term::termios.new(fd => $tty-fd).getattr;

        # Prepare a raw and unbuffered tty for when we will want to be
        # reading keys.
    given ($want-tty-state = Term::termios.new(fd => $tty-fd).getattr) {
        .makeraw;
    }
}

    # Ensure that the original tty state is restored when we leave
    # a program using this module.
END {$orig-tty-state.setattr: :NOW if $in-terminal};

# --------------------------------------------------------------------
has $keyboard;
has %.kk;

method new (:$resource = 'us', :$line-style = 's1', :$lines) {
    my $keyboard = $lines
        ?? Keyboard.new($lines, $line-style)
        !! $resource
        ?? Keyboard.new(%?RESOURCES{$resource}.IO.lines, $line-style)
        !! die "Moo"
    ;
    my %kk;
    for $keyboard.key-def.list -> $kd {
        note "$kd.name - ", $kd.nums.join: '.';
        %kk{Buf.new(|$kd.nums).decode} = $kd.name;
    }
    return self.bless: :$keyboard, :%kk;
}

# --------------------------------------------------------------------
method read-key {

    $want-tty-state.setattr(:DRAIN) if $in-terminal;
    LEAVE {$orig-tty-state.setattr(:NOW) if $in-terminal};

    my Supplier $supplier .= new;
    my $done = False;
    my $supply = $supplier.Supply.on-close: { $done = True };

    my $char;
    start {
        until $done {
            my $char = $*IN.read(10).decode;
            $supplier.emit: $char;
        }
    }
    react {
        whenever $supply {
            $char = $_;
            done();
        }
    }

    return %!kk{$char} || (
        $char.substr(0, 1) eq Buf.new(27).decode
            ?? $char.ords
            !! $char
        )
    ;

}

