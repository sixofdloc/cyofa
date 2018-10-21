# What is this? 
A gamebook engine for the Commodore 64.  Out of the box it should be able to play 

# What is the book format? 
Books load at $1a00 - Note that the pointer tables point to the END of each page, not the beginning.
```
Bytes 0,1 - Lo/Hi byte pointer to the numPages byte
Bytes 2,3 - Lo/Hi byte pointer to the pageAddress (HI bytes) table7
Bytes 4,5 - Lo/Hi byte pointer to the pageAddress (LO bytes) table7
Bytes 6-? - The book's title text, zero-terminated
Bytes ? - A single byte indicating the # of pages

pageAddressTable - Hi-bytes of the address of each page

;BOOK DATA, page pointer table
pageAddressHi
    .byte >p000_end,>p001_end,>p002_end,XPAGE
... (when duplicating a gamebook, use $00 for hi/lo to indicate missing pages
pageAddressLo
    .byte <p000_end,<p001_end,<p002_end,XPAGE
...
    .binary "book/p000.pak",2 ;include the exomized page file, skipping the load addr
p000_end

    .binary "book/p001.pak",2
p001_end
    
    .binary "book/p002.pak",2
p002_end
```
# What is the page data format?
Sample page source follows:

```
    *=$1000
p000 ; book pages 1-5
    .byte PT_NORMAL ; page type
    .byte 2 ; number of options
    .byte <p000_opt1,>p000_opt1 ; pointer to first option    
    .byte <p000_opt2,>p000_opt2 ; pointer to second option
          ;01234567890123456789012345678901234567890
    .byte $0d
    .text "  Page text"
    .byte $00
p000_opt1
    .byte 3 ;destination page for option 1
    .text "Text to display for option 1"
    .byte $00
p000_opt2
    .byte 4 ;destination page for option 2
    .text "Text to display for option 2"
    .byte $00
```
# How is the page data processed and compressed?
Each page file is compiled, then exomized (compressed)

# What are the page types?
```
PT_NORMAL = $00;
PT_TERMINATOR = $01;
```

# Are there any special characters to use in page data 
* $ff - pauses with "PRESS SPACE" message
* $fe (followed by a single-byte page #) - pauses and then continues at specified page

# Many thanks to: 
* _Magnus Lind_ for his excellent
* All of the amazing gamebook authors from the 70's and 80's who brought so much joy to my childhood.


