; This file contains a kind of extended prove of concept of a custome implementation of the 
; Linux kernel function load_elf_binary done in assembly

; Syscall register assignment: 
; rdi - rsi - rdx - r10 - r8 - r9 - rax = Syscall-number
; Syscall clobbers: 
; RAX, RCX, R11

BITS 64  ; ensure 64bit

section .bss
    ELF_FILENAME:   resq 0x01   ; quad word variable to store the char pointer to the filename 
    ELF_FILE_FD:    resq 0x01   ; quad word variable to store the file descriptor of the efi file
    IO_BUFFER:      resq 0x01   ; quad word variable to store the char pointer to the buffer
    IO_BUFFER_PTR:  resq 0x01   ; quad word variable to store read/write index to IO-Buffer into
    ERRNO:          resq 0x01   ; C-style errno number variable 
section .data
    FATAL_ERROR_STR: db "Fatal error occured!", 0x0A, 0x00
    ARGUMENTS_ERROR_STR: db "Usage: ./load_elf_binary.asm <path/to/binary>", 0x0A, 0x00
section .text

%include "flags.asm.inc"
%include "asm-generic_errno-base.lib.asm"

; Macro for doing the prolog
%macro ENTER 0
    push    rbp
    mov     rbp, rsp
    ; Align the stack to a mod 16 boundary
    and     rsp, -16
%endmacro

; Macro for setting the sys_errno variable with the negated value in rax
%macro SET_ERRNO 0
    neg     eax             ; negate rax
    mov     [SYS_ERRNO], eax; store the value in eax into sys_errno
%endmacro


; procedure for printing text
; we expect the string to be printed TO BE null-terminated, and put into rdi
print_text:
    ENTER
    ; first find out how long the string is
    mov     rsi, rdi        ; move string pointer into source index 
    mov     al, -1          ; move into al anything except the null terminator
    cld                     ; clear direction flag for lodsb to work correctly
    .for:  ; count the length of the string
        test    al, al      ; check if al is the null terminator
        js      .end_for    ; if we reached the null terminator, end the loop
        lodsb               ; load byte at byte [rsi] into al and increment si
        jmp     .for        ; continue the loop
    .end_for:  ; label to end the for loop
    ; now calculate the length of the string
    sub     rsi, rdi        ; do so by subtracting the pointer, pointing to the null terminator from the base of the string

    mov     rdx, rsi        ; param: nbyte -> calculated by the sub
    mov     rsi, rdi        ; param: buf
    mov     rax, __NR_write ; move syscall number into rax
    mov     rdi, STDOUT     ; param: fildes -> stdout -> 1
    syscall                 ; print the error string
    ; if the write failed, we just return with rax beeing the negative value
    .return: 
        leave
        ret

; procedure that mirrors behavior to to C-function perror
print_error:


; Custome implementation of load_elf_binary
; Note that we use _start, therefore we dont have any glibc functionality
; As opposed to the original function signature:        static int load_elf_binary(struct linux_binprm *bprm)
; we just take a simple char* filename as argument:     int load_elf_binary(char* filename)
global _start
_start: 
    ENTER

    ; **** Save the filename argument into the filename variable ****
    ; rbp+8  --> argc
    ; rbp+16 --> executable filename (skip it) 
    ; rbp+24 --> char* filename argument
    ; check if we received enough arguments
    cmp     qword [rbp+8*2], 0x02   ; check if argc is equal 2
    jne     .print_usage    ; print the usage and exit program
    ; else continue with execution
    mov     rsi, [rbp+8*3]  ; move argument char* filename into rsi
    mov     [ELF_FILENAME], rsi ; save rsi into filename variable

    ; **** Create a buffer for read operations to store them read bytes into ****
    ; Do this with mmap: void *mmap(void addr[.length], size_t length, int prot, int flags, int fd, off_t offset);
    ; We take a standard buffer size for the allocated space - like BUFSIZ from stdio.h - so we can maybe reuse the buffer 
    mov     rax, __NR_mmap  ; move syscall number for mmap into rax
    xor     rdi, rdi        ; param: addr[.length] --> 0
    mov     rsi, BUFSIZ     ; param: length --> C-BUFSIZ constant 
    mov     rdx, PROT_READ | PROT_WRITE ; param: prot --> read and write
    mov     r10, MAP_PRIVATE | MAP_ANONYMOUS  ; param: flags
    mov     r8, -1          ; param: fd
    xor     r9, r9          ; param: offset --> 0
    syscall                 ; allocate a block of memory BUFSIZ bytes in size
    test    rax, rax        ; check if mmap was executed successfully
    js      .error          ; if rax is a neg number, handle the error
    mov     [IO_BUFFER], rax; move pointer to allocated space into variable

    ; First open the efi file  - creating a file handle, initializing structs and pointers - for reading its properties using the following kernel functions:
    ; Opening the ELF file: int open(const char *path, int oflag, ...);
    .open_efi:
        mov     rax, __NR_open      ; open syscall number
        mov     rdi, ELF_FILENAME   ; parameter char* path
        mov     rsi, O_RDONLY       ; open efi for read-only
        syscall             ; do open syscall --> rax 
        test    rax, rax    ; rest if rax is negativ
        js      .error      ; jmp to error section and handle the error
        ; else fall through
        mov     [ELF_FILE_FD], rax  ; move file_fd into variable

    ; Second, make some consistency checks - magic number, ...
    ; ssize_t read(int fildes, void *buf, size_t nbyte);
    .check_efi_consistency:
        mov     rax, __NR_read      ; put syscall number into rax
        mov     rdi, [ELF_FILE_FD]  ; param: fildes
        mov     rsi, IO_BUFFER      ; param: buf
        mov     rdx, 0x04   ; param: nbyte --> elf number length is 4 bytes
        syscall             ; read the first 4 byte into the buffer
        cmp     byte [IO_BUFFER+0], ELFMAG0  ; compare the first byte for a match
        jne     .error      ; if it does not match, print error and exit
        ; ...

    jmp     .return         ; per default skip all the following sections and jmp straigth to the return section
    .error: 
        ; do some error printing and debugging information ...
        mov     rdi, FATAL_ERROR_STR    ; param: buf 
        call    print_text  ; print that shit
        ; as for now and also probably in the future, this is all we have on debuggin, sry
        jmp     .return     ; jump to return section
    .print_usage:  ; print the usage and exit
        mov     rdi, ARGUMENTS_ERROR_STR   ; move string to print into destination index
        call    print_text  ; print it
        jmp     .return     ; jmp to return section
    .return: 
        ; Simple epilog
        leave
        ret 