# Toolchain

CC      := gcc
AS      := nasm
LD      := ld

# Paths

BUILD_DIR := build
SRC_DIR   := .
OUT_DIR   := ..

# Files

FLAGS_SRC := create_flags.c
FLAGS_BIN := $(BUILD_DIR)/create_flags
FLAGS_INC := flags.asm.inc

ASM_SRC   := load_elf_binary.asm
ASM_OBJ   := $(BUILD_DIR)/load_elf_binary.o
ASM_BIN   := $(BUILD_DIR)/load_elf_binary

# Default target

all: flags loader

# Ensure build directory exists

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# --------------------------------------------------

# Generate flags.asm.inc

# This rule runs every time (PHONY dependency)

# --------------------------------------------------

.PHONY: flags
flags: $(BUILD_DIR)
	$(CC) $(FLAGS_SRC) -o $(FLAGS_BIN)
	$(FLAGS_BIN)
	rm -f $(FLAGS_BIN)

# --------------------------------------------------

# Assemble + link custom ELF loader (no gcc)

# --------------------------------------------------

loader: $(ASM_SRC) flags | $(BUILD_DIR)
	$(AS) -f elf64 $(ASM_SRC) -o $(ASM_OBJ)
	$(LD) -static -o $(ASM_BIN) $(ASM_OBJ)
	cp $(ASM_BIN) $(SRC_DIR)

# --------------------------------------------------

# Cleanup

# --------------------------------------------------

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	rm -f $(FLAGS_INC)
	rm -f $(OUT_DIR)/load_elf_binary
