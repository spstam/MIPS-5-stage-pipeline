# Single Cycle MIPS Processor - Extended Instructions

This document details the extra instructions implemented in this single-cycle MIPS processor.  For general information about the processor, please refer to the main [README](../README.md).

## Extended Instructions

This implementation adds the following instructions to the basic MIPS processor:

* **BEQ:** Branch if equal.
* **BNE:** Branch if not equal.
* **J:** Jump to a specified address.

## Implementation Details

* **BEQ/BNE:** These instructions use the ALU to compare two register values and calculate the branch target address based on the PC and the sign-extended immediate value. 
* **J:** This instruction directly modifies the PC with the jump target address derived from the instruction.

## Verification

These instructions have been verified using the provided testbench, which includes test cases specifically designed to exercise the branch and jump functionality.

## Note

While these instructions have been tested, there may still be edge cases or bugs. Please report any issues you encounter.
