	;
	; CVBasic prologue (BASIC compiler, 6502 target)
	; C64 version
	;
	; by Oscar Toledo G.
	; https://nanochess.org/
	;
	; Creation date: May/31/2026.
	;

	CPU 6502

	;
	; C64 PRG header
	;
	FORG $0000

	; PRG load address
	DW $0801

	; Set file offset to skip past PRG header, match memory address
	FORG $0002
	ORG $0801

	; BASIC SYS stub
	DW $080C        ; Next BASIC line pointer
	DW 10
	DB $9e          ; BASIC token for SYS
	DB " 2064"      ; SYS 2064 → $0810 → JMP START
	DB $00          ; End of line
	DB $00,$00      ; End of BASIC program

	; Jump to the actual program start (BASIC SYS calls $080E)
	JMP START

	;
	; CVBasic variables in zero page.
	;
temp:		equ $02
temp2:		equ $04
result:		equ $06
pointer:	equ $08

read_pointer:	equ $0a
cursor:		equ $0c
mode:		equ $0e
ntsc:		equ $0f

vdp_status:	equ $10
flicker:	equ $11
frame:		equ $12
scroll_x:	equ $18
scroll_y:	equ $1a

joy1_data:	equ $20
joy2_data:	equ $21
key1_data:	equ $22
key2_data:	equ $23
sprite_data:	equ $24

	IF CVBASIC_MUSIC_PLAYER
music_playing:		EQU $4f
music_bank:		EQU $30
music_timing:		EQU $31
music_start:		EQU $32
music_pointer:		EQU $34
music_note_counter:	EQU $36
music_instrument_1:	EQU $37
music_note_1:		EQU $38
music_counter_1:	EQU $39
music_instrument_2:	EQU $3a
music_note_2:		EQU $3b
music_counter_2:	EQU $3c
music_instrument_3:	EQU $3d
music_note_3:		EQU $3e
music_counter_3:	EQU $3f
music_drum:		EQU $40
music_counter_4:	EQU $41
audio_freq1:		EQU $42
audio_freq2:		EQU $44
audio_freq3:		EQU $46
audio_vol1:		EQU $48
audio_vol2:		EQU $49
audio_vol3:		EQU $4a
audio_vol4hw:		EQU $4b
audio_noise:		EQU $4c
music_tick:		EQU $4d
music_mode:		EQU $4e
	ENDIF

	;
	; C64 hardware register equates
	;
VIC:		EQU $D000
SID:		EQU $D400
CI1:		EQU $DC00
CI2:		EQU $DD00

	;
	; Screen memory and color memory
	;
SCREEN_MEM:	EQU $C400
COLOR_MEM:	EQU $D800

	;
	; WRTVRM - Write to memory (C64 is memory-mapped)
	; Input: A = value, XY = address
	;
WRTVRM:
	PHA
	TXA
	LDY #0
	STA pointer
	STY pointer+1
	PLA
	STA (pointer),Y
	RTS

	;
	; Translate ColecoVision VRAM addresses ($1800-$1Axx) to C64 screen ($C400-$C6xx)
	; Operates on temp/temp+1 for VPOKE inline code
	;
vram_translate:
	LDA temp+1
	CMP #$18
	BCC .vtdone
	CMP #$1C
	BCS .vtdone
	CLC
	ADC #$AC
	STA temp+1
.vtdone:
	RTS

SETRD:
	; Translate $18xx-$1Bxx -> $C4xx-$C7xx for VPEEK
	CPY #$18
	BCC .sd_store
	CPY #$1C
	BCS .sd_store
	TYA
	CLC
	ADC #$AC
	TAY
.sd_store:
	STA pointer
	STY pointer+1
	RTS

RDVRM:
	JSR SETRD
	LDY #0
	LDA (pointer),Y
	RTS

	;
	; define_sprite - Copy sprite bitmap data to VIC bank
	; Input: A=count, pointer=sprite_num, temp=source addr
	;
define_sprite:
	STA temp2
	LDA #0
	STA temp2+1
	LDA #$C0
	STA pointer+1
	LDA pointer
	ASL A
	ROL pointer+1
	ASL A
	ROL pointer+1
	ASL A
	ROL pointer+1
	ASL A
	ROL pointer+1
	ASL A
	ROL pointer+1
	ASL A
	ROL pointer+1
	STA pointer
	LDA temp2
	ASL A
	ROL temp2+1
	ASL A
	ROL temp2+1
	ASL A
	ROL temp2+1
	ASL A
	ROL temp2+1
	ASL A
	ROL temp2+1
	ASL A
	ROL temp2+1
	STA temp2
	JSR LDIRVM
	RTS

	;
	; define_char - Copy character pattern data to RAM charset
	; Input: A=count, pointer=char_num, temp=source addr
	;
define_char:
	STA temp2
	LDA #0
	STA pointer+1
	STA temp2+1
	LDA pointer
	ASL A
	ROL pointer+1
	ASL A
	ROL pointer+1
	ASL A
	ROL pointer+1
	STA pointer
	LDA temp2
	ASL A
	ROL temp2+1
	ASL A
	ROL temp2+1
	ASL A
	ROL temp2+1
	STA temp2
	CLC
	LDA pointer
	ADC #$00
	STA pointer
	LDA pointer+1
	ADC #$C8
	STA pointer+1
	JSR LDIRVM
	RTS

	;
	; define_color - Color definition (no-op on C64, colors are per-position)
	;
define_color:
	RTS

	;
	; LDIRVM - Copy data to screen (simplified, no buffering needed)
	; Input: pointer=destination, temp=source, temp2=length
	;
LDIRVM:
	LDY #0
	LDA temp
	STA read_pointer
	LDA temp+1
	STA read_pointer+1
.1:
	LDA (read_pointer),Y
	STA (pointer),Y
	INC read_pointer
	BNE .2
	INC read_pointer+1
.2:
	INC pointer
	BNE .3
	INC pointer+1
.3:
	LDA temp2
	BNE .4
	DEC temp2+1
.4:
	DEC temp2
	LDA temp2
	ORA temp2+1
	BNE .1
	RTS

	;
	; Enable screen (no-op on C64 - screen is always on unless we disable it)
	;
ENASCR:
	LDA $D011
	AND #$EF	; Clear bit 4 to enable screen
	STA $D011
	RTS

	;
	; Disable screen
	;
DISSCR:
	LDA $D011
	ORA #$10	; Set bit 4 to disable screen
	STA $D011
	RTS

	;
	; CPYBLK - Copy screen block (used by SCREEN statement)
	;
CPYBLK:
.1:
	LDA temp2
	PHA
	LDA temp2+1
	PHA
	TXA
	PHA
	TYA
	PHA
	LDA temp
	PHA
	LDA temp+1
	PHA
	LDA #0
	STA temp2+1
	JSR LDIRVM
	PLA
	STA temp+1
	PLA
	STA temp
	PLA
	STA temp2+1
	PLA
	STA temp2
	LDA temp
	CLC
	ADC temp2
	STA temp
	LDA temp+1
	ADC temp2+1
	STA temp+1
	LDX temp2
	LDY temp2+1
	PLA
	STA temp2+1
	PLA
	STA temp2
	LDA pointer
	CLC
	ADC #$28	; 40 bytes per row (C64 screen width)
	STA pointer
	LDA pointer+1
	ADC #$00
	STA pointer+1
	DEC temp2+1
	BNE .1
	RTS

	;
	; CLS - Clear screen
	;
cls:
	LDA #$20	; Space character
	LDX #0
.1:
	STA SCREEN_MEM,X
	STA SCREEN_MEM+256,X
	STA SCREEN_MEM+512,X
	STA SCREEN_MEM+768,X
	INX
	BNE .1
	LDA #$01	; White on blue
	LDX #0
.2:
	STA COLOR_MEM,X
	STA COLOR_MEM+256,X
	STA COLOR_MEM+512,X
	STA COLOR_MEM+768,X
	INX
	BNE .2
	RTS

	;
	; Update sprite
	; A = sprite number (0-7)
	;
update_sprite:
	STA pointer	; Save sprite number
	ASL A
	TAY		; Y = sprite_number * 2 (offset for X/Y registers)

	; Y coordinate: $D001 + n*2
	LDA sprite_data+1
	STA $D001,Y

	; X coordinate: $D000 + n*2, with MSB in $D010
	LDA sprite_data+2
	STA $D000,Y
	; Clear MSB bit for this sprite in $D010
	; (CVBasic X is 8-bit, so MSB is always 0)
	LDA pointer	; Sprite number as bit mask
	TAX
	LDA bit_mask,X
	EOR #$FF
	AND $D010
	STA $D010

	; Color: $D027 + n (single byte offset)
	LDY pointer
	LDA sprite_data+3
	STA $D027,Y

	; Sprite data pointer: $C7F8 + n (screen_base + $3F8)
	LDA sprite_data+0
	STA $C7F8,Y
	RTS

bit_mask:
	db $01,$02,$04,$08,$10,$20,$40,$80

_abs16:
	PHA
	TYA
	BPL _neg16.1
	PLA
_neg16:
	EOR #$FF
	CLC
	ADC #1
	PHA
	TYA
	EOR #$FF
	ADC #0
	TAY
.1:
	PLA
	RTS

_sgn16:
	STY temp
	ORA temp
	BEQ .1
	TYA
	BMI .2
	LDA #0
	TAY
	LDA #1
	RTS

.2:	LDA #$FF
.1:	TAY
	RTS

_read16:
	JSR _read8
	PHA
	JSR _read8
	TAY
	PLA
	RTS

_read8:
	LDY #0
	LDA (read_pointer),Y
	INC read_pointer
	BNE .1
	INC read_pointer+1
.1:
	RTS

_peek8:
	STA pointer
	STY pointer+1
	LDY #0
	LDA (pointer),Y
	RTS

_peek16:
	STA pointer
	STY pointer+1
	LDY #0
	LDA (pointer),Y
	PHA
	INY
	LDA (pointer),Y
	TAY
	PLA
	RTS

	; 16-bit multiplication.
_mul16:
	STA temp2
	STY temp2+1
	LDA #0
	STA result
	TAY
	LDX #7
.1:
	LSR temp2
	BCC .2
	LDA result
	CLC
	ADC temp
	STA result
	TYA
	ADC temp+1
	TAY
.2:	ASL temp
	ROL temp+1
	DEX
	BPL .1
	TYA
	LDX #7
.3:
	LSR temp2+1
	BCC .4
	CLC
	ADC temp+1
.4:	ASL temp+1
	DEX
	BPL .3
	TAY
	LDA result
	RTS

	; 16-bit signed modulo.
_mod16s:
	STA temp2
	STY temp2+1
	LDY temp2+1
	PHP
	BPL .1
	LDA temp2
	JSR _neg16
	STA temp2
	STY temp2+1
.1:
	LDY temp+1
	BPL .2
	LDA temp
	JSR _neg16
	STA temp
	STY temp+1
.2:
	JSR _mod16.1
	PLP
	BPL .3
	JMP _neg16
.3:
	RTS

	; 16-bit signed division.
_div16s:
	STA temp2
	STY temp2+1
	LDA temp+1
	EOR temp2+1
	PHP
	LDY temp2+1
	BPL .1
	LDA temp2
	JSR _neg16
	STA temp2
	STY temp2+1
.1:
	LDY temp+1
	BPL .2
	LDA temp
	JSR _neg16
	STA temp
	STY temp+1
.2:
	JSR _div16.1
	PLP
	BPL .3
	JMP _neg16
.3:
	RTS

_div16:
	STA temp2
	STY temp2+1
.1:
	LDA #0
	STA result
	STA result+1
	LDX #15
.2:
	ROL temp2
	ROL temp2+1
	ROL result
	ROL result+1
	LDA result
	SEC
	SBC temp
	TAY
	LDA result+1
	SBC temp+1
	BCC .3
	STY result
	STA result+1
.3:	DEX
	BPL .2
	ROL temp2
	ROL temp2+1
	LDA temp2
	LDY temp2+1
	RTS

_mod16:
	STA temp2
	STY temp2+1
.1:
	LDA #0
	STA result
	STA result+1
	LDX #15
.2:
	ROL temp2
	ROL temp2+1
	ROL result
	ROL result+1
	LDA result
	SEC
	SBC temp
	STA result
	LDA result+1
	SBC temp+1
	STA result+1
	BCS .3
	LDA result
	ADC temp
	STA result
	LDA result+1
	ADC temp+1
	STA result+1
	CLC
.3:
	DEX
	BPL .2
	LDA result
	LDY result+1
	RTS

	; Random number generator.
random:
	LDA lfsr
	ORA lfsr+1
	BNE .0
	LDA #$11
	STA lfsr
	LDA #$78
	STA lfsr+1
.0:	LDA lfsr+1
	ROR A	
	ROR A		
	ROR A		
	EOR lfsr+1	
	STA temp
	LDA lfsr+1
	ROR A
	ROR A
	EOR temp
	STA temp
	LDA lfsr
	ASL A
	ASL A
	EOR temp
	ROL A
	ROR lfsr+1
	ROR lfsr
	LDA lfsr
	LDY lfsr+1
	RTS

lfsr:		equ $1e

wait:
	LDA frame
.1:
	CMP frame
	BEQ .1
	RTS

print_string_cursor_constant:
	PLA
	STA temp
	PLA
	STA temp+1
	LDY #1
	LDA (temp),Y
	STA cursor
	INY
	LDA (temp),Y
	STA cursor+1
	INY
	LDA (temp),Y
	STA temp2
	TYA
	CLC
	ADC temp
	STA temp
	BCC $+4
	INC temp+1
	LDA temp2
	BNE print_string.2

print_string_cursor:
	STA cursor
	STY cursor+1
print_string:
	PLA
	STA temp
	PLA
	STA temp+1
	LDY #1
	LDA (temp),Y
	STA temp2
	INC temp
	BNE $+4
	INC temp+1
.2:	CLC
	ADC temp
	TAY
	LDA #0
	ADC temp+1
	PHA
	TYA
	PHA
	INC temp
	BNE $+4
	INC temp+1
	LDA cursor
	STA pointer
	LDA cursor+1
	AND #$07	; Map to screen memory $C400-$C7FF
	ORA #$C4
	STA pointer+1
	LDY #0
.3:
	LDA (temp),Y
	STA (pointer),Y
	INY
	DEC temp2
	BNE .3
	LDA temp2
	CLC
	ADC cursor
	STA cursor
	BCC .4
	INC cursor+1
.4:
	RTS

print_number:
	LDX #0
	STX temp
	SEI
print_number5:
	LDX #10000
	STX temp2
	LDX #10000/256
	STX temp2+1
	JSR print_digit
print_number4:
	LDX #1000
	STX temp2
	LDX #1000/256
	STX temp2+1
	JSR print_digit
print_number3:
	LDX #100
	STX temp2
	LDX #0
	STX temp2+1
	JSR print_digit
print_number2:
	LDX #10
	STX temp2
	LDX #0
	STX temp2+1
	JSR print_digit
print_number1:
	LDX #1
	STX temp2
	STX temp
	LDX #0
	STX temp2+1
	JSR print_digit
	CLI
	RTS

print_digit:
	LDX #$2F
.2:
	INX
	SEC
	SBC temp2
	PHA
	TYA
	SBC temp2+1
	TAY
	PLA
	BCS .2
	CLC
	ADC temp2
	PHA
	TYA
	ADC temp2+1
	TAY
	PLA
	CPX #$30
	BNE .3
	LDX temp
	BNE .4
	RTS

.4:	DEX
	BEQ .6
	LDX temp+1
	BNE print_char
.6:
	LDX #$30
.3:	PHA
	LDA #1
	STA temp
	PLA

print_char:
	PHA
	TYA
	PHA
	LDA cursor
	STA pointer
	LDA cursor+1
	AND #$07
	ORA #$C4
	STA pointer+1
	PLA
	TAY
	PLA
	LDY #0
	STA (pointer),Y
	INC cursor
	BNE .1
	INC cursor+1
.1:
	RTS

mode_0:
	JSR cls
clear_sprites:
	LDA #$F0
	LDX #0
.1:
	STA $D000,X	; Clear sprite Y coordinates
	INX
	CPX #$10
	BNE .1
	RTS

music_init:
	LDA #$00
	STA $D418	; SID volume
	STA $D404	; Voice 1 control off
	STA $D40B	; Voice 2 control off
	STA $D412	; Voice 3 control off
    if CVBASIC_MUSIC_PLAYER
    else	
	RTS
    endif

    if CVBASIC_MUSIC_PLAYER
	LDA #music_silence
	LDY #music_silence>>8
	;
	; Play music.
	; YA = Pointer to music.
	;
music_play:
	SEI
	STA music_pointer
	STY music_pointer+1
	LDY #0
	STY music_note_counter
	LDA (music_pointer),Y
	STA music_timing
	INY
	STY music_playing
	INC music_pointer
	BNE $+4
	INC music_pointer+1
	LDA music_pointer
	LDY music_pointer+1
	STA music_start
	STY music_start+1
	CLI
	RTS

	;
	; Generates music
	;
music_generate:
	LDA #$10
	STA audio_vol1
	STA audio_vol2
	STA audio_vol3
	STA audio_vol4hw
	LDA music_note_counter
	BEQ .1
	JMP .2
.1:
	LDY #0
	LDA (music_pointer),Y
	CMP #$fe	; End of music?
	BNE .3		; No, jump.
	LDA #0		; Keep at same place.
	STA music_playing
	RTS

.3:	CMP #$fd	; Repeat music?
	BNE .4
	LDA music_start
	LDY music_start+1
	STA music_pointer
	STY music_pointer+1
	JMP .1

.4:	LDA music_timing
	AND #$3f	; Restart note time.
	STA music_note_counter

	LDA (music_pointer),Y
	CMP #$3F	; Sustain?
	BEQ .5
	AND #$C0
	STA music_instrument_1
	LDA (music_pointer),Y
	AND #$3F
	ASL A
	STA music_note_1
	LDA #0
	STA music_counter_1
.5:
	INY
	LDA (music_pointer),Y
	CMP #$3F	; Sustain?
	BEQ .6
	AND #$C0
	STA music_instrument_2
	LDA (music_pointer),Y
	AND #$3F
	ASL A
	STA music_note_2
	LDA #0
	STA music_counter_2
.6:
	INY
	LDA (music_pointer),Y
	CMP #$3F	; Sustain?
	BEQ .7
	AND #$C0
	STA music_instrument_3
	LDA (music_pointer),Y
	AND #$3F
	ASL A
	STA music_note_3
	LDA #0
	STA music_counter_3
.7:
	INY
	LDA (music_pointer),Y
	STA music_drum
	LDA #0	
	STA music_counter_4
	LDA music_pointer
	CLC
	ADC #4
	STA music_pointer
	LDA music_pointer+1
	ADC #0
	STA music_pointer+1
.2:
	LDY music_note_1
	BEQ .8
	LDA music_instrument_1
	LDX music_counter_1
	JSR music_note2freq
	STA audio_freq1
	STY audio_freq1+1
	STX audio_vol1
.8:
	LDY music_note_2
	BEQ .9
	LDA music_instrument_2
	LDX music_counter_2
	JSR music_note2freq
	STA audio_freq2
	STY audio_freq2+1
	STX audio_vol2
.9:
	LDY music_note_3
	BEQ .10
	LDA music_instrument_3
	LDX music_counter_3
	JSR music_note2freq
	STA audio_freq3
	STY audio_freq3+1
	STX audio_vol3
.10:
	LDA music_drum
	BEQ .11
	CMP #1		; 1 - Long drum.
	BNE .12
	LDA music_counter_4
	CMP #3
	BCS .11
.15:
	LDA #$06
	STA audio_noise
	LDA #$9c
	STA audio_vol4hw
	JMP .11

.12:	CMP #2		; 2 - Short drum.
	BNE .14
	LDA music_counter_4
	CMP #0
	BNE .11
	LDA #$02
	STA audio_noise
	LDA #$9c
	STA audio_vol4hw
	JMP .11

.14:
	LDA music_counter_4
	CMP #2
	BCC .15
	ASL A
	SEC
	SBC music_timing
	BCC .11
	CMP #4
	BCC .15
.11:
	LDX music_counter_1
	INX
	CPX #$18
	BNE $+4
	LDX #$10
	STX music_counter_1

	LDX music_counter_2
	INX
	CPX #$18
	BNE $+4
	LDX #$10
	STX music_counter_2

	LDX music_counter_3
	INX
	CPX #$18
	BNE $+4
	LDX #$10
	STX music_counter_3

	INC music_counter_4
	DEC music_note_counter
	RTS

music_flute:
	LDA music_notes_table,Y
	CLC
	ADC .2,X
	PHA
	LDA music_notes_table+1,Y
	ADC #0
	TAY
	LDA .1,X
	TAX
	PLA
	RTS

.1:
	db $9a,$9c,$9d,$9d,$9c,$9c,$9c,$9c
	db $9b,$9b,$9b,$9b,$9a,$9a,$9a,$9a
	db $9b,$9b,$9b,$9b,$9a,$9a,$9a,$9a

.2:
	db 0,0,0,0,0,1,1,1
	db 0,1,1,1,0,1,1,1
	db 0,1,1,1,0,1,1,1

	;
	; Converts note to frequency.
	; Input:
	;   A = Instrument.
	;   Y = Note (1-62)
	;   X = Instrument counter.
	; Output:
	;   YA = Frequency.
	;   X = Volume.
	;
music_note2freq:
	CMP #$40
	BCC music_piano
	BEQ music_clarinet
	CMP #$80
	BEQ music_flute
	;
	; Bass instrument
	; 
music_bass:
	LDA music_notes_table,Y
	ASL A
	PHA
	LDA music_notes_table+1,Y
	ROL A
	TAY
	LDA .1,X
	TAX
	PLA
	RTS

.1:
	db $9d,$9d,$9c,$9c,$9b,$9b,$9a,$9a
	db $99,$99,$98,$98,$97,$97,$96,$96
	db $95,$95,$94,$94,$93,$93,$92,$92

music_piano:
	LDA music_notes_table,Y
	PHA
	LDA music_notes_table+1,Y
	TAY
	LDA .1,X
	TAX
	PLA
	RTS

.1:	
	db $dc,$db,$db,$da,$da,$d9,$d9,$d8
	db $d8,$d7,$d7,$d6,$d6,$d5,$d5,$d4
	db $d4,$d4,$d5,$d5,$d4,$d4,$d3,$d3

music_clarinet:
	LDA music_notes_table,Y
	CLC
	ADC .2,X
	PHA
	LDA .2,X
	BMI .3
	LDA #$00
	DB $2C
.3:	LDA #$ff
	ADC music_notes_table+1,Y
	LSR A
	TAY
	LDA .1,X
	TAX
	PLA
	ROR A
	RTS

.1:
	db $1d,$1e,$1e,$1d,$1d,$1c,$1c,$1c
	db $1b,$1b,$1b,$1b,$1c,$1c,$1c,$1c
	db $1b,$1b,$1b,$1b,$1c,$1c,$1c,$1c

.2:
	db 0,0,0,0,-1,-1,-1,0
	db 1,1,1,0,-1,-1,-1,0
	db 1,1,1,0,-1,-1,-1,0

	;
	; Musical notes table for C64 SID (PAL ~985248 Hz)
	;
	; SID frequency register = note_freq * 2^24 / SID_clock
	; For PAL (985248 Hz): SID_freq = note_freq * 16777216 / 985248
	;
music_notes_table:
	; Silence - 0
	dw 0
	; 2nd octave - Index 1 (C-2 to B-2)
	dw 1114,1180,1250,1325,1403,1487,1575,1669,1768,1874,1985,2103
	; 3rd octave - Index 13 (C-3 to B-3)
	dw 2228,2360,2500,2650,2806,2974,3150,3338,3536,3748,3970,4206
	; 4th octave - Index 25 (C-4 to B-4)
	dw 4456,4720,5000,5300,5612,5948,6300,6676,7072,7496,7940,8412
	; 5th octave - Index 37 (C-5 to B-5)
	dw 8912,9440,10000,10600,11224,11896,12600,13352,14144,14992,15880,16824
	; 6th octave - Index 49 (C-6 to B-6)
	dw 17824,18880,20000,21200,22448,23792,25200,26704,28288,29984,31760,33648
	; 7th octave - Index 61 (C-7 to D-7)
	dw 35648,37760,40000

	;
	; When the frequency upper byte is rewritten, the
	; output phase is reset, and it creates glitches.
	; So it doesn't rewrite frequency unless the note
	; changes.
	;
	;
	; Write audio to SID chip.
	; Maps internal audio_freq/vol variables to SID registers.
	;
music_hardware:
	LDA music_mode
	CMP #4		; PLAY SIMPLE?
	BCC .9		; Yes, skip channel 3 routing
	LDA audio_vol2
	AND #$0F
	BNE .9
	LDA audio_vol3
	AND #$0F
	BEQ .9
	LDA audio_vol3
	STA audio_vol2
	LDA #$10
	STA audio_vol3
	LDA audio_freq3
	LDY audio_freq3+1
	STA audio_freq2
	STY audio_freq2+1
.9:
	; Voice 1 frequency + control
	LDA audio_freq1
	STA $D400
	LDA audio_freq1+1
	STA $D401
	LDA audio_vol1
	AND #$0F
	BNE .1
	LDA #$10	; Gate off
	BNE .2
.1:
	LDA #$11	; Gate on
.2:
	STA $D404
	LDA #$09	; Attack=0, Decay=9
	STA $D405
	LDA #$F0	; Sustain=F, Release=0
	STA $D406

	; Voice 2 frequency + control
	LDA audio_freq2
	STA $D407
	LDA audio_freq2+1
	STA $D408
	LDA audio_vol2
	AND #$0F
	BNE .3
	LDA #$10
	BNE .4
.3:
	LDA #$11
.4:
	STA $D40B
	LDA #$09
	STA $D40C
	LDA #$F0
	STA $D40D

	; Voice 3 frequency + control
	; If drums are active, use voice 3 for noise instead
	LDA music_drum
	BEQ .normal_v3
	; Drum on voice 3: use noise waveform
	LDA audio_noise
	STA $D40E
	LDA #$00
	STA $D40F
	LDA audio_vol4hw
	AND #$0F
	BNE .drum_on
	LDA #$90	; Noise, gate off
	BNE .drum_ctrl
.drum_on:
	LDA #$91	; Noise, gate on
.drum_ctrl:
	STA $D412
	LDA #$00	; Attack=0, Decay=0 (no ADSR shaping)
	STA $D413
	LDA #$F0	; Sustain=F, Release=0
	STA $D414
	JMP .6

.normal_v3:
	LDA music_mode
	CMP #4
	BCC .6
	LDA audio_freq3
	STA $D40E
	LDA audio_freq3+1
	STA $D40F
	LDA audio_vol3
	AND #$0F
	BNE .5
	LDA #$10
	BNE .7
.5:
	LDA #$11
.7:
	STA $D412
	LDA #$09
	STA $D413
	LDA #$F0
	STA $D414
.6:
	LDA #$0F	; Max volume
	STA $D418
	RTS

music_silence:
	db 8
	db 0,0,0,0
	db -2
    endif

	;
	; Raster IRQ handler
	; Fires once per frame at raster line $80
	; Reads joysticks, increments frame counter, acknowledges IRQ
	;
irq_handler:
	PHA
	TXA
	PHA
	TYA
	PHA

	; Increment frame counter
	INC frame
	BNE .1
	INC frame+1
.1:
	; Read joystick 1 from CIA #1 Port A ($DC00)
	; C64 bits: 0=Up,1=Down,2=Left,3=Right,4=Fire (active-low)
	; Map to CVBasic: 0=Up,1=Right,2=Down,3=Left,6=Button
	LDA $DC00
	EOR #$FF	; Invert to active-high
	LDX #0
	LSR A		; Bit 0 -> C: Up
	BCC .j2
	TXA
	ORA #1		; Set bit 0 (Up)
	TAX
.j2:	LSR A		; Bit 1 -> C: Down
	BCC .j3
	TXA
	ORA #4		; Set bit 2 (Down)
	TAX
.j3:	LSR A		; Bit 2 -> C: Left
	BCC .j4
	TXA
	ORA #8		; Set bit 3 (Left)
	TAX
.j4:	LSR A		; Bit 3 -> C: Right
	BCC .j5
	TXA
	ORA #2		; Set bit 1 (Right)
	TAX
.j5:	LSR A		; Bit 4 -> C: Fire
	BCC .j6
	TXA
	ORA #$40	; Set bit 6 (Button)
	TAX
.j6:	STX joy1_data

	; Read joystick 2 from CIA #1 Port B ($DC01)
	LDA $DC01
	EOR #$FF
	LDX #0
	LSR A
	BCC .k2
	TXA
	ORA #1
	TAX
.k2:	LSR A
	BCC .k3
	TXA
	ORA #4
	TAX
.k3:	LSR A
	BCC .k4
	TXA
	ORA #8
	TAX
.k4:	LSR A
	BCC .k5
	TXA
	ORA #2
	TAX
.k5:	LSR A
	BCC .k6
	TXA
	ORA #$40
	TAX
.k6:	STX joy2_data

	; Acknowledge VIC-II IRQ
	LDA #$01
	STA $D019

	PLA
	TAY
	PLA
	TAX
	PLA
	RTI

irq_addr:
	DW irq_handler

sn76489_freq:
	; A = freq low byte, Y = freq high byte, X = command byte (1cc0dddd)
	STA temp
	STY temp+1
	STX temp2
	; Decode channel from command byte bits 6-5
	TXA
	AND #$60
	LSR A
	LSR A
	LSR A
	LSR A
	LSR A		; A = channel (0,1,2,3)
	ASL A		; A = channel*2
	TAX
	LDA sid_freq_lo,X
	STA pointer
	LDA sid_freq_hi,X
	STA pointer+1
	; Write frequency
	LDA temp
	LDY #0
	STA (pointer),Y
	LDA temp+1
	INY
	STA (pointer),Y
	RTS

sid_freq_lo:
	DB $00, $07, $0E, $0E
sid_freq_hi:
	DB $D4, $D4, $D4, $D4

sn76489_vol:
	; X = command byte, A = volume (inverted)
	EOR #$FF
	AND #$0F	; A = volume 0-15
	STA temp
	STX temp2
	; Decode channel from command byte bits 6-5
	TXA
	AND #$60
	LSR A
	LSR A
	LSR A
	LSR A
	LSR A		; A = channel (0,1,2,3)
	ASL A		; A = channel*2
	TAX
	LDA sid_freq_lo,X
	CLC
	ADC #4		; Control register is freq_base + 4
	STA pointer
	LDA sid_freq_hi,X
	ADC #0
	STA pointer+1
	; Set Gate based on volume
	LDA temp
	BNE .sv_on
	; Volume = 0: Gate off
	LDA #$10
	BNE .sv_done
.sv_on:
	; Volume > 0: Gate on (triangle waveform)
	LDA #$11
	; Set ADSR for quick response
	PHA
	LDY #5
	LDA #$00	; Attack=0, Decay=0
	STA (pointer),Y
	INY
	LDA #$F0	; Sustain=15, Release=0
	STA (pointer),Y
	PLA
.sv_done:
	LDY #4		; Control register offset
	STA (pointer),Y
	RTS

	;
	; Initialize C64
	;
START:
	SEI
	CLD

	; Clear zero page and variable area
	LDA #0
	TAX
.1:
	STA $02,X
	INX
	BNE .1

	; Set stack pointer
	LDX #$FF
	TXS

	; Setup VIC-II: screen at $C400, character ROM at $D000 (bank 3)
	LDA #$12	; Screen at $0400 offset, charset at $1000 offset
	STA $D018

	; Set background and border colors
	LDA #$06	; Blue background
	STA $D021
	LDA #$0E	; Light blue border
	STA $D020

	; Enable screen (clear bit 4 of $D011)
	LDA $D011
	AND #$EF
	STA $D011

	; Set VIC-II bank to bank 3 ($C000-$FFFF) for ROM charset at $D000
	LDA $DD02
	ORA #$03
	STA $DD02
	LDA $DD00
	ORA #$03
	STA $DD00

	; Copy chargen ROM to RAM at $C800 so DEFINE CHAR can modify it
	SEI
	LDA #$04
	STA $01
	LDX #$00
.cc_lp:
	LDA $D000,X
	STA $C800,X
	LDA $D100,X
	STA $C900,X
	LDA $D200,X
	STA $CA00,X
	LDA $D300,X
	STA $CB00,X
	LDA $D400,X
	STA $CC00,X
	LDA $D500,X
	STA $CD00,X
	LDA $D600,X
	STA $CE00,X
	LDA $D700,X
	STA $CF00,X
	INX
	BNE .cc_lp
	LDA #$37
	STA $01
	CLI

	; Tell VIC-II to use RAM charset at $C800 instead of ROM at $D000
	LDA $D018
	AND #$F0
	ORA #$02
	STA $D018

	; Detect PAL/NTSC using Graham's rasterline count method
	; (from https://codebase64.pokefinder.org/doku.php?id=base:detect_pal_ntsc)
	; Result: 0=NTSC, non-zero=PAL (same convention as NES prologue)
.ntsc0:
	LDA $D012
.ntsc1:
	CMP $D012
	BEQ .ntsc1
	BMI .ntsc0
	AND #$03
	CMP #$03		; PAL gives #$03
	BEQ .ntsc_pal
	LDA #$00		; NTSC
	BEQ .ntsc_done
.ntsc_pal:
	LDA #$01
.ntsc_done:
	STA ntsc

	; Install raster IRQ handler (reads joysticks, increments frame)
	; Use KERNAL indirect vector at $0314 (always RAM, no banking needed)
	LDA irq_addr
	STA $0314
	LDA irq_addr+1
	STA $0315
	LDA #$80		; Fire IRQ at raster line $80
	STA $D012
	LDA $D011
	AND #$7F		; Clear bit 7 (use $D012 value)
	STA $D011
	LDA #$01		; Enable raster IRQ
	STA $D01A
	LDA #$7F		; Acknowledge any pending IRQs from CIA
	STA $DC0D
	STA $DD0D
	LDA $DC0D		; Read to clear
	LDA $DD0D
	CLI

	JSR cls
	JSR music_init

	LDA #$00
	STA frame
	STA frame+1
	STA joy1_data
	STA joy2_data

	;CVBASIC MARK DON'T CHANGE
