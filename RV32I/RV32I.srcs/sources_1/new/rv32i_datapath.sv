`timescale 1ns / 1ps
`include "define.vh"


module rv32i_datapath (
    input         clk,
    input         rst,
    input         pc_en,
    input         rf_we,
    input         alu_src,
    input  [ 3:0] alu_control,
    input  [31:0] instr_data,
    input  [31:0] bus_rdata,
    input  [2:0]  rfwd_src,
    input         branch,
    input         jalr_sel,
    input         jal_sel,
    output [31:0] instr_addr,
    output [31:0] bus_addr,
    output [31:0] bus_wdata
 


);
    logic [31:0]  alu_result, alurs2_data,imm_data;
    logic [31:0] rfwb_data;
    logic        btaken;
    logic [31:0] auipc;
    logic [31:0] j_type;
    logic [31:0] auipc_out;
    logic [31:0] jal_out;

    
    logic [31:0] i_dec_rs1,o_dec_rs1,i_dec_rs2,o_dec_rs2,i_dec_imm,o_dec_imm;
    logic [31:0]  o_exe_rs2,o_exe_alu_result;
    logic [31:0] o_mem_drdata;
    




    assign bus_daddr  = o_exe_alu_result;
    assign bus_wdata = o_exe_rs2;
  

    // pc_counter U_PC (
    //     .clk(clk),
    //     .rst(rst),
    //     .pc_en(pc_en),
    //     .btaken(btaken),
    //     .branch(branch),
    //     .jalr_sel(jalr_sel),
    //     .jal_sel(jal_sel),
    //     .rd1(o_dec_rs1),
    //     .imm_data(o_dec_imm),
    //     .program_counter(instr_addr),
    //     .auipc_out(auipc_out),
    //     .jal_out(jal_out)

    // );
    
program_counter U_PC (
        .clk            (clk),
        .rst            (rst),
        .pc_en          (pc_en),
        .btaken         (btaken),      // from alu comparator
        .branch         (branch),      // from Control unit for B-type
        .jal            (jal_sel),
        .jalr           (jalr_sel),
        .imm_data       (o_dec_imm),
        .rd1            (o_dec_rs1),
        .program_counter(instr_addr),
        .pc_4_out       (j_type),
        .pc_imm_out     (auipc)
    );

    //decode
    register_file U_REG_FILE (
        .clk(clk),
        .rst(rst),
       .RA1(instr_data[19:15]),

       .RA2(instr_data[24:20]),

       .WA(instr_data[11:7]),
        .Wdata(rfwb_data),
        .rf_we(rf_we),
        .RD1(i_dec_rs1),
        .RD2(i_dec_rs2)
    );
    imm_extender U_IMM_EXTENDER (
        .instr_data(instr_data),
        // .instr_data(ir),
        .imm_data  (imm_data)
    );



    register U_DEC_REG_RS1(
        .clk(clk),
        .rst(rst),
        .data_in(i_dec_rs1),
        .data_out(o_dec_rs1)
    );

    register U_DEC_REG_RS2(
        .clk(clk),
        .rst(rst),
        .data_in(i_dec_rs2),
        .data_out(o_dec_rs2)
    );

    register U_DEC_IMM_EXT(
        .clk(clk),
        .rst(rst),
        .data_in(imm_data),
        .data_out(o_dec_imm)
    );
///execute



    mux2x1 U_MUX_ALUSRC_RS2 (
        .in0(o_dec_rs2),
        // .in0(o_dec_rs2),
        .in1(o_dec_imm),
        .mux_sel(alu_src),
        .out_mux(alurs2_data)
    );


    alu U_ALU (
        .rd1(o_dec_rs1),
        .rd2(alurs2_data),
        .alu_control(alu_control),
        .alu_result(alu_result),
        .btaken(btaken)
    );
    register U_EXE_ALU_RESULT(
        .clk(clk),
        .rst(rst),
        .data_in(alu_result),
        .data_out(o_exe_alu_result) //to DAddr
    );

    register U_EXE_REG_RS2(
        .clk(clk),
        .rst(rst),
        .data_in(o_dec_rs2),  //from alu result
        .data_out(o_exe_rs2)    //to data mem_wdata
    );

    //MEM to WB
    register U_MEM_REG_DRDATA(
        .clk(clk),
        .rst(rst),
        .data_in(bus_drdata),
        .data_out(o_mem_drdata) 
    );

     mux_5x1 U_WB_MUX (
        .in0    (alu_result),  // from ALU Result , because of process with execute state
        .in1    (o_mem_drdata),            // from data memory
        .in2    (o_dec_imm),         // from imm extend, for LUI
        .in3    (auipc),             // from pc + imm extend, for AUIPC
        .in4    (j_type),            // from PC + 4, for JAL/JALR
        .mux_sel(rfwd_src),
        .out_mux(rfwb_data)
    );

    //WB

    // always_comb begin 
    
    //     case (rfwd_src)
    //         3'b000: rfwb_data = alu_result;   //from alu result
    //         3'b001: rfwb_data = o_mem_drdata;//loaded_data;
    //         3'b010: rfwb_data = o_dec_imm; //lui
    //         3'b011: rfwb_data = auipc_out;
    //         3'b100: rfwb_data = jal_out; //jal
             
    //         default: rfwb_data = 32'b0;
    //     endcase
    // end


endmodule

module mux_5x1 (
    input        [31:0] in0,      // sel 0
    input        [31:0] in1,      // sel 1
    input        [31:0] in2,      // sel 2
    input        [31:0] in3,      // sel 3
    input        [31:0] in4,      // sel 4
    input        [ 2:0] mux_sel,
    output logic [31:0] out_mux
);

    always_comb begin
        case (mux_sel)
            3'b000:  out_mux = in0;
            3'b001:  out_mux = in1;
            3'b010:  out_mux = in2;
            3'b011:  out_mux = in3;
            3'b100:  out_mux = in4;
            default: out_mux = 32'hxxxx;
        endcase
    end

endmodule


module register_file (
    input         clk,
    input         rst,
    input  [ 4:0] RA1,
    input  [ 4:0] RA2,
    input  [ 4:0] WA,
    input  [31:0] Wdata,
    input         rf_we,
    output [31:0] RD1,
    output [31:0] RD2
);

    logic [31:0] register_file[1:31];

`ifdef simulation
    initial begin
        for (int i = 1; i < 32; i++) begin
            register_file[i] = i;
        end
    end
`endif

    always_ff @(posedge clk) begin

        if (!rst & rf_we) begin
            register_file[WA] <= Wdata;
        end

    end
   


    assign RD1 = (RA1 != 0) ? register_file[RA1] : 0;
    assign RD2 = (RA2 != 0) ? register_file[RA2] : 0;




endmodule
module alu (
    input        [31:0] rd1,          // 이전 a
    input        [31:0] rd2,          // 이전 b
    input        [ 3:0] alu_control,  // 이전 alu_ctrl
    // input        [31:0] instr_addr,   // AUIPC용 PC값 (기존 데이터패스의 instr_addr)
    output logic [31:0] alu_result,   // 이전 result
    output logic        btaken         // 이전 branch_flag / btaken
);

    // 1. 산술/논리 연산 블록 (alu_result 결정)
    always_comb begin
        alu_result = 32'b0;
        case (alu_control)
            `ADD    : alu_result = rd1 + rd2;
            `SUB    : alu_result = rd1 - rd2;
            `SLL    : alu_result = rd1 << rd2[4:0];
            `SRL    : alu_result = rd1 >> rd2[4:0];
            `SRA    : alu_result = $signed(rd1) >>> rd2[4:0];
            `SLT    : alu_result = ($signed(rd1) < $signed(rd2)) ? 32'd1 : 32'd0;
            `SLTU   : alu_result = (rd1 < rd2) ? 32'd1 : 32'd0;
            `XOR    : alu_result = rd1 ^ rd2;
            `OR     : alu_result = rd1 | rd2;
            `AND    : alu_result = rd1 & rd2;
           
            default : alu_result = 32'b0;
        endcase
    end
   

    always_comb begin
        btaken = 0;
        case (alu_control)
            `BEQ: begin
                if (rd1 == rd2) btaken = 1;  // true : pc = PC + IMM
                else btaken = 0;  // false : pc = pc + 4
            end
            `BNE: begin
                if (rd1 != rd2) btaken = 1;  // true : pc = PC + IMM
                else btaken = 0;  // false : pc = pc + 4
            end
            `BLT: begin
                if ($signed(rd1) < $signed(rd2))
                    btaken = 1;  // true : pc = PC + IMM
                else btaken = 0;  // false : pc = pc + 4
            end
            `BGE: begin
                if ($signed(rd1) >= $signed(rd2))
                    btaken = 1;  // true : pc = PC + IMM
                else btaken = 0;  // false : pc = pc + 4
            end
            `BLTU: begin
                if (rd1 < rd2) btaken = 1;  // true : pc = PC + IMM
                else btaken = 0;  // false : pc = pc + 4
            end
            `BGEU: begin
                if (rd1 >= rd2) btaken = 1;  // true : pc = PC + IMM
                else btaken = 0;  // false : pc = pc + 4
            end
        endcase
    end

endmodule

///fetch, execute

// module pc_counter (
//     input               clk,
//     input               rst,
//     input               pc_en,
//     input               btaken,
//     input               branch,
//     input               jalr_sel,
//     input               jal_sel,
//     input        [31:0] imm_data,
//     input        [31:0] rd1,
//     output logic [31:0] program_counter,
//     output logic [31:0] auipc_out,
//     output logic [31:0] jal_out
// );
//    logic [31:0] pc_4_out;
//    logic [31:0] pc_imm_out;
//    logic [31:0] pc_next;
   
//    logic [31:0] pc_last;
//    logic [31:0] o_exe_pcnext;

  
  
//    assign auipc_out = pc_imm_out;
//    assign jal_out = pc_4_out;
// //    wire pc_sel = (branch & btaken) | jal_sel;

// mux2x1 U_JAL_MUX(
//    .in0(pc_4_out),
//    .in1(pc_imm_out),
//    .mux_sel(jal_sel | (btaken & branch)),
//    .out_mux(pc_last)
// );

//    mux2x1 U_PC_MUX(
//    .in0(program_counter),
//    .in1(rd1),
//    .mux_sel(jalr_sel),
//    .out_mux(pc_next)
// );

//    pc_alu U_pc_IMM (
//         .a(imm_data),
//         .b(pc_next),
//         .pc_alu_out(pc_imm_out)

//     );

//     pc_alu U_pc_ALU4 (
//         .a(32'd4),
//         .b(program_counter),
//         .pc_alu_out(pc_4_out)

//     );

//      register U_PCNEXT_REG(
//         .clk(clk),
//         .rst(rst),
//         .data_in(pc_last),
//         .data_out(o_exe_pcnext)
//      );

//     ///fest
//    register_en U_REG_en (
//        .clk(clk),
//        .rst(rst),
//        .en(pc_en),
//        .data_in(o_exe_pcnext),//o_exe_pcnext
//        .data_out(program_counter)
//    );
//endmodule

module program_counter (
    input         clk,
    input         rst,
    //input [31:0] instr_addr
    input         pc_en,            // from Control unit for PC register
    input         btaken,           // from alu for B-type
    input         branch,           // from Control unit for B-type
    input         jal,
    input         jalr,
    input  [31:0] imm_data,
    input  [31:0] rd1,
    output [31:0] program_counter,
    output [31:0] pc_4_out,         // for J type, PC +4
    output [31:0] pc_imm_out        // for UA type , PC + imm
);
    logic [31:0] pc_next, pc_jtype, o_exe_pcnext;

    // execute
    // jalr mux
    mux_2x1 PC_JTYPE_MUX (
        .in0(program_counter),  // sel 0
        .in1(rd1),  // sel 1
        .mux_sel(jalr),
        .out_mux(pc_jtype)
    );
    pc_alu U_PC_IMM (
        .a(imm_data),
        .b(pc_jtype),
        .pc_alu_out(pc_imm_out)
    );
    pc_alu U_PC_4 (
        .a(32'd4),
        .b(program_counter),
        .pc_alu_out(pc_4_out)
    );
    mux_2x1 PC_NEXT_MUX (
        .in0(pc_4_out),  // sel 0
        .in1(pc_imm_out),  // sel 1
        .mux_sel(jal | (btaken & branch)),
        .out_mux(pc_next)
    );

    register U_PCNEXT_REG (
        .clk(clk),
        .rst(rst),
        .data_in(pc_next),
        .data_out(o_exe_pcnext)
    );

    // fetch    
    register_en U_PC_REG (
        .clk(clk),
        .rst(rst),
        .en(pc_en),
        .data_in(o_exe_pcnext),
        .data_out(program_counter)
    );
endmodule

module pc_alu (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] pc_alu_out

);
    assign pc_alu_out = a + b;
endmodule

module register (
    input clk,
    input rst,
    input [31:0] data_in,
    output [31:0] data_out
);
    logic [31:0] register;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            register <= 0;

        end else begin
            register <= data_in;
        end

    end
    assign data_out = register;

endmodule

module register_en (
    input clk,
    input rst,
    input en,
    input [31:0] data_in,
    output [31:0] data_out
);
    logic [31:0] register;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            register <= 0;

        end else begin
            if(en)
                register <= data_in;
        end

    end
    assign data_out = register;

endmodule

module mux2x1 (
    input        [31:0] in0,
    input        [31:0] in1,
    input               mux_sel,
    output logic [31:0] out_mux
);
    assign out_mux = {mux_sel} ? in1 : in0;
endmodule

module imm_extender (
    input [31:0] instr_data,
    output logic [31:0] imm_data

);

    always_comb begin
        imm_data = 32'd0;
        case (instr_data[6:0])
            `S_type: begin
                imm_data = {
                    {20{instr_data[31]}}, instr_data[31:25], instr_data[11:7]
                };
            end

            `I_type, `IL_type,`JALR_type: begin
                imm_data = {{20{instr_data[31]}}, instr_data[31:20]};
            end
            `B_type: begin
                imm_data = {
                    {20{instr_data[31]}},
                    instr_data[7],
                    instr_data[30:25],
                    instr_data[11:8],
                    1'b0
                };
            end
            `LUI_type,`AUIPC_type: begin
                imm_data = {instr_data [31:12], {12{1'b0}}};
            end
            
            `JAL_type: begin
                imm_data = {{12{instr_data[31]}}, instr_data[19:12], instr_data[20],instr_data[30:21], 1'b0 };
            end

        endcase

    end
endmodule

module mux_2x1 (
    input        [31:0] in0,      // sel 0
    input        [31:0] in1,      // sel 1
    input               mux_sel,
    output logic [31:0] out_mux
);

    assign out_mux = (mux_sel) ? in1 : in0;

endmodule