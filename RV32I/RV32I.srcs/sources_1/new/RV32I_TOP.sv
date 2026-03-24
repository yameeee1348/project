`timescale 1ns / 1ps



module RV32I_TOP (
    input clk,
    input rst
);

    logic [31:0] instr_addr, instr_data;
    logic dwe,dre;
    logic [2:0] o_funct3;
    logic [31:0] bus_addr,bus_wdata,bus_rdata,ready;
    logic bus_wreq,bus_rreq,bus_ready;

    instruction_memory U_INSTRUCTION_MEM (.*);


    RV32_CPU U_RV32I (
        .*,
        .o_funct3(o_funct3)


    );



//    data_mem U_DATA_MEM (
//        .*,
//        .i_funct3(o_funct3)
//    );

    APB_master U_APB_MASTER_INTERFACE (

        //Soc internal sig
        .PCLK(clk),
        .PRESETn(rst),
        .Addr(bus_addr),
        .Wdata(bus_wdata),
        .Wreq(bus_wreq),  //dwe
        .Rreq(bus_rreq),  //dre
        .Rdata(bus_rdata),
        .Ready(bus_ready),
        .PENABLE(),
        .PWRITE(),

        //APB IF SIG
        .PADDR (),
        .PWDATA(),
        .PSEL0 (),  //RAM
        .PSEL1 (),  //GPO
        .PSEL2 (),  //GPI
        .PSEL3 (),  //GPIO
        .PSEL4 (),  //FND
        .PSEL5 (),  //UART

        .PRDATA0(),  //RAM
        .PRDATA1(),  //GPO
        .PRDATA2(),  //GPI
        .PRDATA3(),  //GPIO
        .PRDATA4(),  //FND
        .PRDATA5(),  //UART

        .PREADY0(),  //RAM
        .PREADY1(),  //GPO
        .PREADY2(),  //GPI
        .PREADY3(),  //GPIO
        .PREADY4(),  //FND
        .PREADY5()   //UART



    );
endmodule
