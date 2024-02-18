# Design-and-Verify-Multi-Cycle-RISC-Processor 

## A. Objectives: 
To design and verify a simple pipelined RISC processor in Verilog  
## B. Processor Specifications: 
1. The instruction size and the words size is 32 bits .
2. 16 32-bit general-purpose registers: from R0 to R15.
3. 32-bit special purpose register for the program counter (PC)
4. 32-bit special purpose register for the stack pointer (SP), which points to the topmost empty element of
the stack. This register is visible to the programmer.
5. The program memory layout comprises the following three segments:
(i) Static data segment
(ii) Code segment
(iii) Stack segment. It is a LIFO (Last in First out) data structure. This machine has explicit instructions
that enables the programmer to push/pop elements on/from the stack. The stack stores the
return address, registers’ values upon function calls, etc.
6. The processor has two separate physical memories, one for instructions and the other one for data. The
data memory stores both the static data segment and the stack segment.
7. Four instruction types (R-type, I-type, J-type, and S-type).
8. Separate data and instructions memories.
9. Word-addressable memory.
10. You need to generate the required signals from the ALU to calculate the condition branch outcome
(taken/ not taken). These signals might include zero, carry, overflow, etc.
## C. Instruction Types and Formats:
### 1. R-Type (Register Type): 
 **4-bit Rd: destination register**
 
 **4-bit Rs1: first source register**
 
**4-bit Rs2: second source register**

**14-bit unused** 
### 2. I-Type (Immediate Type) 
4-bit Rd: destination register 

4-bit Rs1: first source register

16-bit immediate: unsigned for logic instructions, and signed otherwise.

2-bit unused







