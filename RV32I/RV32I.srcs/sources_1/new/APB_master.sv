`timescale 1ns / 1ps



module APB_master (

    //Soc internal sig
    input  logic        PCLK,
    input  logic        PRESETn,
    input  logic [31:0] Addr,
    input  logic [31:0] Wdata,
    input  logic        Wreq, //dwe
    input  logic        Rreq, //dre
    //output logic        slverr,
    output logic [31:0] Rdata,
    output logic        Ready,
    output logic        PENABLE,
    output logic        PWRITE,

    //APB IF SIG
    output logic [31:0] PADDR,
    output logic [31:0] PWDATA,
    output logic [31:0] PSEL0,   //RAM
    output logic [31:0] PSEL1,   //GPO
    output logic [31:0] PSEL2,   //GPI
    output logic [31:0] PSEL3,   //GPIO
    output logic [31:0] PSEL4,   //FND
    output logic [31:0] PSEL5,   //UART

    input logic [31:0] PRDATA0,  //RAM
    input logic [31:0] PRDATA1,  //GPO
    input logic [31:0] PRDATA2,  //GPI
    input logic [31:0] PRDATA3,  //GPIO
    input logic [31:0] PRDATA4,  //FND
    input logic [31:0] PRDATA5,  //UART

    input logic PREADY0,  //RAM
    input logic PREADY1,  //GPO
    input logic PREADY2,  //GPI
    input logic PREADY3,  //GPIO
    input logic PREADY4,  //FND
    input logic PREADY5  //UART


   
);





    APB_Decoder U_ADDR_DECODER (
        .addr (addr),
        .psel0(PSEL0),
        .psel1(PSEL1),
        .psel2(PSEL2),
        .psel3(PSEL3),
        .psel4(PSEL4),
        .psel5(PSEL5),
        .en()

    );



    APB_Mux U_APB_MUX (
        .sel    (addr),
        .Prdata0(Prdata0),  // sel 0
        .Prdata1(Prdata1),
        .Prdata2(Prdata2),
        .Prdata3(Prdata3),
        .Prdata4(Prdata4),
        .Prdata5(Prdata5),
        .PREADY0(PREADY0),
        .PREADY1(PREADY1),
        .PREADY2(PREADY2),
        .PREADY3(PREADY3),
        .PREADY4(PREADY4),
        .PREADY5(PREADY5),
        .Rdata  (Rdata),
        .Ready  (Ready)
    );

    logic [31:0] PADDR_next, PWDATA_next;
    logic decode_en, PWRITE_next;

    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } apb_state_e;



    apb_state_e c_state, n_state;


    always_ff @(posedge PCLK, negedge PRESETn) begin
        if (!PRESETn) begin
            c_state <= IDLE;
            PADDR   <= 32'd0;
            PWDATA  <= 32'd0;
            PWRITE <= 1'b0;
        end else begin
            c_state <= n_state;
            PADDR   <= PADDR_next;
            PWDATA  <= PWDATA_next;
            PWRITE <= PWRITE_next;
        end
    end

    always_comb begin
        n_state     = c_state;
        decode_en   = 1'b0;
        PENABLE     = 1'b0;
        PWRITE      = 1'b0;
        PADDR_next  = PADDR;
        PWDATA_next = PWDATA;
        PWRITE_next = PWRITE;
        case (c_state)
            IDLE: begin
                decode_en = 0;
                if (Wreq | Rreq) begin
                    PADDR_next  = Addr;
                    PWDATA_next = Wdata;
                    if(Wreq) begin
                        PWRITE =1'b1;
                    end else begin
                        PWRITE =1'b0;
                    end
                    n_state     = SETUP;
                end
            end
            SETUP: begin
                decode_en = 1;
                PENABLE   = 0;
                n_state   = ACCESS;
            end
            ACCESS: begin
                decode_en = 1;
                PENABLE   = 1;
                // if (PREADY0|PREADY1|PREADY2|PREADY3|PREADY4|PREADY5)begin
                if (Ready) begin
                    n_state = IDLE;
                end
            end

        endcase
    end
endmodule


module APB_Decoder (
    input logic [31:0] addr,
    input logic en,
    output logic psel0,
    output logic psel1,
    output logic psel2,
    output logic psel3,
    output logic psel4,
    output logic psel5

);

    always_comb begin
        psel0 = 1'b0;
        psel1 = 1'b0;
        psel2 = 1'b0;
        psel3 = 1'b0;
        psel4 = 1'b0;
        psel5 = 1'b0;
        if (en) begin

            case (addr[31:28])
                4'h1: psel0 = 1'b1;
                4'h2: begin
                    case (addr[15:12])
                        4'h0: psel1 = 1'b1;
                        4'h1: psel2 = 1'b1;
                        4'h2: psel3 = 1'b1;
                        4'h3: psel4 = 1'b1;
                        4'h4: psel5 = 1'b1;

                    endcase
                end





            endcase
        end
    end


endmodule



module APB_Mux (
    input        [31:0] sel,
    input        [31:0] Prdata0,  // sel 0
    input        [31:0] Prdata1,
    input        [31:0] Prdata2,
    input        [31:0] Prdata3,
    input        [31:0] Prdata4,
    input        [31:0] Prdata5,
    input               PREADY0,
    input               PREADY1,
    input               PREADY2,
    input               PREADY3,
    input               PREADY4,
    input               PREADY5,
    output logic [31:0] Rdata,
    output logic        Ready
);

    always_comb begin
        Rdata = 32'h0000_0000;
        Ready = 1'b0;

        case (sel[31:28])
            4'h1: begin
                Rdata = Prdata0;
                Ready = PREADY0;
            end
            4'h2: begin
                case (sel[15:12])
                    4'h0: begin
                        Rdata = Prdata1;
                        Ready = PREADY1;
                    end
                    4'h1: begin
                        Rdata = Prdata2;
                        Ready = PREADY2;
                    end
                    4'h2: begin
                        Rdata = Prdata3;
                        Ready = PREADY3;
                    end
                    4'h3: begin
                        Rdata = Prdata4;
                        Ready = PREADY4;
                    end
                    4'h4: begin
                        Rdata = Prdata5;
                        Ready = PREADY5;
                    end
                    default: begin
                        Rdata = 32'h0000_0000;
                        Ready = 1'b0;
                    end
                endcase
            end
        endcase
    end

endmodule
