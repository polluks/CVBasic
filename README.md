# CVBasic compiler v0.2.0
*(c) Copyright 2024 Óscar Toledo Gutiérrez*
*https://nanochess.org/*

BASIC language cross-compiler for the Colecovision.

    CVBasic.c               The CVBasic compiler C language source code
    LICENSE                 Source code license

    cvbasic_prologue.asm    Prologue file needed for compiled programs.
    cvbasic_epilogue.asm    Epilogue file needed for compiled programs.

    manual.txt              English manual for CVBasic

    README.md               This file


### Usage guide

    cvbasic game.bas game.asm
    gasm80 game.asm -o game.rom -l game.lst

You need to assemble the output file using Gasm80 available from [http://github.com/nanochess/gasm80](http://github.com/nanochess/gasm80)


### Notes

The current official version is v0.2.0.


### Acknowledgments

Thanks to the following member of Atariage for contributing valuable suggestions:

    gemintronic
    Kiwi
    pixelboy
    youki

### Supporting the developer

If you find CVBasic useful, please show your appreciation making a donation via Paypal ($9 USD suggested) to b-i+y-u+b-i (at) gmail.com

If you find a bug, please report to same email and I'll try to look into it. Because lack of time I cannot guarantee it will be corrected.
