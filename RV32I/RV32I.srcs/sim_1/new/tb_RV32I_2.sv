`timescale 1ns / 1ps



module tb_RV32I_2();
    logic clk,rst; 
    

    
    RV32I_TOP dut(
        .clk(clk),
        .rst(rst)
);

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

       
        @(negedge clk);
        @(negedge clk);
        rst = 0;
        

        repeat(10000)
        @(negedge clk);
        $stop;
    end
endmodule
