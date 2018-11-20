## MIPS32 CPU

### Build & Run

1. Use vivado to compile the project, yielding a .bit file
2. Run `make ON_FPGA=y`  at `thinpad_top.test` directory, yielding the kernel program in binary format `kernel.bin`
3. Write `kernel.bin` into ExtRAM
4. Write the .bit file into FPGA
5. Connect the terminal to the thinpad
6. Click the reset button

The terminal should display "MONITOR for MIPS32 - initialized" after these steps.

