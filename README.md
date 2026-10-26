# Debayering-filter
Implementation of a Debayering filter in VHDL for a Zynq SoC FPGA using an RTL architecture, with 3 structural modules:

The component for calculating the pixel's RGB components using the averages of neighboring pixels (Mean.vhd).

The component for converting the input data from serial to 3x3 parallel, using 2 RAM FIFOs (stp.vhd).

The component for controlling the state of the sub-modules (FSM.vhd).

The interface I used for the communication between the programmable logic (PL) and the processing system (PS) is AXI4-stream.
