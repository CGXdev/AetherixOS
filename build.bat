@echo off
set /p nasm=NASM Directory: 
echo Moving bootloader...
copy source\bootload\boot.bin build\boot.bin
echo Building kernel...
%nasm%nasm.exe -O0 -f bin -o build\kernel.bin source\kernel.asm
pause