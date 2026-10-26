# Debayering-filter
Implementation of a Debayering filter in VHDL for a Zynq SoC FPGA
For the implementation of the Debayering filter (Debayering.vhd) using an RTL architecture, I created 3 structural modules:

The component for calculating the pixel's RGB components using the averages of neighboring pixels (Mean.vhd).

The component for converting the input data from serial to 3x3 parallel, using 2 RAM FIFOs (stp.vhd).

The component for controlling the state of the sub-modules (FSM.vhd).
