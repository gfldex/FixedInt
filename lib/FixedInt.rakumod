unit class FixedInt:ver<0.0.1>:auth<github:thundergnat>;
has $.var handles <Str Numeric gist> = 0;
has $.bits;
has $.mask;

submethod BUILD (Int :$var = 0, Int :bits(:$bit) = 32) { $!var = $var; $!bits = $bit; $!mask = 2**$!bits - 1 }

# method STORE ($val) { $!var = $val +& $!mask }

# rotate right
method ror (Int $bits) { 
    self.clone(:var(
        $!var +> $bits +| ($!var +& (2**$bits - 1) +< ($!bits - $bits))
    ))
}

# rotate left
method rol (Int $bits) { 
    self.clone(:var(
        (($!var +< $bits) +& $!mask ) +| ($!var +> ($!bits - $bits))
    ))
}

# ones complement
method C1 { 
    self.clone(:var(
        $!mask +^ $!var 
    ))
}

# twos complement
method C2 { 
    self.clone(:var(
        $!mask +^ $!var + 1 
    ))
}

# treat the fixed-sized int as a signed int and return the "signed" value.
method signed {
    self.clone(:var(
        ($!var +& 2**($!bits - 1)) ??
        -(($!var +& ($!mask +> 1)) +^ ($!mask +> 1) + 1) !!
        $!var
    ))
}

# return a binary formatted IntStr
method bin { "0b{$!var.Str.fmt('%0' ~ $!bits ~ 'b')}" }

# return an octal formatted IntStr
method oct { "0o{$!var.Str.fmt('%0' ~ ceiling($!bits / 3) ~ 'o')}" }

# return a hex formatted IntStr
method hex { "0x{$!var.Str.fmt('%0' ~ ceiling($!bits / 4) ~ 'X')}" }

multi sub infix:<->(FixedInt:D \l, Numeric:D \r --> FixedInt ) is rw is export { FixedInt.new: :var((l.var - r) +& l.mask), :bits(l.bits), :mask(l.mask) }
multi sub infix:<+>(FixedInt:D \l, Numeric:D \r --> FixedInt ) is rw is export { FixedInt.new: :var((l.var + r) +& l.mask), :bits(l.bits), :mask(l.mask) }

multi sub infix:«+>»(FixedInt:D \l, Numeric:D \r --> FixedInt ) is rw is export { FixedInt.new: :var((l.var +> r) +& l.mask), :bits(l.bits), :mask(l.mask) }
multi sub infix:«+<»(FixedInt:D \l, Numeric:D \r --> FixedInt ) is rw is export { FixedInt.new: :var((l.var +< r) +& l.mask), :bits(l.bits), :mask(l.mask) }

=begin pod

=head1 NAME

FixedInt - Unsigned fixed sized Integers

[![Build Status](https://travis-ci.org/thundergnat/FixedInt.svg?branch=master)](https://travis-ci.org/thundergnat/FixedInt)

=head1 SYNOPSIS

=begin code :lang<raku>

use FixedInt;

my \fixedint = FixedInt.new(:8bit);

say fixedint; # 0

say fixedint -= 12;   # 244
say fixedint.signed;  # -12
say fixedint.bin;     # 0b11110100
say fixedint.hex;     # 0xF4

say fixedint += 2500; # 184
say fixedint.signed;  # -72
say fixedint.bin;     # 0b10111000
say fixedint.hex;     # 0xB8

=end code

=head1 DESCRIPTION

FixedInt provides an easy way to work with fixed-sized unsigned integer in Raku.
Rakus Integers by default are unfixed, arbitrary size. Doing unsigned fixed-size
bitwise operations requires a bunch of extra bookkeeping. This module hides that
bookkeeping behind an interface.

One major caveat to be aware of when using this module. The class instance
B<may not> be instantiated in a $ sigiled variable.

Raku $ sigiled scalar variables do not implement a STORE method, but instead
do direct assignment; and there doesn't seem to be any easy way to override that
behaviour.

An implication of that is that classes that B<do> implement a STORE method can
not be held in a $ sigiled variable. (Well, they B<can>, they just won't work
correctly. The first time you try to store a new value, the entire class
instance will be overwritten and disappear.)

The only way to instantiate a class in a scalar that won't get overwritten when
STOREed to is to use an unsigiled variable.

The FixedInt module allows creating and working with B<any> sized fixed size
Integer. Not only the "standard" sizes: 8, 16, 32, 64, etc., but also: 11, 25,
103, whatever. Once instantiated, it can be treated like any other variable. You
can add to it, subtract from it, multiply, divide, whatever; the value stored in
the variable will always stay the specified bit size. Any excesses will "roll
over" the value. Works correctly for any standard bitwise or arithmatic
operator, though you must remember to assign to the variable to get the fixed
sized properties.

Provides some bit-wise operators that don't make sense for non-fixed size
integers. Provides a few "format" operators that return a formatted IntStr;
useful for display but also directly usable as an integer value.



=head2 Methods

Note that most of the method examples below show binary representations of the
value, that is just for demonstration purposes, returns decimal numbers by
default.  All of the method examples below assume an 8 bit fixedint.


=head3 .new()

Specify the number of bits. May be any positive integer. Defaults to 32. Accepts
:bit or :bits. Defaults to 0; will not accept a Nil value.

=begin code :lang<raku>
    my \fixedint = FixedInt.new(:8bit);

    # or

    my \fixedint = FixedInt.new(:bits(8));

    # or

    my \fixedint = FixedInt.new(bits => 8);
=end code


=head3 .ror (Int $bits)

Rotate right by the given number of bits
=begin code :lang<raku>
    # before 00000011 (3)
    fixedint.=ror(1);
    # after 10000001  (129)
=end code

=head3 .rol (Int $bits)

Rotate left by the given number of bits

=begin code :lang<raku>
    # before 10000001 (129)
    fixedint.=rol(3);
    # after 00001100 (12)
=end code

=head3 .C1

Ones complement. Every bit is negated.

=begin code :lang<raku>
    # before 00001100 (12)
    fixedint.=C1;
    # after 11110011  (243)
=end code

=head3 .C2

Twos complement. A "negated" integer.

=begin code :lang<raku>
    # before 00001100 (12)
    fixedint.=C2;
    # after 11110100 (244)
=end code

=head3 .signed

Treats the fixed size unsigned integer as a signed integer, returns negative
numbers for FixedInts with a set most significant bit.

=begin code :lang<raku>
    say fixedint        # 244
    say fixedint.signed # -12
=end code

=head3 .bin

Returns a binary formatted IntStr;
=begin code :lang<raku>
    say fixedint     # 244
    say fixedint.bin # 0b11110100
=end code

=head3 .oct

Returns a octal formatted IntStr;
=begin code :lang<raku>
    say fixedint     # 244
    say fixedint.oct # 0o0364
=end code

=head3 .hex

Returns a hex formatted IntStr;
=begin code :lang<raku>
    say fixedint     # 244
    say fixedint.hex # 0xF4
=end code



=head1 AUTHOR

Steve Schulze (thundergnat)

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Steve Schulze

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
