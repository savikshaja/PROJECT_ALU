module alu_testb;

    parameter WIDTH = 4;

    reg [WIDTH-1:0] opa, opb;
    reg clk, rst, ce, mode, cin;
    reg [1:0] inp_valid;
    reg [3:0] cmd;

    wire [2*WIDTH-1:0] res_dut;
    wire cout_dut, oflow_dut, g_dut, l_dut, e_dut, err_dut;

    wire [2*WIDTH-1:0] res_ref;
    wire cout_ref, oflow_ref, g_ref, e_ref, l_ref, err_ref;

    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;

    four_bit_alu_rtl_design #(.WIDTH(WIDTH)) dut (
        .i_opa      (opa),
        .i_opb      (opb),
        .cin        (cin),
        .clk        (clk),
        .rst        (rst),
        .i_cmd      (cmd),
        .ce         (ce),
        .mode       (mode),
        .i_inp_valid(inp_valid),
        .res        (res_dut),
        .cout       (cout_dut),
        .oflow      (oflow_dut),
        .g          (g_dut),
        .e          (e_dut),
        .l          (l_dut),
        .err        (err_dut)
    );

    alu_ref #(.N(WIDTH)) ref_model (
        .opa      (opa),
        .opb      (opb),
        .ce       (ce),
        .mode     (mode),
        .inp_valid(inp_valid),
        .cin      (cin),
        .cmd      (cmd),
        .res      (res_ref),
        .cout     (cout_ref),
        .oflow    (oflow_ref),
        .g        (g_ref),
        .e        (e_ref),
        .l        (l_ref),
        .err      (err_ref)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("alu_test.vcd");
        $dumpvars(1, alu_testb);
    end

    initial begin
        rst=1; ce=1; cin=0; opa=0; opb=0; mode=0; cmd=0; inp_valid=0;
        repeat(2) @(posedge clk);
        rst = 0;
        repeat(2) @(posedge clk);  // let cycle_count settle to 00

        $display("\n-----Arithmetic operation mode(1)--------");
        mode = 1;
        test_arithmetic();

        $display("\n--ce=0 hold state-----");
        ce = 0;
        repeat(2) @(posedge clk);
        #1;
        test_count = test_count + 1;
        if(compare_output(1'b0)) begin
            $display("[PASS] CE=0 hold state | RES=%h ERR=%b", res_dut, err_dut);
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] CE=0 hold state | RES=%h ERR=%b", res_dut, err_dut);
            display_mismatch();
            fail_count = fail_count + 1;
        end
        ce = 1;
        repeat(2) @(posedge clk);  // let cycle_count settle after ce re-enable

        test_multi();

        $display("\n-----logical operation mode(0)--------");
        mode = 0;
        repeat(2) @(posedge clk);  // settle before logic tests
        test_logical();

        $display("\n test summary");
        $display("total test case: %0d", test_count);
        $display("PASS: %0d", pass_count);
        $display("FAIL: %0d", fail_count);

        if(fail_count == 0)
            $display("\n all test passed");
        else
            $display("\n some test failed");

        #100;
        $finish;
    end

    task test_arithmetic();
    begin
        apply_test(4'h7, 4'h1, 4'b0000, 2'b11, "ADD");
        apply_test(4'hF, 4'h1, 4'b0000, 2'b01, "ADD err");
        apply_test(4'h8, 4'h1, 4'b0000, 2'b11, "ADD COUT");
        apply_test(4'hF, 4'h1, 4'b0000, 2'b11, "ADD overflow");
        apply_test(4'hF, 4'h1, 4'b0000, 2'b00, "ADD err2");
        apply_test(4'hF, 4'hF, 4'b0000, 2'b11, "ADD boundary");

        apply_test(4'h7, 4'h1, 4'b0001, 2'b11, "SUB");
        apply_test(4'h7, 4'h1, 4'b0001, 2'b00, "SUB err");
        apply_test(4'h0, 4'h1, 4'b0001, 2'b11, "SUB overflow");
        apply_test(4'h7, 4'h1, 4'b0001, 2'b01, "SUB err2");
        apply_test(4'hF, 4'hF, 4'b0001, 2'b11, "SUB boundary");

        cin = 1;
        apply_test(4'h7, 4'h1, 4'b0010, 2'b11, "ADD_CIN");
        apply_test(4'hF, 4'h1, 4'b0010, 2'b00, "ADD_CIN err");
        apply_test(4'hF, 4'h1, 4'b0010, 2'b11, "ADD_CIN overflow");
        apply_test(4'hF, 4'h1, 4'b0010, 2'b10, "ADD_CIN err2");
        apply_test(4'hF, 4'hF, 4'b0010, 2'b11, "ADD_CIN boundary");
        cin = 0;

        cin = 1;
        apply_test(4'h7, 4'h1, 4'b0011, 2'b11, "SUB_CIN");
        apply_test(4'h7, 4'h1, 4'b0011, 2'b01, "SUB_CIN err");
        apply_test(4'h0, 4'h1, 4'b0011, 2'b11, "SUB_CIN overflow");
        apply_test(4'h7, 4'h1, 4'b0011, 2'b00, "SUB_CIN err2");
        apply_test(4'hF, 4'hF, 4'b0011, 2'b11, "SUB_CIN boundary");
        cin = 0;

        apply_test(4'hF, 4'h0, 4'b0100, 2'b00, "INC_A err");
        apply_test(4'hF, 4'h0, 4'b0100, 2'b10, "INC_A boundary");
        apply_test(4'h0, 4'h0, 4'b0100, 2'b01, "INC_A");
        apply_test(4'h8, 4'h0, 4'b0100, 2'b11, "INC_A");

        apply_test(4'hF, 4'h0, 4'b0101, 2'b00, "DEC_A err");
        apply_test(4'h0, 4'h0, 4'b0101, 2'b10, "DEC_A boundary");
        apply_test(4'h0, 4'h0, 4'b0101, 2'b01, "DEC_A");
        apply_test(4'h8, 4'h0, 4'b0101, 2'b11, "DEC_A");

        apply_test(4'h0, 4'hF, 4'b0110, 2'b00, "INC_B err");
        apply_test(4'h0, 4'hF, 4'b0110, 2'b10, "INC_B");
        apply_test(4'h0, 4'hF, 4'b0110, 2'b01, "INC_B boundary err");
        apply_test(4'h0, 4'h8, 4'b0110, 2'b11, "INC_B");

        apply_test(4'h0, 4'hF, 4'b0111, 2'b00, "DEC_B err");
        apply_test(4'h0, 4'hF, 4'b0111, 2'b10, "DEC_B");
        apply_test(4'h0, 4'h0, 4'b0111, 2'b01, "DEC_B boundary err");
        apply_test(4'h0, 4'h8, 4'b0111, 2'b11, "DEC_B");

        apply_test(4'hF, 4'h1, 4'b1000, 2'b00, "CMP err");
        apply_test(4'hF, 4'h1, 4'b1000, 2'b11, "CMP G");
        apply_test(4'hF, 4'hF, 4'b1000, 2'b11, "CMP E");
        apply_test(4'hA, 4'hF, 4'b1000, 2'b11, "CMP L");

        apply_test(4'hE, 4'h2, 4'b1001, 2'b11, "MULTI_INCRE");
        apply_test(4'hE, 4'hE, 4'b1001, 2'b10, "MULTI_INCRE err");
        apply_test(4'hF, 4'hF, 4'b1001, 2'b11, "MULTI_INCRE boundary");
        apply_test(4'hF, 4'h2, 4'b1001, 2'b11, "MULTI_INCRE boundary2");
        apply_test(4'h7, 4'h1, 4'b1001, 2'b11, "MULTI_INCRE");

        apply_test(4'hE, 4'hF, 4'b1010, 2'b11, "MULTI_SHIFT");
        apply_test(4'h7, 4'hE, 4'b1010, 2'b10, "MULTI_SHIFT err");
        apply_test(4'h3, 4'h2, 4'b1010, 2'b11, "MULTI_SHIFT boundary");
        apply_test(4'hB, 4'h1, 4'b1010, 2'b11, "MULTI_SHIFT");

        apply_test(4'h7, 4'h8, 4'b1011, 2'b11, "S_ADD");
        apply_test(4'hF, 4'h1, 4'b1011, 2'b00, "S_ADD err");
        apply_test(4'hF, 4'h7, 4'b1011, 2'b11, "S_ADD overflow");
        apply_test(4'hF, 4'h1, 4'b1011, 2'b11, "S_ADD");
        apply_test(4'h0, 4'h0, 4'b1011, 2'b11, "S_ADD boundary");
        apply_test(4'h7, 4'h7, 4'b1011, 2'b11, "S_ADD overflow2");
        apply_test(4'h8, 4'h8, 4'b1011, 2'b11, "S_ADD overflow3");
        apply_test(4'hF, 4'hF, 4'b1011, 2'b11, "S_ADD");

        apply_test(4'h7, 4'h1, 4'b1100, 2'b11, "S_SUB");
        apply_test(4'hF, 4'h1, 4'b1100, 2'b00, "S_SUB err");
        apply_test(4'h9, 4'h7, 4'b1100, 2'b11, "S_SUB overflow");
        apply_test(4'hF, 4'h1, 4'b1100, 2'b11, "S_SUB");
        apply_test(4'h0, 4'h0, 4'b1100, 2'b11, "S_SUB boundary");
        apply_test(4'h8, 4'h7, 4'b1100, 2'b11, "S_SUB");
        apply_test(4'h9, 4'hF, 4'b1100, 2'b11, "S_SUB");
        apply_test(4'h1, 4'h7, 4'b1100, 2'b11, "S_SUB");

        apply_test(4'h7, 4'h7, 4'b1110, 2'b11, "invalid cmd");
    end
    endtask

    task test_logical();
    begin
        apply_test(4'hF, 4'hF, 4'b0000, 2'b11, "AND");
        apply_test(4'hF, 4'hF, 4'b0000, 2'b01, "AND err");
        apply_test(4'hA, 4'h5, 4'b0000, 2'b11, "AND");

        apply_test(4'hF, 4'hF, 4'b0001, 2'b11, "NAND");
        apply_test(4'hF, 4'hF, 4'b0001, 2'b01, "NAND err");
        apply_test(4'hA, 4'h5, 4'b0001, 2'b11, "NAND");

        apply_test(4'hF, 4'hF, 4'b0010, 2'b11, "OR");
        apply_test(4'hF, 4'hF, 4'b0010, 2'b01, "OR err");
        apply_test(4'hA, 4'h5, 4'b0010, 2'b11, "OR");

        apply_test(4'hF, 4'hF, 4'b0011, 2'b11, "NOR");
        apply_test(4'hF, 4'hF, 4'b0011, 2'b01, "NOR err");
        apply_test(4'hA, 4'h5, 4'b0011, 2'b11, "NOR");

        apply_test(4'hF, 4'hF, 4'b0100, 2'b11, "XOR");
        apply_test(4'hF, 4'hF, 4'b0100, 2'b01, "XOR err");
        apply_test(4'hA, 4'h5, 4'b0100, 2'b11, "XOR");

        apply_test(4'hF, 4'hF, 4'b0101, 2'b11, "XNOR");
        apply_test(4'hF, 4'hF, 4'b0101, 2'b01, "XNOR err");
        apply_test(4'hA, 4'h5, 4'b0101, 2'b11, "XNOR");

        apply_test(4'hF, 4'h0, 4'b0110, 2'b10, "NOT-A err");
        apply_test(4'hF, 4'h0, 4'b0110, 2'b01, "NOT-A");
        apply_test(4'hA, 4'h0, 4'b0110, 2'b11, "NOT-A");

        apply_test(4'h0, 4'hA, 4'b0111, 2'b01, "NOT-B err");
        apply_test(4'h0, 4'hF, 4'b0111, 2'b10, "NOT-B");
        apply_test(4'h0, 4'h5, 4'b0111, 2'b11, "NOT-B");

        apply_test(4'hF, 4'h0, 4'b1000, 2'b10, "SR-A err");
        apply_test(4'hF, 4'h0, 4'b1000, 2'b01, "SR-A");
        apply_test(4'h5, 4'h0, 4'b1000, 2'b11, "SR-A");

        apply_test(4'hF, 4'h0, 4'b1001, 2'b10, "SL-A err");
        apply_test(4'hF, 4'h0, 4'b1001, 2'b01, "SL-A");
        apply_test(4'h5, 4'h0, 4'b1001, 2'b11, "SL-A");

        apply_test(4'h0, 4'hA, 4'b1010, 2'b01, "SR-B err");
        apply_test(4'h0, 4'hF, 4'b1010, 2'b10, "SR-B");
        apply_test(4'h0, 4'h5, 4'b1010, 2'b11, "SR-B");

        apply_test(4'h0, 4'hA, 4'b1011, 2'b10, "SL-B");
        apply_test(4'h0, 4'hF, 4'b1011, 2'b00, "SL-B err");
        apply_test(4'h0, 4'h5, 4'b1011, 2'b11, "SL-B");

        apply_test(4'hF, 4'h0, 4'b1100, 2'b11, "RL rotate0");
        apply_test(4'hF, 4'h1, 4'b1100, 2'b11, "RL");
        apply_test(4'hA, 4'h2, 4'b1100, 2'b11, "RL");
        apply_test(4'hA, 4'h4, 4'b1100, 2'b11, "RL ERR");
        apply_test(4'hA, 4'h2, 4'b1100, 2'b01, "RL err valid");

        apply_test(4'hF, 4'h0, 4'b1101, 2'b11, "RR rotate0");
        apply_test(4'hF, 4'h1, 4'b1101, 2'b11, "RR");
        apply_test(4'hA, 4'h2, 4'b1101, 2'b11, "RR");
        apply_test(4'hA, 4'h4, 4'b1101, 2'b11, "RR ERR");
        apply_test(4'hA, 4'h2, 4'b1101, 2'b01, "RR err valid");

        apply_test(4'h7, 4'h7, 4'b1110, 2'b11, "invalid cmd");
    end
    endtask

    task test_multi();
    begin
        $display("\n-----multiplication varying inp_valid and cmd-----");

        // inp_valid changes during multiply
        opa=4'hA; opb=4'h7; cmd=4'b1001; inp_valid=2'b11; ce=1; mode=1;
        @(posedge clk);   // cycle 0 — captured
        @(posedge clk);   // cycle 2 — computing
        inp_valid = 2'b10; // change inp_valid mid multiply
        @(posedge clk);   // cycle 3 — output
        @(posedge clk);
        #1;
        test_count = test_count + 1;
        if(compare_output(1'b0)) begin
            $display("[PASS] inp_valid changed | RES_dut=%h res_ref=%h ERR_dut=%b err_ref=%b",
                      res_dut, res_ref, err_dut, err_ref);
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] inp_valid changed | RES_dut=%h res_ref=%h ERR_dut=%b err_ref=%b",
                      res_dut, res_ref, err_dut, err_ref);
            display_mismatch();
            fail_count = fail_count + 1;
        end

        // cmd changes during multiply
        repeat(2) @(posedge clk);
        opa=4'hA; opb=4'h7; cmd=4'b1001; inp_valid=2'b11;
        @(posedge clk);   // cycle 0 — captured
        @(posedge clk);   // cycle 2 — computing
        cmd = 4'b1000;    // change cmd mid multiply
        @(posedge clk);
        @(posedge clk);
        #1;
        test_count = test_count + 1;
        if(compare_output(1'b0)) begin
            $display("[PASS] cmd changed mid multiply | RES_dut=%h res_ref=%h ERR_dut=%b err_ref=%b",
                      res_dut, res_ref, err_dut, err_ref);
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] cmd changed mid multiply | RES_dut=%h res_ref=%h ERR_dut=%b err_ref=%b",
                      res_dut, res_ref, err_dut, err_ref);
            display_mismatch();
            fail_count = fail_count + 1;
        end

        // cmd switches from 1001 to 1010 mid multiply
        repeat(2) @(posedge clk);
        opa=4'hA; opb=4'h7; cmd=4'b1001; inp_valid=2'b11;
        @(posedge clk);
        @(posedge clk);
        cmd = 4'b1010;
        @(posedge clk);
        @(posedge clk);
        #1;
        test_count = test_count + 1;
        if(compare_output(1'b0)) begin
            $display("[PASS] cmd 1001->1010 mid multiply | RES_dut=%h res_ref=%h ERR_dut=%b err_ref=%b",
                      res_dut, res_ref, err_dut, err_ref);
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] cmd 1001->1010 mid multiply | RES_dut=%h res_ref=%h ERR_dut=%b err_ref=%b",
                      res_dut, res_ref, err_dut, err_ref);
            display_mismatch();
            fail_count = fail_count + 1;
        end
    end
    endtask

    task apply_test(
        input [WIDTH-1:0] a, b,
        input [3:0]       icmd,
        input [1:0]       iv,
        input [80*8:1]    test_name
    );
        begin
            // apply inputs BEFORE posedge so DUT captures correctly
            opa       = a;
            opb       = b;
            cmd       = icmd;
            inp_valid = iv;

            @(posedge clk);  // cycle 0 — DUT captures inputs

            if(mode==1'b1 && (icmd==4'b1001 || icmd==4'b1010)) begin
                @(posedge clk);  // cycle 2 — multiply computing
                @(posedge clk);  // cycle 3 — multiply output ready
            end
            else begin
                @(posedge clk);  // cycle 1 — output ready
            end

            #1;
            test_count = test_count + 1;

            if(compare_output(1'b0)) begin
                $display("[PASS] %s | OPA=%h OPB=%h CIN=%b CMD=%b VALID=%b MODE=%b",
                          test_name, a, b, cin, icmd, iv, mode);
                pass_count = pass_count + 1;
            end
            else begin
                $display("[FAIL] %s: OPA=0x%h OPB=0x%h CIN=%b CMD=%b VALID=%b MODE=%b",
                          test_name, a, b, cin, icmd, iv, mode);
                display_mismatch();
                fail_count = fail_count + 1;
            end
        end
    endtask

    function automatic integer compare_output(input dummy);
    begin
        compare_output = 1;
        if(res_dut   !== res_ref)   compare_output = 0;
        if(cout_dut  !== cout_ref)  compare_output = 0;
        if(oflow_dut !== oflow_ref) compare_output = 0;
        if(g_dut     !== g_ref)     compare_output = 0;
        if(e_dut     !== e_ref)     compare_output = 0;
        if(l_dut     !== l_ref)     compare_output = 0;
        if(err_dut   !== err_ref)   compare_output = 0;
    end
    endfunction

    task display_mismatch();
    begin
        $display("  DUT: RES=0x%h COUT=%b OFLOW=%b G=%b E=%b L=%b ERR=%b",
                  res_dut, cout_dut, oflow_dut, g_dut, e_dut, l_dut, err_dut);
        $display("  REF: RES=0x%h COUT=%b OFLOW=%b G=%b E=%b L=%b ERR=%b",
                  res_ref, cout_ref, oflow_ref, g_ref, e_ref, l_ref, err_ref);
    end
    endtask

endmodule
