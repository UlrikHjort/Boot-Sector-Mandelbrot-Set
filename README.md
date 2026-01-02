# Bootable Mandelbrot (x86 Real Mode)

This project is a **512-byte boot sector program** that renders the **Mandelbrot set** directly from the BIOS, without an operating system.

When booted, it switches the machine into **VGA mode 13h (320×200, 256 colors)** and draws the Mandelbrot fractal using **16-bit real-mode x86 assembly** and **fixed-point arithmetic**.

---

## Features

- Runs directly as a **bootloader**
- No OS, no DOS, no protected mode
- Uses BIOS interrupts and direct VGA memory access
- Fixed-point math (scale = 256), no floating point
- Fits entirely in **512 bytes** (including boot signature)
- Outputs a classic Mandelbrot visualization

---

## How It Works (High Level)

1. BIOS loads the boot sector at `0x7C00`
2. Video mode is set to **13h**
3. Each screen pixel is mapped to a point in the complex plane
4. The Mandelbrot iteration `z = z² + c` is computed
5. The iteration count determines the pixel color
6. The program loops forever to keep the image visible

---

## Building

Assemble with NASM and run with qemu:

```bash
nasm -f bin mandelbrot.asm -o mandelbrot.bin

qemu-system-i386 mandelbrot.bin