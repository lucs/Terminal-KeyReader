[![Actions Status](https://github.com/lucs/Terminal-KeyReader/actions/workflows/test.yml/badge.svg)](https://github.com/lucs/Terminal-KeyReader/actions)

NAME
====

    Terminal::KeyReader - Read key presses from the keyboard buffer

SYNOPSIS
========

    use Terminal::KeyReader;

    my $TKR = Terminal::KeyReader.new;

DESCRIPTION
===========

I wrote Terminal::KeyReader because in some other program I wanted to be able to know which key a user had pressed and act based on that.

Works for US keyboards, but resource files can be constructed for other ones.

AUTHOR
======

Luc St-Louis <lucs@pobox.com>

COPYRIGHT AND LICENSE
=====================

Copyright 2023 Luc St-Louis

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

