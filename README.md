# MIPS32 CPU

## Requirements

* THUCST Thinpad rev.3 (early 2018)
* Vivado 2018
* mips-mti-elfi toolchain
* Python 2.7
* Tensorflow 1.3.0

## Monitor

To build and run the monitor:

1. Use Vivado to compile the project, yielding a .bit file
2. Run `make ON_FPGA=y`  at `thinpad_top.test` directory, yielding the kernel program in binary format `kernel.bin`
3. Write `kernel.bin` into the Flash
4. Write the .bit file into the FPGA
5. Connect the terminal to the thinpad
6. Click the reset button

The screen should display "MONITOR for MIPS32 - initialized" after these steps.

For more information, please refer to https://github.com/z4yx/supervisor-mips32.

## Chatbot

We've developed a sequence-to-sequence chatbot for our MIPS32 CPU.
We implemented the model in Python 2.7 and Tensorflow first, and we then implemented a MIPS32 Assembly version of the inference code for the CPU we developed. The code of the chatbot is located at `/app`.

Based on the previously prepared FPGA, you may follow the steps below to get the chatbot work:

1. Prepare the datasets at the `app/data` directory. We use:
   * [Cornell Movie-Dialogs Corpus](https://www.cs.cornell.edu/~cristian/Cornell_Movie-Dialogs_Corpus.html)
   * [PersonaChat ConvAI2 Dataset](http://convai.io/)

   And we also use the 50-dimensional [GloVe](https://nlp.stanford.edu/projects/glove/) word vectors.

2. Train the sequence-to-sequence model:

```
cd app/tf
python data_pre.py
python main.py --is_train
```

3. Dump the model parameters:

```
cd app/tf
python main.py --run_dump
cp params.S ../as
```

4. Build the chatbot for our MIPS32 CPU:

```
cd app/as
make
```

5. Write `params.bin` into the BaseRAM
6. Write `kernel.bin` into the Flash
7. Click the reset button
8. Now you can chat with the chatbot!

