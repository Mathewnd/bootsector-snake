Simple Snake clone made in x86 assembly to run in under 512 bytes.

To assemble use NASM

    nasm -f bin -o out.bin main.asm

To test it out use QEMU

    qemu-system-i386 -fda out.bin

