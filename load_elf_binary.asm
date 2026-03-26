; This file contains a kind of extended prove of concept of a custome implementation of the 
; Linux kernel function load_elf_binary done in assembly

; Syscall register assignment: 
; rdi - rsi - rdx - r10 - r8 - r9 - rax = Syscall-number

BITS 64  ; ensure 64bit

section .bss
    ELF_FILENAME:   resq 0x01   ; quad word variable to store the char pointer to the filename 
    ELF_FILE_FD:    resq 0x01   ; quad word variable to store the file descriptor of the efi file
section .data
    FATAL_ERROR_STR: db "Fatal error occured!"
section .text

%include "flags.asm.inc"


; Custome implementation of load_elf_binary
; Note that we use _start, therefore we dont have any glibc functionality
; As opposed to the original function signature:        static int load_elf_binary(struct linux_binprm *bprm)
; we just take a simple char* filename as argument:     int load_elf_binary(char* filename)
global _start
_start: 
    ; Prolog
    push    rbp
    mov     rbp, rsp
    ; Align the stack to a mod 16 boundary
    and     rsp, -16

    ; Save the filename argument into the filename variable
    ; first 8 bytes after rbp for return address (garbage), 
    ; second 8 bytes after rbp for the executable filename (skip it) and finally the third 8 bytes represent the char* filename argument
    mov     rsi, [rbp+8*3]  ; move argument char* filename into rsi
    mov     [ELF_FILENAME], rsi  ; save rsi into filename variable

    ; Create a buffer for read operations to store them read bytes into
    ; Do this with mmap: void *mmap(void addr[.length], size_t length, int prot, int flags, int fd, off_t offset);
    ; We take a standard size of buffer size - like BUFSIZ from stdio.h - so we can maybe reuse the buffer 
    mov     rax, SYSCALL_MMAP


    ; First open the efi file  - creating a file handle, initializing structs and pointers - for reading its properties using the following kernel functions:
    ; Opening the ELF file: int open(const char *path, int oflag, ...);
    .open_efi:
        mov     rax, SYSCALL_OPEN   ; open syscall number
        mov     rdi, ELF_FILENAME  ; parameter char* path
        mov     rsi, O_RDONLY   ; open efi for read-only
        syscall                 ; do open syscall --> rax 
        test    rax, rax        ; rest if rax is negativ
        js      .error          ; jmp to error section and handle the error
        ; else fall through to consistency check section

    ; Second make some consistency checks - magic number, ...
    .check_efi_consistency:

    
    jmp     .return         ; per default skip the error section
    .error: 
        ; do some error printing and debugging information ...
    .return: 
        ; Simple epilog
        leave
        ret 