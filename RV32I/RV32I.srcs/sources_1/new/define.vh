
`define simulation 1

`define R_type 7'b0110011
`define B_type 7'b1100011
`define S_type 7'b0100011
`define I_type 7'b0010011
`define IL_type 7'b0000011
`define LUI_type 7'b0110111
`define AUIPC_type 7'b0010111
`define JAL_type 7'b1101111
`define JALR_type 7'b1100111




`define ADD    4'b0000
`define SUB    4'b1000
`define SLL    4'b0001
`define SLT    4'b0010
`define SRL    4'b0101
`define SRA    4'b1101
`define SLTU   4'b0011
`define XOR    4'b0100
`define AND    4'b0111
`define OR     4'b0110


// `define BEQ   3'b000
// `define BNE   3'b001
// `define BLT   3'b100
// `define BGE   3'b101
// `define BLTU  3'b110
// `define BGEU  3'b111


// B-type instruction
`define BEQ 4'b0_000
`define BNE 4'b0_001
`define BLT 4'b0_100
`define BGE 4'b0_101
`define BLTU 4'b0_110
`define BGEU 4'b0_111

// S-type instruction
`define SB 3'b000
`define SH 3'b001
`define SW 3'b010

// IL-type instruction
`define LB 3'b000
`define LH 3'b001
`define LW 3'b010
`define LBU 3'b100
`define LHU 3'b101