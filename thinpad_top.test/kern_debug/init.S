#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
.set noreorder
.set noat
.global START
START:
	lui t1, 0x8040
    addiu t2, 1
    sw t2, (t1)
	lw $30, (t1)
