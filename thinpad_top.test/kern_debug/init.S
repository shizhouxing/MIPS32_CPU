#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
.set noreorder
.set noat
.section .text.init
.global START
START:
    j START
    nop
