# Yet Another RISC-V Processor

- [Video Explanation (Thai)](https://youtu.be/UCgONqoULyc)
- [Article (English)](https://blog.ppat.dev/2022/12/how-to-build-very-simple-risc-v.html)

This is a repository containing the code for the final project for HW SYN LAB course. A simple RISC-V core is built in Verilog following RV32I specification.
A calculator program is then implement using C and cross-compiled then flashed into BASYS3 board.

Directory Structure
```
- verilog: All verilog and testbenches code implementing the RV32I
- basys3: Bitstream output from Vivado
- calculator: Code implementing the calculator
- test: Patch set for patching risc-v test harness
- demo: Hello world program
```
