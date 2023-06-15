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

    method new (
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

            # To help sorting.
            #   ⦃127⦄        : <127000000000000000000>
            #   ⦃27, 3, 126⦄ : <027003126000000000000>
        my $rank = sprintf(
            '<%-21s>',
            @nums.map({sprintf '%03d', $_}).join,
        ).subst(' ', "0", :g);

        return self.bless:
            :$name,
            :@nums,
            :$rank,
            :root($name
                .subst('Ctrl')
                .subst('Alt')
                .subst('Shift')
                .subst(' ', :g)
            ),
            :ctrl($name ~~ /Ctrl/),
            :altt($name ~~ /Alt/),
            :shft($name ~~ /Shift/),
       ;
    }

}

# --------------------------------------------------------------------
class Keyboard {

    has @.key-def;

    method new ($lines, $line-style) {
       # note "\$lines has {$lines.chars} chars.";
        my @key-def;
        for $lines.list -> $line {
            next if $line ~~ /^ \s* ['#' | $] /;
           # note "LINE <$line>";
            @key-def.push: KeyDef.new: $line;
        }
        return self.bless: :@key-def;
    }

    method add (KeyDef $key-def) {
        @!key-def.push: $key-def;
    }

    method display (
            # {$^a.rank cmp $^b.rank}
        &sort-how,

            # -> $kdef { "{$kdef.name}: {$kdef.nums.join('.')} }
        &show-how,
    ) {
        my @sorted_key-def = sort {
            &sort-how($^a, $^b)
        }, @.key-def;
        my $ret-str;
        for @sorted_key-def -> $kdef {
            $ret-str ~= &show-how($kdef);
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
has $akeyboard;
has %.kk;

method new (:$resource = 'us', :$line-style = 's1', :$lines) {
   # note %?RESOURCES{$resource}.IO.slurp;
    my $keyboard = $lines
        ?? Keyboard.new($lines, $line-style)
        !! $resource
        ?? Keyboard.new(%?RESOURCES{$resource}.IO.lines, $line-style)
        !! Keyboard.new('', $line-style)
    ;
    my %kk;
    for $keyboard.key-def.list -> $kdef {
        note "{$kdef.name} - ", $kdef.nums.join: '.';
        %kk{Buf.new($kdef.nums.map(*.Int)).decode} = $kdef.name;
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

