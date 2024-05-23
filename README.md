# CVBasic compiler v0.5.1
*(c) Copyright 2024 Óscar Toledo Gutiérrez*
*https://nanochess.org/*

BASIC language cross-compiler for the Colecovision/SG1000/MSX.

    CVBasic.c               The CVBasic compiler C language source code
    LICENSE                 Source code license

    cvbasic_prologue.asm    Prologue file needed for compiled programs.
    cvbasic_epilogue.asm    Epilogue file needed for compiled programs.

    manual.txt              English manual for CVBasic

    README.md               This file


### Usage guide

Using CVBasic to compile a Colecovision program:

    cvbasic game.bas game.asm
    gasm80 game.asm -o game.rom -l game.lst

You need to assemble the output file using Gasm80 available from [http://github.com/nanochess/gasm80](http://github.com/nanochess/gasm80)

Using CVBasic to compile a Sega SG1000 program:

    cvbasic --sg1000 game.bas game.asm

Using CVBasic to compile a MSX program:

    cvbasic --msx game.bas game.asm

Using CVBasic to compile a Colecovision Super Game Module program:

    cvbasic --sgm game.bas game.asm


### Notes

The current official version is v0.5.1.

MSX controller support only handles the two joysticks and keyboard arrows (plus Space and M for buttons).

The Sega SG1000 doesn't have any keypad, so CONT1.KEY and CONT2.KEY aren't operative, but the support includes compatibility with Sega SC3000 computer, and the keyboard can be used as first controller (code contributed by SiRioKD)


### Acknowledgments

Thanks to the following members of Atariage for contributing valuable suggestions:

    abeker
    aotta
    ARTRAG
    atari2600land
    carlsson
    CrazyBoss
    drfloyd
    gemintronic
    Jess Ragan
    Kamshaft
    Kiwi
    pixelboy
    SiRioKD
    Tarzilla
    Tony Cruise
    youki

### Supporting the developer

If you find CVBasic useful, please show your appreciation making a donation via Paypal ($9 USD suggested) to b-i+y-u+b-i (at) gmail.com

If you find a bug, please report to same email and I'll try to look into it. Because lack of time I cannot guarantee it will be corrected.

You can also get the book **Programming Games for Colecovision**, a book version of the manual, and includes an introductory course to game programming with full examples and source code: Game of Ball, Monkey moon, Space Raider, Bouncy Cube, and Dungeon Warrior.

The foreword is written by David R. Megarry, programmer of Zaxxon™ for Colecovision, and creator of the Dungeon!™ Board game.

* [Programming Games for Colecovision, paperback, 250 pages](https://www.lulu.com/shop/oscar-toledo-gutierrez/programming-games-for-colecovision/paperback/product-95qvzj8.html?page=1&pageSize=4)
* [Programming Games for Colecovision, hardcover, 250 pages](https://www.lulu.com/shop/oscar-toledo-gutierrez/programming-games-for-colecovision/hardcover/product-84nm767.html?page=1&pageSize=4)
* [Programming Games for Colecovision, PDF ebook, 250 pages](https://nanochess.org/store.html)
