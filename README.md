# MIPS 5-Stage Pipeline Processor

This repository contains a Verilog implementation of a 5-stage pipelined MIPS processor. 

## Features

* **Pipelined Execution:** Implements a 5-stage pipeline (IF, ID, EX, MEM, WB).
* **Instruction Support:** Supports a subset of the MIPS instruction set, including:
    * **R-type instructions:**  (e.g., ADD, SUB, AND, OR, SLT)
    * **I-type instructions:** LW, SW, BEQ, ADDI
* **Hazard Detection and Resolution:**
    * **Data Hazards:**  Implements data forwarding (bypassing) to mitigate data dependencies between instructions.
    * **Control Hazards:**  Detects and resolves control hazards caused by branch instructions using stalls.

## Implementation Details

* **Modular Design:** The processor is designed with a modular approach, separating different pipeline stages into individual components for clarity and maintainability.
* **Verilog HDL:**  The processor is implemented using Verilog hardware description language.
* **Testbench:**  Includes a testbench for verification and debugging.

## Future Work

* **Extend Instruction Set:** Add support for more MIPS instructions (e.g., jump instructions, logical instructions).
* **Enhance Hazard Handling:** Implement more advanced hazard detection and resolution techniques (e.g., branch prediction).

## Contributing

Contributions are welcome! Feel free to submit pull requests or open issues for bug reports and feature suggestions.
