unit class Terminal::KeyReader;

use Debugging::Tool;
my $dt = Debugging::Tool.new;

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
        
    has $.name; # ⦃"Shift Tab"⦄
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
        $str
    ) {
        $str ~~ /
            ^ \s*
            $<name> = [ .*? ] \s* '¦' \s*
            $<kcod> = [ .*? ]
            \s* $
        /;
        my $name = $/<name>;
        my @kcod = $/<kcod>.comb: /\d+/;

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

    The constructor takes the key name and the keycodes, in a string
    formatted like "⟨name⟩ ¦ ⟨kcod⟩", ⦃"Shift Tab ¦ 27 91 90"⦄.
)

class Keyboard {

    has @.key-def;

    method new ($lines) {
        my @key-def;
        for $lines.list -> $line {
            next if $line ~~ /^ \s* ['#' | $] /;
            @key-def.push: KeyDef.new: $line;
        }
        return self.bless: :@key-def;
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

has Keyboard $!kbd;
has %.kk;

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

method new (:$resource = 'us', :$lines) {
   # note %?RESOURCES{$resource}.IO.slurp;
    my $kbd = $lines ?? Keyboard.new($lines)
        !! $resource
        ?? Keyboard.new(%?RESOURCES{$resource}.IO.lines)
        !! Keyboard.new('')
    ;
    my %kk;
    for $kbd.key-def.list -> $kdef {
       # $dt.put: "{$kdef.name} - ", $kdef.kcod.join: '.';
        %kk{Buf.new($kdef.kcod.map(*.Int)).decode} = $kdef.name;
    }
    return self.bless: :$kbd, :%kk;
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

    return %!kk{$char} || $char.ords;

   # return %!kk{$char} || (
   #     $char.substr(0, 1) eq Buf.new(27).decode
   #         ?? $char.ords
   #         !! "⟨$char⟩"
   #     )
   # ;

}

