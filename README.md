## MIPS32 CPU

### Software Requirements

* Vivado 2018
* mips-mti-elfi toolchain
* Python 2.7
* Tensorflow 1.3.0

### Build & Run - Supervisor

1. Set the output clock frequency of the pll IP properly (Please refer to Wiki)
2. Use vivado to compile the project, yielding a .bit file
3. Run `make ON_FPGA=y`  at `thinpad_top.test` directory, yielding the kernel program in binary format `kernel.bin`
4. Write `kernel.bin` into ExtRAM
5. Write the .bit file into FPGA
6. Connect the terminal to the thinpad
7. Click the reset button

The terminal should display "MONITOR for MIPS32 - initialized" after these steps.

### Debug

You may put a short MIPS32 program at `thinpad_top.test/kern_debug/init.S` for debugging.

Please run `make debug=y` to compile the kernel in this case.

And note that currently the lowest 16 bits of register $30 are binded to the LEDs for debugging.
