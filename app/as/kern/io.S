#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
#include <hyper.h>
    .set noreorder
    .set noat
    .p2align 2
    .text
    .global read_sentence
    .global write_sentence
    .global write_string
    .global puts
    .global puts_debug
    .global putchar
    .global putspace
    .global putnewline
    .global write_int
    .global stop

read_sentence:
    addiu sp, sp, -16
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)

    lui s0, %hi(post_raw) // address
    addiu s0, %lo(post_raw) 
    ori s1, $0, 0 // length
    ori s2, $0, '\n' // ending char '\n'

    .read_char:
        jal READSERIAL 
        nop
        ori a0, v0, 0
        jal putchar
        nop
        beq v0, s2, .read_done // finish reading on '\n'
        nop
        sb v0, (s0)
        addiu s0, s0, 1
        addiu s1, s1, 1
        j .read_char
        nop

    .read_done:
    ori a0, $0, ' '
    sb a0, (s0)
    ori a0, $0, 'E'
    sb a0, 1(s0)
    ori a0, $0, 'O'
    sb a0, 2(s0)
    ori a0, $0, 'S'
    sb a0, 3(s0)
    ori a0, $0, ' '
    sb a0, 4(s0)
    sb $0, 5(s0)
    lw ra, 0(sp) 
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    addiu sp, sp, 16
    jr ra
    nop

write_sentence:
    addiu sp, sp, -4
    sw ra, 0(sp)

    lui a0, %hi(post_raw)
    addiu a0, %lo(post_raw)
    jal puts
    nop

    lw ra, 0(sp)
    addiu sp, sp, 4
    jr ra
    nop 

putchar:
    // use serial
    # j WRITESERIAL
    # nop
    addiu sp, -8
    sw ra, (sp)
    sw s0, 4(sp)
    
    ori s0, a0, 0
    jal WRITESERIAL
    nop

    lui t0, %hi(screen)
    addiu t0, %lo(screen)
    lui t3, 0x9000

    lui t1, %hi(screen_row)
    addiu t1, %lo(screen_row)
    lw t1, (t1)
    .L_find_screen_row:
        beq t1, $0, .L_find_screen_row_done
        nop
        addiu t1, -1
        addiu t0, SCREEN_COLS 
        addiu t3, SCREEN_COLS 
        j .L_find_screen_row
        nop
    .L_find_screen_row_done:
    lui t1, %hi(screen_col)
    addiu t1, %lo(screen_col)
    lw t2, (t1)
    addu t0, t0, t2
    addu t3, t3, t2

    sb s0, (t0)
    sb s0, (t3)
    
    addiu t2, 1

    ori t4, $0, SCREEN_COLS
    beq t2, t4, .newline
    nop
    ori t4, $0, '\n'
    beq s0, t4, .newline
    nop
    j .newline_done
    nop
    .newline:
        lui t2, 0
        lui t5, %hi(screen_row)
        addiu t5, %lo(screen_row)
        lw t6, (t5)
        addiu t6, 1
        sw t6, (t5)
    .newline_done:

    sw t2, (t1)
    
    lw ra, (sp)
    lw s0, 4(sp)
    addiu sp, 8

    jr ra
    nop

putspace:
    addiu sp, -4
    sw ra, 0(sp)

    ori a0, $0, ' '
    jal putchar
    nop

    lw ra, 0(sp)
    addiu sp, 4
    jr ra
    nop

putnewline:
    addiu sp, -4
    sw ra, 0(sp)

    ori a0, $0, '\n'
    jal putchar
    nop

    lw ra, 0(sp)
    addiu sp, 4
    jr ra
    nop

write_string:
    addiu sp, -8
    sw ra, 0(sp)
    sw s0, 4(sp)

    ori s0, a0, 0
    .L0:
        lb a0, (s0)
        beq a0, zero, .write_string_done
        nop
        jal putchar      
        nop
        addiu s0, s0, 1        
        j .L0
        nop

    .write_string_done:

    lw ra, 0(sp)
    lw s0, 4(sp)
    addiu sp, sp, 8

    jr ra
    nop   

puts:
    addiu sp, -4
    sw ra, 0(sp)

    jal write_string
    nop
    ori a0, $0, '\n'
    jal putchar
    nop

    lw ra, 0(sp)
    addiu sp, sp, 4
    jr ra
    nop 

hex:
    .asciz "0123456789ABCDEF"
.p2align 2
write_int:
    addiu sp, -24
    sw ra, (sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)

    addiu sp, -32

    ori s0, $0, 0
    ori s1, $0, 8
    ori s2, a0, 0
    ori s3, sp, 0
    lui s4, %hi(hex)
    addiu s4, %lo(hex)
    
    .store_digits:
        beq s0, s1, .write_digits
        nop
        andi t0, s2, 0xf
        sw t0, (s3)
        addiu s0, 1
        srl s2, s2, 4
        addiu s3, 4      
        j .store_digits
        nop
    .write_digits:
        addiu s3, -4
        lw a0, (s3)
        addu a0, a0, s4
        nop
        nop
        nop
        nop
        lb a0, (a0)
        jal putchar
        nop
        beq s3, sp, .write_int_done
        nop
        j .write_digits
        nop
    
    .write_int_done:
    addiu sp, 32

    lw ra, (sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    addiu sp, 24
    jr ra
    nop

.p2align 2
debug_message:
    .asciz "Debug!"

.p2align 2
puts_debug:
     // print welcome message
    lui a0, %hi(debug_message)
    addiu a0, %lo(debug_message)
    jal puts
    nop

stop:
    j stop
    nop