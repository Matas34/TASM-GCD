.model small
.stack 100h                                
skBufSize   EQU 20

.data
    buffer1     db skBufSize dup ("$")
    buffer2     db skBufSize dup ("$")
    result      db skBufSize dup ("$")

    helpMessage db "Programa atima du beveik bet kokio ilgio desimtainius teigiamus skaicius, esancius failuose, ir rezultata isveda i trecia faila. Panaudojimas: uzd2 file1.txt file2.txt rez.txt", 13, 10, "$"
    errorOpeningFileForReadingMessage db "Klaida! Neatidarytas duomenu failas.", 13, 10, "$"
    errorOpeningFileForWritingMessage db "Klaida! Neatidarytas rezultatu failas.", 13, 10, "$"

    resLength   db ?

    firstFile   db 255 DUP (0)
    secondFile  db 255 DUP (0)
    outputFile  db 255 DUP (0)

    firstInputFail  dw ?          ;deskriptorius
    secondInputFail dw ?          ;;deskriptorius
    outputFail  dw ?              ;;deskriptorius

.code
main:
    mov ax, @data
    mov ds, ax

    xor di, di
    mov bx, 82h
    mov si, offset firstFile
    call SaveArgument
    mov si, offset secondFile
    call SaveArgument
    mov si, offset outputFile
    call SaveArgument

    xor ax, ax
    xor dx, dx
    mov ah, 3Dh
    mov al, 00
    mov dx, offset firstFile
    int 21h
    jc errorOpeningFileForReading
    mov firstInputFail, ax

    mov bx, firstInputFail
    mov si, offset buffer1
    call ReadBuf

    xor ax, ax
    xor dx, dx
    mov ah, 3Dh
    mov al, 00
    mov dx, offset secondFile
    int 21h
    jc errorOpeningFileForReading
    mov secondInputFail, ax

    mov bx, secondInputFail
    mov si, offset buffer2
    call ReadBuf

    mov ah, 3Ch
    mov cx, 2
    mov dx, offset outputFile
    int 21h
    jc errorOpeningFileForWriting
    mov outputFail, ax

mainloop:
    call skaitmenys
    call didesnis   ;grazina statusa al'e

    cmp al, 1
    je XDY

    cmp al, 2
    je YDX

    cmp al, 3
    je XLY

    XDY:
    call SubtractNumbersKaiXdY
    jmp mainloop

    YDX:
    call SubtractNumbersKaiYdX
    jmp mainloop

    XLY:
    call copyrez
    call printf
    jmp exit

;klaidu apdorojimas

errorOpeningFileForReading:
    mov ah, 09h
    mov dx, offset errorOpeningFileForReadingMessage
    int 21h
    jmp exit

errorOpeningFileForWriting:
    mov ah, 09h
    mov dx, offset errorOpeningFileForWritingMessage
    int 21h
    jmp exit

help:
    mov ah, 09h
    mov dx, offset helpMessage
    int 21h

copyrez PROC
    mov si, offset buffer1
    mov di, offset result

    mov dh, bh
    mov resLength, bl

    galas:
    inc si
    dec dh
    cmp dh, 0
    je outgalas
    jmp galas

    outgalas:
    copyloop:
    mov dl, [si]
    mov [di], dl
    inc si
    inc di
    cmp byte ptr [si], '$'
    je outcopy
    jmp copyloop

    outcopy:
    mov byte ptr[di], '$'
    ret

copyrez ENDP

didesnis PROC
    mov si, offset buffer1
    mov di, offset buffer2

    xor ax, ax    ;irasysima statusa (skaiciu) pagal kuri zinosime kuris skaicius didesnis
    xor dx, dx    ;tarpinis [si] (i dh) ir [di] (i dl) palyginimui

    cmp bl, cl
    je vienodi
    ja XyraDidesnis
    mov al, 2

    jmp endDidesnis

    XyraDidesnis:
    mov al, 1

    jmp endDidesnis

    vienodi:

    mov dh, bh

    siPerstumimas:
    cmp dh, 0
    je endsi
    inc si
    dec dh
    jmp siPerstumimas

    endsi:
    mov dh, ch

    diPerstumimas:
    cmp dh, 0
    je poPetrstumimo
    inc di
    dec dh
    jmp diPerstumimas

    poPetrstumimo:

    vienodiLoop:
    cmp byte ptr[si], '$'
    je lygus

    mov dh, [si]
    mov dl, [di]
    cmp dh, dl
    ja XyraDid
    jl YyraDid

    inc si
    inc di

    jmp vienodiLoop

    XyraDid:
    mov al, 1
    jmp endDidesnis

    YyraDid:
    mov al, 2
    jmp endDidesnis

    lygus:
    mov al, 3

    endDidesnis:
    ret

didesnis ENDP


skaitmenys PROC
    mov si, offset buffer1    ; bh - nuliai bl - skaitmenys
    mov bx, 0
    mov di, offset buffer2    ; ch - nuliai cl - skaitmenys
    mov cx, 0

    mov dx, 0    ;tarpinis [si] (i dh) ir [di] (i dl) palyginimui

    NuliuLoop1:
    mov dh, [si]
    cmp dh, '0'
    jne SkLoop1
    inc bh
    inc si
    jmp NuliuLoop1

    SkLoop1:
    cmp byte ptr[si], '$'
    je end1
    inc bl
    inc si
    jmp SkLoop1

    end1:

    NuliuLoop2:
    mov dl, [di]
    cmp dl, '0'
    jne SkLoop2
    inc ch
    inc di
    jmp NuliuLoop2

    SkLoop2:
    cmp byte ptr[di], '$'
    je end2
    inc cl
    inc di
    jmp SkLoop2

    end2:
    ret

skaitmenys ENDP

SubtractNumbersKaiXdY PROC
    mov si, offset buffer1
    mov di, offset buffer2

    mov dl, bl
    mov dh, bh

    add dl, dh
    dec dl

    ciklas1:
    cmp dl, 0
    je out1
    inc si
    dec dl
    jmp ciklas1

    out1:

    xor dx, dx

    mov dl, cl
    mov dh, ch

    add dl, dh
    dec dl

    ciklas2:
    cmp dl, 0
    je out2
    inc di
    dec dl
    jmp ciklas2

    out2:

    xor dx, dx

    add cl, ch

    SubtractLoopXdY:
        cmp cl, ch
        je EndSubtractionXdY

        mov al, [si]
        mov ah, [di]

    cmp al, ah
    ja noborrow
    je gausisnulis

    dec si
    mov al, 0
    mov al, [si]
    cmp al, '0'
    jne toliau
    mov al, '9'
    mov [si], al
    dec si
    mov al, [si]
    dec al
    mov [si], al
    inc si
    jmp prideti

    toliau:
    dec al
    mov [si], al

    prideti:
    inc si
    mov al, 0
    mov al, [si]    ;isidedame pradine reiksme
    add al, 10

    noborrow:

    sub al, ah
    add al, '0'
    mov ah, 0

    mov [si], al

    dec si
    dec di

    dec cl

    jmp SubtractLoopXdY

    gausisnulis:
    mov al, '0'
    mov [si], al

    dec si
    dec di

    dec cl

    jmp SubtractLoopXdY

    EndSubtractionXdY:
    ret

SubtractNumbersKaiXdY ENDP

SubtractNumbersKaiYdX PROC
    mov si, offset buffer1
    mov di, offset buffer2

    mov dl, bl
    mov dh, bh

    add dl, dh
    dec dl

    cmp dl, 0
    je out11

    ciklas11:
    cmp dl, 0
    je out11
    inc si
    dec dl
    jmp ciklas11

    out11:

    xor dx, dx

    mov dl, cl
    mov dh, ch

    add dl, dh
    dec dl

    cmp dl, 0
    je out22

    ciklas22:
    cmp dl, 0
    je out22
    inc di
    dec dl
    jmp ciklas22

    out22:

    xor dx, dx

    add bl, bh

    SubtractLoopYdX:
        cmp bl, bh
        je EndSubtractionYdX

        mov al, [di]
        mov ah, [si]

    cmp al, ah
    ja noborroww
    je gausisnuliss

    dec di
    mov al, 0
    mov al, [di]
    cmp al, '0'
    jne toliauu
    mov al, '9'
    mov [di], al
    dec di
    mov al, [di]
    dec al
    mov [di], al
    inc di
    jmp pridetiu

    toliauu:
    dec al
    mov [di], al

    pridetiu:
    inc di
    mov al, 0
    mov al, [di]
    add al, 10

    noborroww:

    sub al, ah
    add al, '0'
    mov ah, 0

    mov [di], al

    dec di
    dec si

    dec bl

    jmp SubtractLoopYdX

    gausisnuliss:
    mov al, '0'
    mov [di], al

    dec di
    dec si

    dec bl

    jmp SubtractLoopYdX

    EndSubtractionYdX:
    ret

SubtractNumbersKaiYdX ENDP

SaveArgument PROC
Begin:
    mov dl, [es:bx]
    inc bx
    cmp dl, "?"
    je CheckSlash
    cmp dl, 20h
    je StopSpace
    cmp dl, 13
    je StopEnter
    mov byte ptr [si], dl
    inc si
    jmp Begin

CheckSlash:
    mov dl, [bx]
    inc bx
    cmp dl, '/'
    je helpMe
    jmp Begin

StopSpace:
    inc di
    ret

StopEnter:
    cmp di, 2
    jb helpMe
    ret

helpMe:
    mov ah, 09h
    mov dx, offset helpMessage
    int 21h
    mov ah, 4Ch
    int 21h
    ret
SaveArgument ENDP

ReadBuf PROC
    push cx
    push dx

    mov ah, 3Fh
    mov cx, skBufSize
    mov dx, si
    int 21h

    pop dx
    pop cx
    ret

ReadBuf ENDP

printf PROC
    mov si, offset result
    xor dx, dx
    xor ax, ax
    xor cx, cx

    mov ah, 40h
    mov bx, outputFail
    mov cl, resLength
    mov dx, si
    int 21h

    mov ah, 3Eh
    mov bx, outputFail
    int 21h

    ret

printf ENDP

exit:
    mov ah, 3Eh
    mov bx, firstInputFail
    int 21h

    mov ah, 3Eh
    mov bx, secondInputFail
    int 21h

    mov ah, 4Ch
    int 21h

end main
