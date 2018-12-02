RM	:= rm -f
ifeq ($(OS),Windows_NT)
# Windows Host
GCCPREFIX	:= mips-mti-elf-
else
#GCCPREFIX	:= mipsel-linux-gnu-
GCCPREFIX	:= mips-mti-elf-
endif
QEMU := qemu-system-mipsel
LD	:= $(GCCPREFIX)ld
CC	:= $(GCCPREFIX)gcc
MODULE	:= main
OBJDIR	:= obj
INCLUDE	:= include

SRCDIR	:= kern

LDSCRIPT	:= kern/kernel.ld
SRC_S	:= $(foreach sdir, $(SRCDIR), $(wildcard $(sdir)/*.S))
OBJ_S	:= $(patsubst $(SRCDIR)/%.S, $(OBJDIR)/%.o, $(SRC_S))
SRC_c	:= $(foreach sdir, $(SRCDIR), $(wildcard $(sdir)/*.c))
OBJ_c	:= $(patsubst $(SRCDIR)/%.c, $(OBJDIR)/%.o, $(SRC_c))

TARGET	:= kernel.elf
ASFLAG	:= -D__ASSEMBLY__ -EL -g -mips32r2 -mno-abicalls -mno-shared

override ON_FPGA ?= y

ifeq ($(ON_FPGA), y)
	MACH_DEF = -DMACH_FPGA
else
   	MACH_DEF = -DMACH_QEMU
endif
ASFLAG += $(MACH_DEF)

override EN_INT ?= n
ifeq ($(EN_INT), y)
	ASFLAG += -DENABLE_INT
	EN_TLB = n
endif

.PHONY: all clean show-utest

all: checkdirs $(TARGET) kernel.bin params.bin

$(TARGET): $(OBJ_S) $(LDSCRIPT)
	$(LD) $(OBJ_S) -T$(LDSCRIPT)

$(OBJ_S): $(OBJDIR)/%.o : $(SRCDIR)/%.S
	$(CC) -o $@ $< -c -I$(INCLUDE) $(ASFLAG)

checkdirs: $(OBJDIR)

$(OBJDIR):
	mkdir $@

kernel.bin: $(TARGET)
	@$(GCCPREFIX)objcopy -j .text -j .text.* -O binary -v $< kernel.bin

params.bin: $(TARGET)
	@$(GCCPREFIX)objcopy -j .rodata -j .rodata.* -O binary -v $< params.bin

show-utest: $(TARGET)
	@$(GCCPREFIX)objdump -D $< | grep "^[0-9a-f]\{8\} <UTEST_" | grep -n --color=auto 'UTEST_'

.PHONY: commits-num show-utest sim clean

sim: $(TARGET)
	$(QEMU) -M mipssim -m 8M -kernel $< -vnc :0 -serial tcp::6666,server -s

commits-num:
	@git log --pretty=format:"commit %H" | grep -c 'commit'

clean:
	-$(RM) -r $(OBJDIR)
