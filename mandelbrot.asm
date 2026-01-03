 ; *************************************************************************** 
 ;                  Boot Sector Mandelbrot set  
 ;
 ;           Copyright (C) 2026 By Ulrik Hørlyk Hjort
 ; *************************************************************************** 	


[BITS 16]                ; We are in 16-bit real mode
[ORG 0x7C00]             ; BIOS loads the boot sector here

start:
    ; ============================
    ; Set VGA video mode 13h
    ; 320x200 pixels, 256 colors
    ; ============================
    mov ax, 0x0013
    int 0x10

    ; ============================
    ; Point ES to VGA video memory
    ; Each pixel = 1 byte at A000:0000
    ; ============================
    mov ax, 0xA000
    mov es, ax

    xor di, di            ; DI = 0, screen offset (used by STOSB)
    mov word [py], 0      ; py = 0 (start at top row)

; ============================
; Outer loop over Y (rows)
; ============================
y_loop:
    mov word [px], 0      ; px = 0 (start at left column)

; ============================
; Inner loop over X (columns)
; ============================
x_loop:

    ; ============================
    ; Map screen X coordinate to complex plane
    ; x0 = (px * 4) - 640
    ; Fixed-point scale = 256
    ; ============================
    mov ax, [px]          ; AX = px
    shl ax, 2             ; AX = px * 4
    sub ax, 640            ; Shift range to center
    mov [x0], ax          ; Store real component (c.real)

    ; ============================
    ; Map screen Y coordinate to complex plane
    ; y0 = (py * 4) - 400
    ; ============================
    mov ax, [py]          ; AX = py
    shl ax, 2             ; AX = py * 4
    sub ax, 400            ; Shift range to center
    mov [y0], ax          ; Store imaginary component (c.imag)

    ; ============================
    ; Initialize z = 0 + 0i
    ; ============================
    xor si, si             ; SI = x = 0 (real part of z)
    xor bp, bp             ; BP = y = 0 (imag part of z)

    mov cl, 255            ; Iteration counter (max 255)

; ============================
; Mandelbrot iteration loop
; z = z*z + c
; ============================
iter_loop:

    ; ============================
    ; Compute x_squared = (x * x) / 256
    ; x is fixed-point (scale 256)
    ; IMUL gives DX:AX = x*x (32-bit)
    ; We want (DX:AX) >> 8
    ; ============================
    mov ax, si             ; AX = x
    imul si                ; DX:AX = x * x

    mov bx, ax             ; Save AX (low 16 bits)
                            ; We need AH later

    mov ax, dx             ; AX = high 16 bits
    shl ax, 8              ; AH = DL, AL = 0
    mov al, bh             ; AL = original AH
                            ; AX now = (x*x) >> 8

    mov [x_sq], ax         ; Store x*x

    ; ============================
    ; Compute y_squared = (y * y) / 256
    ; Same fixed-point method
    ; ============================
    mov ax, bp             ; AX = y
    imul bp                ; DX:AX = y * y

    mov bx, ax             ; Save AX again
    mov ax, dx             ; AX = high 16 bits
    shl ax, 8              ; Shift left 8 bits
    mov al, bh             ; Insert original AH
                            ; AX = (y*y) >> 8

    mov [y_sq], ax         ; Store y*y

    ; ============================
    ; Escape condition:
    ; x*x + y*y > 4.0 ?
    ; 4.0 * 256 = 1024
    ; ============================
    mov ax, [x_sq]         ; AX = x*x
    add ax, [y_sq]         ; AX = x*x + y*y
    cmp ax, 1024           ; Compare to 4.0
    ja done                ; If > 4.0, escape

    ; ============================
    ; new_y = (2 * x * y) / 256 + y0
    ; ============================
    mov ax, si             ; AX = x
    imul bp                ; DX:AX = x * y

    mov bx, ax             ; Save AX
    mov ax, dx             ; AX = high 16 bits
    shl ax, 8              ; Shift
    mov al, bh             ; Insert AH
    shl ax, 1              ; Multiply by 2
    add ax, [y0]           ; + c.imag
    mov bp, ax             ; y = new_y

    ; ============================
    ; new_x = x*x - y*x + x0
    ; ============================
    mov ax, [x_sq]         ; AX = x*x
    sub ax, [y_sq]         ; AX = x*x - y*y
    add ax, [x0]           ; + c.real
    mov si, ax             ; x = new_x

    dec cl                 ; Decrease iteration count
    jnz iter_loop          ; Continue if not zero

; ============================
; Pixel coloring
; ============================
done:
    mov al, cl             ; Color based on escape speed
    stosb                  ; Write pixel, DI++

    ; ============================
    ; Advance to next X
    ; ============================
    inc word [px]
    cmp word [px], 320
    jb x_loop

    ; ============================
    ; Advance to next Y
    ; ============================
    inc word [py]
    cmp word [py], 200
    jb y_loop

; ============================
; Infinite loop to keep image on screen
; ============================
forever:
    jmp forever

; ============================
; Variables (in boot sector)
; ============================
px:   dw 0                 ; Current x pixel
py:   dw 0                 ; Current y pixel
x0:   dw 0                 ; Mapped real coordinate
y0:   dw 0                 ; Mapped imaginary coordinate
x_sq: dw 0                 ; x*x (fixed-point)
y_sq: dw 0                 ; y*y (fixed-point)

; ============================
; Pad to 512 bytes and boot signature
; ============================
times 510-($-$$) db 0
dw 0xAA55
