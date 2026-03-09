# User-space_ELF_loader
An assembly implementation of the Linux kernel function `load_elf_binary` in [`fs/binfmt_elf.c`](https://github.com/torvalds/linux/blob/master/fs/binfmt_elf.c)
The goal is to have an implementation capable loading a 64bit x84 binary. 
Restrictions: the executable to be loaded MUST be statically linked - so no position independent code (`-no-pie`) - and does not engage in suffisticated stack operations as this loader implementation is only an extended proof of concept. 
