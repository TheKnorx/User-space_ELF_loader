; This include file containts error strings to make error printing
; and finding errors a little more easier

section .rdata
	ARGUMENTS_ERROR_STR: db "Received invalid sequenze arguments", 0x0A, "Usage: load_efi_binary <executable-path>", 0x0A
    ARGUMENTS_ERROR_LEN equ $ - ARGUMENTS_ERROR_STR  ; len of arguments1 error string
