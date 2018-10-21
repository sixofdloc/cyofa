PT_NORMAL = $00;
PT_TERMINATOR = $01;
    *=$0801
    .byte $0c,$08,$06,$00,$9e,$20,$32,$30,$36,$34,$00,$00,$00
    *=$0810
start
    lda #$36
    sta $01
    lda #$01
    sta $d020
    lda #$00
    sta $d021
    lda #$01
    sta $0286
    jsr $e544
    lda #$0e
    jsr $ffd2
    lda #<cyofaStarttext
    sta $fe
    lda #>cyofaStarttext
    sta $ff
    jsr printString
    lda #<loadingText
    sta $fe
    lda #>loadingText
    sta $ff
    jsr printString
    jsr loadBook
;set up address pointers for pages
    lda book+2
    sta pah0+1
    sta pah1+1
    lda book+3
    sta pah0+2
    sta pah1+2
    lda book+4
    sta pal0+1
    lda book+5
    sta pal0+2
restart
    ;print book title
    lda #<(book+6) ;title base
    sta $fe
    lda #>(book+6) ;title base
    sta $ff
    jsr printString
    jsr pressSpacePrompt
    jsr $e544

    ldx #$00
GotoPage
    jsr loadPage
    jmp displayPage

lock    
    inc $d020
    jmp lock

endOfBook
    lda #<theEnd
    sta $fe
    lda #>theEnd
    sta $ff
    jsr printString
    jsr pressSpacePrompt
    ldx #$00
    jmp restart

clearKeyboardBuffer
    jsr $ffe4
    bne clearKeyboardBuffer
    rts

displayPage 
    jsr displayPageText
    jsr clearKeyboardBuffer
    lda pageType
    cmp #PT_TERMINATOR
    beq endOfBook
    jsr displayOptions
dpageloop
    jsr $ffe4
    beq dpageloop
    cmp #$85
    beq displayPage
    cmp #$86
    bne notF3
    ldx #$00
    jmp takeOption
notF3
    cmp #$87
    bne notF5
    ldx #$01
    jmp takeOption
notF5
    ldx numOptions
    cpx #3
    bne notF7
    cmp #$88
    bne notF7
    ldx #$02
    jmp takeOption
notF7
    jmp dpageloop
    ;jsr pressSpace
    rts

displayPageText ; no prereqs
    lda #$01
    sta $0286
    jsr crlf
    jsr crlf
    lda pageTextLo
    sta $fe
    lda pageTextHi
    sta $ff
    ldy #$00
displayPageText_loop
    lda ($fe),y
    beq dptlx    
    cmp #$ff
    bne dptl2
    lda $ff
    pha
    lda $fe
    pha
    tya
    pha
    jsr pressSpacePrompt
    pla
    tay
    pla
    sta $fe
    pla
    sta $ff
    jsr incpointer
    jmp displayPageText_loop

dptl2
    cmp #$22
    bne dpnotquote
    jsr $ffd2
    lda #$00
    sta $d4
    jmp dpnq1
dpnotquote
    cmp #$fe
    bne dpnotpagejump
    jsr incpointer
    lda ($fe),y
    pha
    jsr pressSpacePrompt
    pla
    tax
    jmp GotoPage
dpnotpagejump
    jsr $ffd2
dpnq1
    jsr incpointer
    jmp displayPageText_loop
dptlx
    jsr crlf
    jsr crlf
    rts

displayOptions ;no prereqs
    lda #$07
    sta $0286
    
    lda #<F1
    sta $fe
    lda #>F1
    sta $ff
    jsr printString
    jsr crlf

    lda #<F3
    sta $fe
    lda #>F3
    sta $ff
    jsr printString
    ;get pointer to first option into fe/ff
    ldx #$00
    jsr fetchOptionPointer
    jsr displayOption
    jsr crlf
    jsr crlf
    lda #<F5
    sta $fe
    lda #>F5
    sta $ff
    jsr printString
    ldx #$01
    jsr fetchOptionPointer
    jsr displayOption
    lda numOptions
    cmp #$03
    bne doptsx
    jsr crlf
    jsr crlf
    lda #<F7
    sta $fe
    lda #>F7
    sta $ff
    jsr printString
    ;get pointer to first option into fe/ff
    ldx #$02
    jsr fetchOptionPointer
    jsr displayOption
    
doptsx
    rts

takeOption ; expects option # in x
    jsr fetchOptionPointer
    jsr fetchbyte
    tax
    jmp GotoPage

fetchOptionPointer ; expects option in x, returns option in fe/ff
    ;option pointer is at pageBase + 2 + (x * 2)
    lda #$00
    sta $fe
    lda #$10
    sta $ff   ;pagebase for unpacked page is always $1000
    txa
    asl ; *2
    clc
    tay
    iny
    iny
    jsr fetchbyte
    pha
    jsr fetchbyte
    sta $ff
    pla
    sta $fe
    ldy #$00
    rts
        



displayOption ; expects pointer to option in fe/ff, returns pointer to NEXT option in fe/ff
    ;get past the index byte
    inc $fe
    bne do1
    inc $ff
do1
    jsr printString
    jsr incpointer
    rts

pressSpacePrompt
    lda #<pressSpace
    sta $fe
    lda #>pressSpace
    sta $ff
    jsr printString
psloop
    jsr $ffe4
    beq psloop
    cmp #$20
    bne psloop    ;jsr $ffcf
    rts
    

printString ; expects string at fe/ff
    ldy #$00
psLoop
    jsr fetchbyte
    cmp #$00 ; because fetchbyte kills zero flag with a cpy
    beq psx
    cmp #$22
    bne notquote
    jsr $ffd2
    lda #$00
    sta $d4
    jmp psLoop
notquote
    jsr $ffd2
    jmp psLoop
psx
    rts
      


loadPage ; expects page # in x
pah0
    lda $ffff,x
    bne pageFound
    lda #<pageNotFound
    sta $fe
    lda #>pageNotFound
    sta $ff
    jsr printString
    jsr pressSpacePrompt
    rts
pageFound
    stx currentPage
    ldy #$00
pal0
    lda $ffff,x
    ;depack page
    sta exomizer_lobyte
pah1
    lda $ffff,x
    sta exomizer_hibyte
    sei
    lda #$35
    sta $01
    jsr decrunch
    lda #$36
    sta $01
    cli
    ;Continue on
    lda #$00
    sta $fe
    lda #$10
    sta $ff
    jsr fetchbyte
    sta pageType
    jsr fetchbyte
    sta numOptions
   ;page text pointer is page + 2 +(num_options * 2)
    lda numOptions
    asl ;*2
    clc
    adc #$02
    sta adder+1
    lda $fe
    sta pageTextLo
    lda $ff
    sta pageTextHi
    lda pageTextLo
    clc
adder
    adc #$04
    sta pageTextLo
    bcc lp1
    inc pageTextHi
lp1    
    rts  


fetchbyte
    lda ($fe),y

incpointer
    iny
    cpy #$00
    bne ip0
    inc $ff
ip0
    rts

crlf
    lda #$0d
    jsr $ffd2
    rts

loadBook
    lda #$31 ;first file $1a00-4a00
    sta fileLast
    jsr loadFile
    lda #$0f
    sta $d020
    lda #$32 ;second file $4a01-$8a00
    sta fileLast
    jsr loadFile
    lda #$0c
    sta $d020
    lda #$33 ;third file $8a01-$cd00
    sta fileLast
    jsr loadFile
    lda #$0b
    sta $d020
    lda #$34 ;fourth file $e000-$f800
    sta fileLast
    jsr loadFile
    lda #$00
    sta $d020
    rts

loadFile
    lda #7
    ldx #<fileName
    ldy #>fileName
    jsr $ffbd
    lda #$01
    ldx $ba
    ldy #$01
    jsr $ffba
    lda #$00
    jsr $ffd5
    rts
    .include "exomizer.asm"
    
;DATA, misc
cyofaStarttext
    .byte $0d,$0d
    .text "{yellow}  Choose Your Own F. Adventure Engine"
    .byte $0d
    .text "            Version 0.6.67"
    .byte $0d
    .text "             By Six/DLoC"
    .byte $00

loadingText
    .byte $0d,$0d,$0d,$0d
    .text "{white}Loading book..."
    .byte $0d,$0d,$0d,$0d,$00

theEnd
    .text "{$0d}{$0d}{yellow}                {rvs on}THE END{rvs off}{$0d}"
    .byte $00

pageNotFound
    .text "{$0d}{$0d}{$0d} {rvs on}{red}No page found with that page number.{rvs off} {white}"
    .byte $0d,$0d,$0d,$00

pressSpace
    .byte $0d,$0d
    .text "      {white}{rvs on}Press space to continue.{rvs off}"
    .byte $0d, $00

F1
    .text "{rvs on}F1{rvs off} Reprint text"
    .byte $0d, $00
F3
    .text "{rvs on}F3{rvs off} "
    .byte $00
F5
    .text "{rvs on}F5{rvs off} "
    .byte $00

F7
    .text "{rvs on}F7{rvs off} "
    .byte $00

optDisplaying
    .byte $00
currentOptionLo
    .byte $00
currentOptionHi
    .byte $00

;DATA, currentPage
currentPage     
    .byte $00
pageType
    .byte $00
numOptions
    .byte $00
pageTextLo
    .byte $00
pageTextHi
    .byte $00

fileName
    .text "altair"
fileLast
    .text "1"
    .byte $00

decrunchedPage
    *=$1000
    .repeat $1ff,00
book
    *=$1a00
    ;.include "book/altair.asm"


