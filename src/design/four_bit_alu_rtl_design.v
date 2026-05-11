module four_bit_alu_rtl_design #(parameter WIDTH=4)
(i_opa, i_opb, cin, clk, rst, i_cmd, ce, mode, i_inp_valid,
 cout, oflow, res, g, e, l, err);

    input  [WIDTH-1:0] i_opa, i_opb;
    input              clk, rst, ce, mode, cin;
    input  [1:0]       i_inp_valid;
    input  [3:0]       i_cmd;

    output reg [2*WIDTH-1:0] res;
    output reg               cout, oflow, g, e, l, err;

    localparam rotate_value = $clog2(WIDTH);

    reg [WIDTH-1:0]   opa, opb;
    reg [3:0]         cmd;
    reg [1:0]         inp_valid;
    reg               cin_r;
    reg               mode_r;
    reg [2*WIDTH-1:0] res_multi;
    reg [1:0]         cycle_count;
    reg [2*WIDTH-1:0] res_temp;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            res         <= {(2*WIDTH){1'b0}};
            cout        <= 1'b0;
            oflow       <= 1'b0;
            g           <= 1'b0;
            e           <= 1'b0;
            l           <= 1'b0;
            err         <= 1'b0;
            opa         <= {WIDTH{1'b0}};
            opb         <= {WIDTH{1'b0}};
            cmd         <= 4'b0000;
            inp_valid   <= 2'b00;
            cin_r       <= 1'b0;
            mode_r      <= 1'b0;
            cycle_count <= 2'b00;
            res_multi   <= {(2*WIDTH){1'b0}};
            res_temp    <= {(2*WIDTH){1'b0}};
        end

        else if (ce) begin

            // cycle 0  capture inputs
            if (cycle_count == 2'b00) begin
                opa       <= i_opa;
                opb       <= i_opb;
                cmd       <= i_cmd;
                inp_valid <= i_inp_valid;
                cin_r     <= cin;
                mode_r    <= mode;
                g         <= 1'b0;
                l         <= 1'b0;
                e         <= 1'b0;

                if (mode && (i_cmd == 4'b1001 || i_cmd == 4'b1010))
                    cycle_count <= 2'b10;
                else
                    cycle_count <= 2'b01;
            end

            // cycle 1  compute and output
            else if (cycle_count == 2'b01) begin
                res         <= {(2*WIDTH){1'b0}};
                cout        <= 1'b0;
                oflow       <= 1'b0;
                g           <= 1'b0;
                e           <= 1'b0;
                l           <= 1'b0;
                err         <= 1'b0;
                cycle_count <= 2'b00;

                if (mode_r) begin
                    case (cmd)

                        4'b0000: begin  // addition
                            if (inp_valid == 2'b11) begin
                                res  <= {{WIDTH{1'b0}}, opa} + {{WIDTH{1'b0}}, opb};
                                cout <= ({{1'b0}, opa} + {{1'b0}, opb}) >> WIDTH;
                            end
                            else
                                err <= 1'b1;
                        end

                        4'b0001: begin  // subtraction
                            if (inp_valid == 2'b11) begin
                                res   <= {{WIDTH{1'b0}}, opa} - {{WIDTH{1'b0}}, opb};
                                oflow <= (opa < opb);
                            end
                            else
                                err <= 1'b1;
                        end

                        4'b0010: begin  // add with cin
                            if (inp_valid == 2'b11) begin
                                res  <= {{WIDTH{1'b0}}, opa} + {{WIDTH{1'b0}}, opb} + cin_r;
                                cout <= ({{1'b0}, opa} + {{1'b0}, opb} + cin_r) >> WIDTH;
                            end
                            else
                                err <= 1'b1;
                        end

                        4'b0011: begin  // sub with cin
                            if (inp_valid == 2'b11) begin
                                res   <= {{WIDTH{1'b0}}, opa} - {{WIDTH{1'b0}}, opb} - cin_r;
                                oflow <= (opa < (opb + cin_r));
                            end
                            else
                                err <= 1'b1;
                        end

                        4'b0100: begin  // increment a
                            if (inp_valid == 2'b11 || inp_valid == 2'b01)
                                res <= {{WIDTH{1'b0}}, opa} + 1;
                            else
                                err <= 1'b1;
                        end

                        4'b0101: begin  // decrement a
                            if (inp_valid == 2'b11 || inp_valid == 2'b01)
                                res <= {{WIDTH{1'b0}}, opa} - 1;
                            else
                                err <= 1'b1;
                        end

                        4'b0110: begin  // increment b
                            if (inp_valid == 2'b11 || inp_valid == 2'b10)
                                res <= {{WIDTH{1'b0}}, opb} + 1;
                            else
                                err <= 1'b1;
                        end

                        4'b0111: begin  // decrement b
                            if (inp_valid == 2'b11 || inp_valid == 2'b10)
                                res <= {{WIDTH{1'b0}}, opb} - 1;
                            else
                                err <= 1'b1;
                        end

                        4'b1000: begin  // comparator
                            if (inp_valid == 2'b11) begin
                                if (opa == opb) begin
                                    e <= 1'b1;
                                    g <= 1'b0;
                                    l <= 1'b0;
                                end
                                else if (opa > opb) begin
                                    g <= 1'b1;
                                    e <= 1'b0;
                                    l <= 1'b0;
                                end
                                else begin
                                    l <= 1'b1;
                                    e <= 1'b0;
                                    g <= 1'b0;
                                end
                            end
                            else begin
                                err <= 1'b1;
                            end
                        end

                        4'b1011: begin  // signed addition
                            if (inp_valid == 2'b11) begin
                                // sign extend to 2*WIDTH then add
                                res_temp = $signed({{WIDTH{opa[WIDTH-1]}}, opa}) +
                                           $signed({{WIDTH{opb[WIDTH-1]}}, opb});
                                res   <= res_temp;
                                cout  <= 1'b0;
                                oflow <= (opa[WIDTH-1] == opb[WIDTH-1]) &&
                                         (res_temp[WIDTH-1] != opa[WIDTH-1]);
                                if      ($signed(opa) > $signed(opb)) g <= 1'b1;
                                else if ($signed(opa) < $signed(opb)) l <= 1'b1;
                                else                                   e <= 1'b1;
                            end
                            else
                                err <= 1'b1;
                        end

                        4'b1100: begin  // signed subtraction
                            if (inp_valid == 2'b11) begin
                                // sign extend to 2*WIDTH then subtract
                                res_temp = $signed({{WIDTH{opa[WIDTH-1]}}, opa}) -
                                           $signed({{WIDTH{opb[WIDTH-1]}}, opb});
                                res   <= res_temp;
                                cout  <= 1'b0;
                                oflow <= (opa[WIDTH-1] != opb[WIDTH-1]) &&
                                         (res_temp[WIDTH-1] != opa[WIDTH-1]);
                                if      ($signed(opa) > $signed(opb)) g <= 1'b1;
                                else if ($signed(opa) < $signed(opb)) l <= 1'b1;
                                else                                   e <= 1'b1;
                            end
                            else
                                err <= 1'b1;
                        end

                        default: begin  // invalid cmd
                            res   <= {(2*WIDTH){1'b0}};
                            cout  <= 1'b0;
                            oflow <= 1'b0;
                            g     <= 1'b0;
                            e     <= 1'b0;
                            l     <= 1'b0;
                            err   <= 1'b1;
                        end

                    endcase
                end

                else begin  // logic mode
                    case (cmd)

                        4'b0000:  // and
                            if (inp_valid == 2'b11)
                                res <= {{WIDTH{1'b0}}, opa & opb};
                            else
                                err <= 1'b1;

                        4'b0001:  // nand
                            if (inp_valid == 2'b11)
                                res <= {{WIDTH{1'b0}}, ~(opa & opb)};
                            else
                                err <= 1'b1;

                        4'b0010:  // or
                            if (inp_valid == 2'b11)
                                res <= {{WIDTH{1'b0}}, opa | opb};
                            else
                                err <= 1'b1;

                        4'b0011:  // nor
                            if (inp_valid == 2'b11)
                                res <= {{WIDTH{1'b0}}, ~(opa | opb)};
                            else
                                err <= 1'b1;

                        4'b0100:  // xor
                            if (inp_valid == 2'b11)
                                res <= {{WIDTH{1'b0}}, opa ^ opb};
                            else
                                err <= 1'b1;

                        4'b0101:  // xnor
                            if (inp_valid == 2'b11)
                                res <= {{WIDTH{1'b0}}, ~(opa ^ opb)};
                            else
                                err <= 1'b1;

                        4'b0110:  // not a
                            if (inp_valid == 2'b11 || inp_valid == 2'b01)
                                res <= {{WIDTH{1'b0}}, ~opa};
                            else
                                err <= 1'b1;

                        4'b0111:  // not b
                            if (inp_valid == 2'b11 || inp_valid == 2'b10)
                                res <= {{WIDTH{1'b0}}, ~opb};
                            else
                                err <= 1'b1;

                        4'b1000:  // shift right a
                            if (inp_valid == 2'b11 || inp_valid == 2'b01)
                                res <= {{WIDTH{1'b0}}, opa >> 1};
                            else
                                err <= 1'b1;

                        4'b1001:  // shift left a
                            if (inp_valid == 2'b11 || inp_valid == 2'b01)
                                res <= {{WIDTH{1'b0}}, opa << 1};
                            else
                                err <= 1'b1;

                        4'b1010:  // shift right b
                            if (inp_valid == 2'b11 || inp_valid == 2'b10)
                                res <= {{WIDTH{1'b0}}, opb >> 1};
                            else
                                err <= 1'b1;

                        4'b1011:  // shift left b
                            if (inp_valid == 2'b11 || inp_valid == 2'b10)
                                res <= {{WIDTH{1'b0}}, opb << 1};
                            else
                                err <= 1'b1;

                        4'b1100: begin  // rotate left a by b
                            if (inp_valid == 2'b11) begin
                                if (|opb[WIDTH-1:rotate_value])
                                    err <= 1'b1;
                                else if (opb[rotate_value-1:0] == 0)
                                    res <= {{WIDTH{1'b0}}, opa};
                                else
                                    res <= {{WIDTH{1'b0}},
                                            (opa << opb[rotate_value-1:0]) |
                                            (opa >> (WIDTH - opb[rotate_value-1:0]))};
                            end
                            else
                                err <= 1'b1;
                        end

                        4'b1101: begin  // rotate right a by b
                            if (inp_valid == 2'b11) begin
                                if (|opb[WIDTH-1:rotate_value])
                                    err <= 1'b1;
                                else if (opb[rotate_value-1:0] == 0)
                                    res <= {{WIDTH{1'b0}}, opa};
                                else
                                    res <= {{WIDTH{1'b0}},
                                            (opa >> opb[rotate_value-1:0]) |
                                            (opa << (WIDTH - opb[rotate_value-1:0]))};
                            end
                            else
                                err <= 1'b1;
                        end

                        default: begin  // invalid cmd
                            res   <= {(2*WIDTH){1'b0}};
                            cout  <= 1'b0;
                            oflow <= 1'b0;
                            g     <= 1'b0;
                            e     <= 1'b0;
                            l     <= 1'b0;
                            err   <= 1'b1;
                        end

                    endcase
                end
            end

            // cycle 2  multiply middle cycle
            else if (cycle_count == 2'b10) begin
                if ((i_inp_valid != inp_valid) && (i_cmd == cmd)) begin
                    // inp_valid changed but cmd same  error
                    err         <= 1'b1;
                    res         <= {(2*WIDTH){1'b0}};
                    cycle_count <= 2'b00;
                end
                else if ((i_inp_valid != inp_valid) && (i_cmd != cmd)) begin
                    // both inp_valid and cmd changed  capture new inputs
                    opa         <= i_opa;
                    opb         <= i_opb;
                    cmd         <= i_cmd;
                    inp_valid   <= i_inp_valid;
                    cin_r       <= cin;
                    mode_r      <= mode;
                    cycle_count <= 2'b01;
                end
                else begin
                    // compute multiplication
                    if (cmd == 4'b1001)
                        res_multi <= (opa + 1) * (opb + 1);  // multi incre
                    else
                        res_multi <= (opa << 1) * opb;        // multi shift a

                    res         <= {(2*WIDTH){1'bx}};
                    cycle_count <= 2'b11;
                end
            end

            // cycle 3  multiply output
            else if (cycle_count == 2'b11) begin
                res         <= res_multi;
                cycle_count <= 2'b00;
            end

        end
    end

endmodule
