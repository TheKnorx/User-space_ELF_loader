/* 	The purpose of this program is to convert C constants and flags
 * 	stored in C-header files to assembly readable include files
*/

#include <fcntl.h>  // oflags for open syscall
#include <elf.h> 	// for elf magic number
#include <asm/unistd_64.h> // for syscall numbers
#include <stdio.h>  // for file operations and printing, and std* constants
#include <sys/mman.h>  // for mmap flags

// int fprintf(FILE *restrict stream, const char *restrict format, ...);
#define INSERT(format_str) fprintf(include_file, format_str)
#define CREATE_ASM_CONSTANT(CONST) "%s equ %d\n", #CONST, CONST
#define CREATE_ASM_VARIABLE(VAR) "%s db \"%s\"\n", #VAR, VAR

#ifndef _MAP_FAILED
#define _MAP_FAILED (-1)
#endif
#define STDOUT 1


int main(){
	const char* filename = "flags.asm.inc";

	printf("--> Opening file %s\n", filename);
	// FILE *fopen(const char *restrict pathname, const char *restrict mode);
	FILE* include_file = fopen(filename, "w");  // create/open the include file 
	if (NULL == include_file) {perror("Failed to open file"); return -1;}

	printf("--> Writing flags and constants to file\n");

	/**** Write them syscall numbers into the file ****/
	{
		INSERT( "; ---- syscall numbers ----\n" );
		INSERT( CREATE_ASM_CONSTANT(__NR_read) );
		INSERT( CREATE_ASM_CONSTANT(__NR_write) );
		INSERT( CREATE_ASM_CONSTANT(__NR_open) );
		INSERT( CREATE_ASM_CONSTANT(__NR_mmap) );
		INSERT( CREATE_ASM_CONSTANT(__NR_read) );
	}
	/**** general constants ****/
	{
		INSERT( "\n; ---- general constants ----\n" );
		INSERT( CREATE_ASM_CONSTANT(BUFSIZ) );
		INSERT( CREATE_ASM_CONSTANT(STDOUT) );
	}

	/**** write all the flags of open() into the include file ****/
	{
		INSERT( "\n; ---- open() oflags ----\n" );
		INSERT( CREATE_ASM_CONSTANT(O_RDONLY) );
		INSERT( CREATE_ASM_CONSTANT(O_WRONLY) );
		INSERT( CREATE_ASM_CONSTANT(O_RDWR) );
		INSERT( CREATE_ASM_CONSTANT(O_CREAT) );
	}

	/**** flags and constants needed for mmap and munmap ****/
	{
		fprintf(include_file, "\n; ---- map flags ----\n");
		INSERT( CREATE_ASM_CONSTANT(PROT_EXEC) );
		INSERT( CREATE_ASM_CONSTANT(PROT_READ) );
		INSERT( CREATE_ASM_CONSTANT(PROT_WRITE) );
		INSERT( CREATE_ASM_CONSTANT(PROT_NONE) );

		INSERT( CREATE_ASM_CONSTANT(MAP_SHARED) );
		INSERT( CREATE_ASM_CONSTANT(MAP_SHARED_VALIDATE) );
		INSERT( CREATE_ASM_CONSTANT(MAP_PRIVATE) );
		INSERT( CREATE_ASM_CONSTANT(MAP_ANONYMOUS) );
		INSERT( CREATE_ASM_CONSTANT(MAP_STACK) );

		INSERT( CREATE_ASM_CONSTANT(_MAP_FAILED));
	}
	
	/**** write elf magic number into the include file ****/
	// https://github.com/torvalds/linux/blob/master/include/uapi/linux/elf.h#L362
	{
		INSERT( "\n; ---- efi constants ----\n" );
		INSERT( CREATE_ASM_CONSTANT(ELFMAG0) );
		INSERT( CREATE_ASM_CONSTANT(ELFMAG1) );
		INSERT( CREATE_ASM_CONSTANT(ELFMAG2) );
		INSERT( CREATE_ASM_CONSTANT(ELFMAG3) );
		INSERT( CREATE_ASM_VARIABLE(ELFMAG) );
	}

	printf("--> Closing file %s\n", filename);
	// int fclose(FILE *stream);
	if (fclose(include_file) == EOF){perror("Failed closing file"); return -1;}

	return 0;
}