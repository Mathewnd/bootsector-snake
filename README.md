Simple bootsector snake clone.

To assemble use NASM

    nasm -f bin -o out.bin main.asm

To test it out use QEMU

    qemu-system-i386 -fda out.bin
