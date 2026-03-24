`timescale 1ns / 1ps
`include "define.vh"


module RV32_CPU (
    input               clk,
    input               rst,
    input  logic [31:0] instr_data,
    input        [31:0] bus_rdata,
    output       [31:0] instr_addr,
    input               bus_ready,
    output              bus_wreq,
    output              bus_rreq,
    output       [ 2:0] o_funct3,
    output       [31:0] bus_addr,
    output       [31:0] bus_wdata


);
    logic pc_en, rf_we, alu_src, jalr_sel, jal_sel;
    logic branch;
    logic [3:0] alu_control;
    logic [2:0] rfwd_src;


    control_unit U_CONTR_UNIT (

        .clk(clk),
        .rst(rst),
        .funct7(instr_data[31:25]),
        .funct3(instr_data[14:12]),
        .opcode(instr_data[6:0]),
        .ready(ready),
        .rf_we(rf_we),
        .alu_control(alu_control),
        .alu_src(alu_src),
        .rfwd_src(rfwd_src),
        .o_funct3(o_funct3),
        .wreq(bus_wreq),
        .branch(branch),
        .jalr_sel(jalr_sel),
        .jal_sel(jal_sel),
        .pc_en(pc_en),
        .dwe(bus_wreq),
        .dre(bus_rreq)

    );


    rv32i_datapath U_DATAPATH (
        .*
    );



endmodule





module control_unit (
    input              clk,
    input              rst,
    input        [6:0] funct7,
    input        [2:0] funct3,
    input        [6:0] opcode,
    input              ready,
    output logic       pc_en,
    output logic       alu_src,
    output logic       rf_we,
    output logic       branch,
    output logic [2:0] o_funct3,
    output logic       wreq,
    output logic [3:0] alu_control,
    output logic [2:0] rfwd_src,
    output logic       jalr_sel,
    output logic       jal_sel,
    output logic       dwe,
    output logic       dre





);

    typedef enum logic [3:0] {
        FETCH,
        DECODE,
        EXECUTE,
        EX_R,
        EX_I,
        EX_S,
        EX_B,
        EX_L,
        EX_J,
        EX_JL,
        EX_U,
        EX_UA,
        MEM,
        MEM_S,
        MEM_L,
        WB
    } state_e;

    state_e c_state, n_state;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= FETCH;
        end else begin
            c_state <= n_state;
        end
    end

    always_comb begin

        n_state = c_state;
        case (c_state)
            FETCH: begin

                n_state = DECODE;
            end
            DECODE: begin

                n_state = EXECUTE;
            end

            EXECUTE: begin
                case (opcode)
                    `JAL_type,`JALR_type,`AUIPC_type,`LUI_type,`B_type,`I_type,`R_type: begin
                        n_state = FETCH;
                    end
                    `S_type: begin
                        n_state = MEM;
                    end
                    `IL_type: begin
                        n_state = MEM;
                    end

                endcase
            end
            MEM: begin
                case (opcode)
                    `S_type: begin
                        if (ready) begin
                            n_state = FETCH;
                        end
                    end  
                    `IL_type: n_state = WB;

                endcase
            end
            WB: begin
                if (ready) begin
                    
                n_state = FETCH;
                end
            end

            // DECODE: begin
            //     case (opcode)
            //         `R_type:     n_state = EX_R;
            //         `I_type:     n_state = EX_I;
            //         `S_type:     n_state = EX_S;
            //         `B_type:     n_state = EX_B;
            //         `IL_type:    n_state = EX_L;  // Load 명령어
            //         `JAL_type:   n_state = EX_J;
            //         `JALR_type:  n_state = EX_JL;
            //         `LUI_type:   n_state = EX_U;
            //         `AUIPC_type: n_state = EX_UA;
            //         default:     n_state = FETCH;

            //     endcase
            // end

            // EX_R:  n_state = FETCH;
            // EX_S:  n_state = MEM_S;
            // MEM_S: n_state = FETCH;
            // EX_L:  n_state = MEM_L;
            // MEM_L: n_state = WB;
            // WB:    n_state = FETCH;
            // EX_I:  n_state = FETCH;
            // EX_B:  n_state = FETCH;
            // EX_U:  n_state = FETCH;
            // EX_UA: n_state = FETCH;
            // EX_J:  n_state = FETCH;
            // EX_JL: n_state = FETCH;



            // default: n_state = FETCH;




        endcase
    end




    //output
    always_comb begin
        pc_en       = 1'b0;
        rf_we       = 0;
        jal_sel     = 1'b0;
        jalr_sel    = 1'b0;
        branch      = 1'b0;
        alu_src     = 1'b0;
        alu_control = 4'b0000;
        rfwd_src    = 3'b000;
        o_funct3    = 3'b0;
        wreq        = 1'b0;
        dwe         = 1'b0;
        dre         = 1'b0;

        case (c_state)
            FETCH: begin
                pc_en = 1'b1;


            end
            DECODE: begin


            end

            EXECUTE: begin
                case (opcode)
                    `R_type: begin
                        rf_we       = 1'b1;
                        alu_src     = 1'b0;
                        alu_control = {funct7[5], funct3};
                    end
                    `I_type: begin
                        rf_we   = 1'b1;
                        alu_src = 1'b1;
                        if (funct3 == 3'b101) alu_control = {funct7[5], funct3};
                        else alu_control = {1'b0, funct3};


                    end
                    `B_type: begin
                        branch      = 1'b1;
                        alu_src     = 1'b0;
                        alu_control = {1'b0, funct3};

                    end
                    `IL_type: begin
                        alu_control = 4'b0000;
                        alu_src     = 1'b1;

                    end
                    `S_type: begin
                        alu_src     = 1'b1;
                        alu_control = 4'b0000;

                    end
                    `LUI_type: begin
                        rf_we    = 1;
                        rfwd_src = 3'b010;

                    end
                    `AUIPC_type: begin
                        rf_we    = 1;
                        rfwd_src = 3'b011;

                    end
                    `JAL_type, `JALR_type: begin
                        rf_we   = 1;
                        jal_sel = 1;
                        if (opcode == `JALR_type) jalr_sel = 1;
                        else jalr_sel = 0;
                        rfwd_src = 3'b100;

                    end

                endcase
            end
            MEM: begin
                o_funct3 = funct3;
                if (opcode == `S_type) wreq = 1'b1;
            end
            WB: begin
                rf_we = 1'b1;
                rfwd_src = 3'b001;
                dre         = 1'b1;
            end
            // EX_R: begin
            //     pc_en       = 1'b0;
            //     rf_we       = 1;
            //     alu_src     = 1'b0;
            //     wreq         = 1'b0;
            //     rfwd_src    = 3'b000;
            //     branch      = 1'b0;
            //     jal_sel     = 1'b0;
            //     jalr_sel    = 1'b0;
            //     alu_control = {funct7[5], funct3};

            // end
            // EX_S: begin
            //     pc_en       = 1'b0;
            //     rf_we       = 1;
            //     alu_src     = 1'b1;
            //     wreq         = 1'b0;
            //     rfwd_src    = 3'b000;
            //     branch      = 1'b0;
            //     jal_sel     = 1'b0;
            //     jalr_sel    = 1'b0;
            //     alu_control = 4'b0000;
            //     o_funct3    = funct3;

            // end

            // EX_L: begin
            //     pc_en       = 1'b0;
            //     rf_we       = 0;
            //     alu_src     = 1'b1;
            //     wreq         = 1'b0;
            //     rfwd_src    = 3'b001;
            //     branch      = 1'b0;
            //     jal_sel     = 1'b0;
            //     jalr_sel    = 1'b0;
            //     alu_control = 4'b0000;
            //     o_funct3    = funct3;
            // end

            // MEM_S: begin
            //     pc_en       = 1'b0;
            //     rf_we       = 0;
            //     alu_src     = 1'b1;
            //     wreq         = 1'b1;
            //     rfwd_src    = 3'b000;
            //     branch      = 1'b0;
            //     jal_sel     = 1'b0;
            //     jalr_sel    = 1'b0;
            //     alu_control = 4'b0000;
            //     o_funct3    = funct3;
            // end

            // MEM_L: begin
            //     pc_en       = 1'b0;
            //     rf_we       = 0;
            //     alu_src     = 1'b1;
            //     wreq         = 1'b0;
            //     rfwd_src    = 3'b001;
            //     branch      = 1'b0;
            //     jal_sel     = 1'b0;
            //     jalr_sel    = 1'b0;
            //     alu_control = 4'b0000;
            //     o_funct3    = funct3;

            // end
            // WB: begin
            //     pc_en       = 1'b0;
            //     rf_we       = 1;
            //     alu_src     = 1'b1;
            //     wreq         = 1'b0;
            //     //rfwd_src    = 3'b001;
            //     branch      = 1'b0;
            //     jal_sel     = 1'b0;
            //     jalr_sel    = 1'b0;
            //     alu_control = 4'b0000;
            //     rfwd_src = 3'b001;
            //     // case (opcode)
            //     //     `IL_type:    rfwd_src = 3'b001; // Load: 메모리 데이터
            //     //     `LUI_type:   rfwd_src = 3'b010; // LUI 데이터
            //     //     `AUIPC_type: rfwd_src = 3'b011; // AUIPC 데이터
            //     //     default:     rfwd_src = 3'b000; // R-type, I-type: ALU 연산 결과
            //     // endcase

            // end
            // EX_I: begin
            //     pc_en    = 1'b0;
            //     rf_we    = 0;
            //     alu_src  = 1'b1;
            //     wreq      = 1'b0;
            //     rfwd_src = 3'b000;
            //     branch   = 1'b0;
            //     jal_sel  = 1'b0;
            //     jalr_sel = 1'b0;
            //     if (funct3 == 3'b101) alu_control = {funct7[5], funct3};
            //     else alu_control = {1'b0, funct3};
            //     o_funct3    = funct3;

            // end
            // EX_B: begin
            //     pc_en       = 1'b0;
            //     rf_we       = 0;
            //     alu_src     = 1'b0;
            //     wreq         = 1'b0;
            //     rfwd_src    = 3'b000;
            //     branch      = 1'b1;
            //     jal_sel     = 1'b0;
            //     jalr_sel    = 1'b0;
            //     alu_control = {1'b1, funct3};
            //     o_funct3    = funct3;

            // end
            // EX_U: begin
            //     pc_en       = 1'b0;
            //     rf_we       = 1;
            //     alu_src     = 1'b0;
            //     wreq         = 1'b0;
            //     rfwd_src    = 3'b010;
            //     branch      = 1'b0;
            //     jal_sel     = 1'b0;
            //     jalr_sel    = 1'b0;
            //     alu_control = 4'b1111;

            // end
            // EX_UA: begin
            //     pc_en       = 1'b0;
            //     rf_we       = 1;
            //     alu_src     = 1'b1;
            //     wreq         = 1'b0;
            //     rfwd_src    = 3'b011;
            //     branch      = 1'b0;
            //     jal_sel     = 1'b0;
            //     jalr_sel    = 1'b0;
            //     alu_control = 4'b0000;
            //     o_funct3    = funct3;

            // end
            // EX_J: begin
            //     pc_en       = 1'b0;
            //     rf_we       = 1;
            //     alu_src     = 1'b0;
            //     wreq         = 1'b0;
            //     rfwd_src    = 3'b100;
            //     branch      = 1'b0;
            //     jal_sel     = 1'b1;
            //     jalr_sel    = 1'b0;
            //     alu_control = 4'b0000;
            // end
            // EX_JL: begin
            //     pc_en       = 1'b0;
            //     rf_we       = 1;
            //     alu_src     = 1'b0;
            //     wreq         = 1'b0;
            //     rfwd_src    = 3'b100;
            //     branch      = 1'b0;
            //     jal_sel     = 1'b1;
            //     jalr_sel    = 1'b1;
            //     alu_control = 4'b0000;
            // end


        endcase
    end

    // always_comb begin
    //     rf_we       = 0;
    //     alu_control = 4'b0000;
    //     alu_src     = 1'b0;
    //     wreq         = 1'b0;
    //     rfwd_src    = 3'b000;
    //     o_funct3    = 3'b0;
    //     branch      = 1'b0;
    //     jalr_sel    = 1'b0;
    //     jal_sel     = 1'b0;

    //     case (opcode)
    //         `R_type: begin
    //             rf_we       = 1;
    //             alu_src     = 1'b0;
    //             alu_control = {funct7[5], funct3};
    //             wreq         = 1'b0;
    //             rfwd_src    = 3'b000;
    //             o_funct3    = 3'b0;
    //             branch      = 1'b0;

    //         end
    //         `B_type: begin
    //             rf_we       = 0;
    //             alu_src     = 1'b0;
    //             alu_control = {1'b1, funct3}; 
    //             rfwd_src    = 3'b000;
    //             wreq         = 1'b0;
    //             o_funct3    = funct3;
    //             branch      = 1'b1;

    //         end
    //         `S_type: begin
    //             rf_we       = 0;
    //             alu_src     = 1'b1;
    //             alu_control = 4'b0000;
    //             wreq         = 1'b1;
    //             rfwd_src    = 3'b000;
    //             branch      = 1'b0;
    //             o_funct3    = funct3;


    //         end
    //         `IL_type: begin
    //             rf_we       = 1;
    //             alu_src     = 1'b1;
    //             alu_control = 4'b0000;
    //             branch      = 1'b0;
    //             rfwd_src    = 3'b001;
    //             wreq         = 1'b0;
    //             o_funct3    = funct3;

    //         end
    //         `I_type: begin
    //             rf_we   = 1;
    //             branch      = 1'b0;
    //             alu_src = 1'b1;
    //             if (funct3 == 3'b101) 
    //             alu_control = {funct7[5], funct3};
    //             else alu_control = {1'b0, funct3};
    //             rfwd_src = 3'b000;
    //             wreq      = 1'b0;
    //             o_funct3 = funct3;

    //         end

    //         `LUI_type: begin
    //             rf_we       = 1;
    //             alu_src     = 1'b1;
    //             alu_control = 4'b1111;
    //             branch      = 1'b0;
    //             rfwd_src    = 3'b010;
    //             wreq         = 1'b0;


    //         end
    //         `AUIPC_type: begin
    //             rf_we       = 1;
    //             alu_src     = 1'b1;
    //             alu_control = 4'b0000;
    //             branch      = 1'b0;
    //             rfwd_src    = 3'b011;  // ★ 수정: ALU 결과(PC+Imm)를 레지스터로 보내야 하므로 0
    //             wreq         = 1'b0;
    //             o_funct3 = funct3;
    //         end
    //         `JAL_type : begin
    //             rf_we       = 1;
    //             alu_src     = 1'b0;
    //             alu_control = 4'b1110;
    //             branch      = 1'b0;
    //             rfwd_src    = 3'b100;
    //             wreq         = 1'b0;
    //             jal_sel     = 1'b1;
    //         end
    //         `JALR_type : begin
    //             rf_we       = 1;
    //             alu_src     = 1'b1;
    //             alu_control = 4'b0000;
    //             branch      = 1'b0;
    //             rfwd_src    = 3'b100;
    //             wreq         = 1'b0;
    //             jalr_sel    = 1'b1;
    //             jal_sel     = 1'b1;

    //         end
    //         default: begin

    //         rf_we = 0;
    //         wreq =0;
    //         branch = 0;        
    //         end 
    //     endcase

    // end

endmodule





