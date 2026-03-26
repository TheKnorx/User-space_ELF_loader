/* 	The purpose of this program is to convert C flags stored in C-header files
* 	to assembly readable include files
*/

// #define FLAG_FORMAT_STRING(c_flag_str, c_flag_val) "%s equ %d\n", c_flag_str, c_flag_val
#define FLAG_FORMAT_STRING(flag) "%s equ %d\n", #flag, flag

#include <fcntl.h>  // oflags for open syscall
#include <elf.h> 	// for elf magic number
#include <asm/unistd_64.h> // for syscall numbers
#include <stdio.h>  // for file operations and printing, etc

int main(){
	const char* filename = "flags.asm.inc";

	printf("--> Opening file %s\n", filename);
	// FILE *fopen(const char *restrict pathname, const char *restrict mode);
	FILE* include_file = fopen(filename, "w");  // create/open the include file 
	if (NULL == include_file) {perror("Failed to open file"); return -1;}

	printf("--> Writing flags and constants to file\n");

	// **** Write them syscall numbers into the file ****
	{
		fprintf(include_file, "; ---- syscall numbers ----\n");
		fprintf(include_file, FLAG_FORMAT_STRING(__NR_read));
		fprintf(include_file, FLAG_FORMAT_STRING(__NR_open));
		fprintf(include_file, FLAG_FORMAT_STRING(__NR_mmap));
	}

	// **** write all the flags of open() into the include file ****
	// int fprintf(FILE *restrict stream,
    //             const char *restrict format, ...);
	{
		fprintf(include_file, "\n; ---- open() oflags ----\n");
		fprintf(include_file, FLAG_FORMAT_STRING(O_RDONLY));
		fprintf(include_file, FLAG_FORMAT_STRING(O_WRONLY));
		fprintf(include_file, FLAG_FORMAT_STRING(O_RDWR));
		fprintf(include_file, FLAG_FORMAT_STRING(O_CREAT));
	}

	// **** flags and constants needed for mmap and munmap ****
	{
		fprintf(include_file, "\n; ---- map constants ----\n");
		fprintf(include_file, FLAG_FORMAT_STRING(BUFSIZ));
	}
	
	// **** write elf magic number into the include file ****
	// https://github.com/torvalds/linux/blob/master/include/uapi/linux/elf.h#L362
	{
		fprintf(include_file, "\n; ---- efi constants ----\n");
		fprintf(include_file, FLAG_FORMAT_STRING(ELFMAG0));
		fprintf(include_file, FLAG_FORMAT_STRING(ELFMAG1));
		fprintf(include_file, FLAG_FORMAT_STRING(ELFMAG2));
		fprintf(include_file, FLAG_FORMAT_STRING(ELFMAG3));
		fprintf(include_file, "ELFMAG db \"%s\"", ELFMAG);
	}

	printf("--> Closing file %s\n", filename);
	// int fclose(FILE *stream);
	if (fclose(include_file) == EOF){perror("Failed closing file"); return -1;}

	return 0;
}