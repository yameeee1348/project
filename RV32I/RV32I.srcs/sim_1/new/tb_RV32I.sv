`timescale 1ns / 1ps

module tb_RV32I();
    logic clk;
    logic rst;

    // DUT 인스턴스화
    RV32I_TOP dut (
        .clk(clk),
        .rst(rst)
    );

    // 10ns 주기 클럭 (100MHz)
    always #5 clk = ~clk;

    // 내부 레지스터 파일에 접근하기 위한 계층적 경로 단축어
    // (시뮬레이션 툴에 따라 경로가 다를 수 있으니 확인 필요)
    `define REG_FILE dut.U_RV32I.U_DATAPATH.U_REG_FILE.rf

    initial begin
        // 1. 초기화 및 리셋
        clk = 0;
        rst = 1;
        #20 rst = 0;

        // 2. 시나리오용 초기값 주입 (Force Loading)
        // x4 = 20 (0x14), x5 = 10 (0x0A)
        `REG_FILE[4] = 32'd20;
        `REG_FILE[5] = 32'd10;
        
        // 3. 엣지 케이스 테스트를 위한 특수 값 주입 (SLT/SRA 확인용)
        // x15 = -5 (0xFFFFFFFB)
        `REG_FILE[15] = -32'd5; 

        $display("\n=================================================");
        $display("   RISC-V R-type Processor Functional Test       ");
        $display("=================================================");
        $display("Initial Values: x4=%0d, x5=%0d, x15=%0d(signed)", `REG_FILE[4], `REG_FILE[5], $signed(`REG_FILE[15]));
        $display("-------------------------------------------------");

        // 4. 각 명령어 실행 대기 (명령어 10개 + 여유분)
        // 각 클럭마다 PC가 4씩 증가하며 ROM의 명령어를 실행합니다.
        repeat (12) @(posedge clk);

        // 5. 결과 검증 및 리포트
        #5; // 연산 결과가 레지스터에 기록될 시간을 조금 줌
        
        $display(" [RESULT REPORT] ");
        $display(" 1. ADD  (x3  = x4 + x5)  -> Result: %0d (Exp: 30)", `REG_FILE[3]);
        $display(" 2. SUB  (x6  = x4 - x5)  -> Result: %0d (Exp: 10)", `REG_FILE[6]);
        $display(" 3. SLL  (x7  = x4 << x5) -> Result: %h (Shift Left)", `REG_FILE[7]);
        $display(" 4. SLT  (x8  = x4 < x5)  -> Result: %0d (Exp: 0)", `REG_FILE[8]);
        $display(" 5. SLTU (x9  = x4 < x5)  -> Result: %0d (Unsigned)", `REG_FILE[9]);
        $display(" 6. XOR  (x10 = x4 ^ x5)  -> Result: %h", `REG_FILE[10]);
        $display(" 7. SRL  (x11 = x4 >> x5) -> Result: %h (Logic Right)", `REG_FILE[11]);
        $display(" 8. SRA  (x12 = x4 >>> x5)-> Result: %h (Arith Right)", `REG_FILE[12]);
        $display(" 9. OR   (x13 = x4 | x5)  -> Result: %h", `REG_FILE[13]);
        $display("10. AND  (x14 = x4 & x5)  -> Result: %h", `REG_FILE[14]);
        
        $display("-------------------------------------------------");
        // x0 레지스터 보호 확인 (매우 중요)
        $display(" Critical Check: x0 Register Value = %0d (Should be 0)", `REG_FILE[0]);
        
        if (`REG_FILE[0] == 0 && `REG_FILE[3] == 30 && `REG_FILE[6] == 10)
            $display("\n CONCLUSION: ALL R-TYPE TEST PASSED! ✅");
        else
            $display("\n CONCLUSION: TEST FAILED! ❌ Check your logic.");
        $display("=================================================\n");

        $finish;
    end

    // 시뮬레이션 중 파형 모니터링
    initial begin
        $monitor("Time:%t | PC:%h | Instr:%h | ALU_Out:%h", 
                  $time, dut.instr_addr, dut.instr_data, dut.U_RV32I.U_DATAPATH.U_ALU.alu_result);
    end

endmodule