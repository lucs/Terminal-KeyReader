unit class Terminal::KeyReader:ver<0.1.1>:auth<zef:lucs>;

# --------------------------------------------------------------------
#`(
    Holds what is known about a key press.

    For example, pressing ‹Shift Tab› sends the keycodes <27 91 90> to
    the keyboard buffer. How do we know this? Welp, I checked and
    noted it in a resource file.

    The constructor takes the key name and the keycodes, in a string
    formatted like "⟨name⟩ ¦ ⟨kcod⟩", ⦃"Shift Tab ¦ 27 91 90"⦄.
)

class KeyDef {
        
    has $.name; # ⦃"ShiftTab"⦄
    has $.root; # ⌊"Tab"⌉
    has $.ctrl; # ⌊False⌉
    has $.altt; # ⌊False⌉
    has $.shft; # ⌊True⌉

        # The keycodes ⦃(27, 91, 90)⦄.
    has @.kcod;

        # ⦃"027091090000000000000"⦄, used for sorting.
    has $.rank;

    method new (
            # "⟨name⟩ ¦ ⟨kcod⟩", ⦃"Shift Tab ¦ 27 91 90"⦄.
        $name-kcod
    ) {
        $name-kcod ~~ /
            ^ \s*
            $<name> = [ .*? ] \s* '¦' \s*
            $<kcod> = [ .*? ]
            \s* $
        /;
        my $name = ~$/<name>;
        my @kcod = $/<kcod>.comb: /\d+/;
        $name ~~ s:g/ \s //;

            # To help sorting.
            #   ⦃127⦄        : <127000000000000000000>
            #   ⦃27, 3, 126⦄ : <027003126000000000000>
        my $rank = sprintf(
            '<%-21s>',
            @kcod.map({sprintf '%03d', $_}).join,
        ).subst(' ', "0", :g);

        return self.bless:
            :$name,
            :@kcod,
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
#`(
    Holds what is known about a keyboard's key definitions.

    The constructor takes
)

class Keyboard {

    has @.key-def;
    has %.kcod-to-name;

    method new ($name-kcod-lines) {
        my @key-def;
        for $name-kcod-lines.lines -> $name-kcod {
            next if $name-kcod ~~ /^ \s* ['#' | $] /;
            @key-def.push: KeyDef.new: $name-kcod;
        }
        my %kcod-to-name;
        for @key-def -> $kdef {
            my $kcod = Buf.new($kdef.kcod.map(*.Int)).decode;
            %kcod-to-name{$kcod} = $kdef.name;
        }
        return self.bless: :@key-def, :%kcod-to-name;
    }

    method display (
            # {$^a.rank cmp $^b.rank}
        &sort-how,

            # -> $kdef { "{$kdef.name}: {$kdef.kcod.join('.')} }
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

has Keyboard $.kbd;

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

method new (
    :$resource = 'us',
    :$name-kcod-file,
) {
    my $name-kcod-lines = '';
    
    if $resource {
        $name-kcod-lines ~= %?RESOURCES{"$resource.layout"}.absolute.IO.slurp;
    }
    if $name-kcod-file {
        $name-kcod-lines ~= $name-kcod-file.IO.slurp;
    }

   # note $name-kcod-lines;
    my $kbd = Keyboard.new($name-kcod-lines);
    return self.bless: :$kbd;
}

# --------------------------------------------------------------------
method read-key {

    $want-tty-state.setattr(:DRAIN) if $in-terminal;
    LEAVE {$orig-tty-state.setattr(:NOW) if $in-terminal};

    my Supplier $supplier .= new;
    my $done = False;
    my $supply = $supplier.Supply.on-close: { $done = True };

    my $kcod;
    start {
        until $done {
            my $kcod = $*IN.read(10).decode;
            $supplier.emit: $kcod;
        }
    }
    react {
        whenever $supply {
            $kcod = $_;
            done();
        }
    }

    return $!kbd.kcod-to-name{$kcod} || ~$kcod.ords;

   # Alt Pgdn            ¦ 27 91 54 59 51 126

   #     # Not sure what this old code was about.
   # return %!kcod-to-name{$kcod} || (
   #     $kcod.substr(0, 1) eq Buf.new(27).decode
   #         ?? $kcod.ords
   #         !! "⟨$kcod⟩"
   #     )
   # ;

}

