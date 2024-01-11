# AetherixOS
AetherixOS is an open-source and lightweight operating system. It is designed to work on BIOS machines, it runs in 16 bit real mode on x86-x64 processors.

Details

AetherixOS is built in pure 16 bit assembly, it has a built in unix-like shell which can be modified or replaced completely.
AetherixOS is a microkernel meaning it only does the basics. 
I do intend to add to this project in the near future.

Building the OS

Navigate to the source folder and open "kernel.asm", scroll to the bottom until you find some commands that look like this: %INCLUDE "..." From there change that to the path that the kernel is in, for me the path is E:\ so it would look like this: %INCLUDE "E:\source..." If it has anything after the E:, dont remove it, that is required to build the kernel. Once done, navigate to the project's root folder and run "build.bat" if you are on Windows, make sure you have NASM installed somewhere as it will ask you where. Once you enter the path of NASM it will create 2 files in the build folder: "boot.bin" and "kernel.bin", these two are the most important files in the OS. To write the OS to a drive, write "boot.bin" to a drive using a tool like Rufus and then after writing the bootloader, copy kernel.bin to that drive. Now, if all is done correctly, you should be able to boot into AetherixOS!
