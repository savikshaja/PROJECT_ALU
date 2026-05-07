module four_bit_alu_rtl_design #(parameter WIDTH=4)
(i_opa,i_opb,cin,clk,rst,i_cmd,ce,mode,i_inp_valid,cout,oflow,res,g,e,l,err);

input [WIDTH-1:0] i_opa, i_opb;
input clk, rst, ce, mode, cin;
input [1:0] i_inp_valid;
input [3:0] i_cmd;

output reg [2*WIDTH-1:0] res;
output reg cout, oflow, g, e, l, err;

//rotate 
localparam rotate_value = $clog2(WIDTH);

//cycle pipline
reg [WIDTH-1:0] opa, opb;
reg [3:0] cmd;
reg [1:0] inp_valid;
reg cin_r;
reg mode_r;

reg [2*WIDTH-1:0] res_multi;

reg [1:0] cycle_count;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        res <= {(2*WIDTH){1'b0}};
        cout<= 1'b0;
        oflow <= 1'b0;
        g <= 1'b0;
        e <= 1'b0;
        l <= 1'b0;
        err <= 1'b0;
        
        opa  <= {WIDTH{1'b0}};
        opb  <= {WIDTH{1'b0}};
        cmd  <= 4'b0000;
        inp_valid   <= 2'b00;
        cin_r <= 1'b0;
        mode_r  <= 1'b0;
        cycle_count <= 2'b00;
        res_multi <= {(2*WIDTH){1'b0}};
    end 
    else if (ce) begin
//cycle_count=0 capture input
        if (cycle_count == 2'b00) begin
            opa <= i_opa;
            opb <= i_opb;
            cmd <= i_cmd;
            inp_valid <= i_inp_valid;
            cin_r <= cin;
            mode_r <= mode;
            
            g <= 1'b0;
            e <= 1'b0;
            l <= 1'b0;
            err<=1'b0;
            cout<=1'b0;
            oflow<=1'b0;
            if (mode && (i_cmd == 4'b1001 || i_cmd == 4'b1010))
                cycle_count <= 2'b10; //if mode and comd of multipication cycle=2 because input already captures
            else
                cycle_count <= 2'b01; //else cycle=1 for rest cmd operation
        end
//cycle =1 and set all output to 0 and count of cycle=0 because only 2 cyle for other operation
        else if (cycle_count == 2'b01) begin
            res   <= {(2*WIDTH){1'b0}};
            cout  <= 1'b0;
            oflow <= 1'b0;
            g <= 1'b0;
            e <= 1'b0;
            l  <= 1'b0;
            err <= 1'b0;

            cycle_count <= 2'b00;

            if (mode_r) begin
                case (cmd)
                    4'b0000: begin          //ADDITION
                        if (inp_valid == 2'b11)
                        begin
                            res<= opa + opb;
                            cout<=({1'b0,opa}+{1'b0,opb})>>WIDTH;
                            res[2*WIDTH-1:WIDTH+1]<= {WIDTH{1'b0}};
                        end
                        else
                            err <= 1'b1;
                    end
                    4'b0001: begin          //SUBSTRACTION
                        if (inp_valid == 2'b11)
                        begin
                            res <= opa - opb;
                            oflow <= (opa < opb);
                        end 
                            else err <= 1'b1;
                    end
                    4'b0010: begin          //ADD WITH CIN
                        if (inp_valid == 2'b11) begin
                            res<= opa + opb + cin_r;
                            cout<=res[WIDTH];
                            res[2*WIDTH-1:WIDTH] <= {WIDTH{1'b0}};
                        end 
                        else 
                            err <= 1'b1;
                    end
                    4'b0011: begin          //SUB WITH CIN
                        if (inp_valid == 2'b11) begin
                            res <= opa - opb - cin_r;
                            oflow <= (opa < opb + cin_r);
                        end 
                        else 
                            err <= 1'b1;
                    end
                    4'b0100: begin          //INCREMENT A
                        if (inp_valid == 2'b11 || inp_valid == 2'b01)
                            res <= opa + 1;
                        else 
                            err <= 1'b1;
                    end
                    4'b0101: begin          //DECREMENT A
                        if (inp_valid == 2'b11 || inp_valid == 2'b01)
                            res <= opa - 1;
                        else
                             err <= 1'b1;
                    end
                    4'b0110: begin      //INCREMENT A
                        if (inp_valid == 2'b11 || inp_valid == 2'b10)
                            res <= opb + 1;
                        else 
                            err <= 1'b1;
                    end
                    4'b0111: begin      //DECREMENT B
                        if (inp_valid == 2'b11 || inp_valid == 2'b10)
                            res <= opb - 1;
                        else 
                            err <= 1'b1;
                    end
                    4'b1000: begin          //COMPARATOR
                        if (inp_valid == 2'b11) begin
                            if (opa == opb) 
                            begin
                                e <= 1'b1;
                                g <= 1'b0;
                                l <= 1'b0;
                            end
                            else if (opa > opb) 
                            begin
                                g <= 1'b1;
                                e <= 1'b0;
                                l <= 1'b0;
                            end
                            else
                            begin
                                l <= 1'b1;
                                e <= 1'b0;
                                g <= 1'b0;
                            end
                        end 
                        else begin
                            res <= {(2*WIDTH){1'b0}};
                            err <= 1'b1;
                        end
                    end
                    4'b1011: begin          //SIGNED ADDITION
                        if (inp_valid == 2'b11)
                        begin
                            {cout, res[WIDTH-1:0]} <= $signed(opa) + $signed(opb);
                            res[2*WIDTH-1:WIDTH]   <= {WIDTH{1'b0}};
                            oflow <= (opa[WIDTH-1] == opb[WIDTH-1]) && (res[WIDTH-1] != opa[WIDTH-1]);
                            //comparator
                            if($signed(opa)>$signed(opb))g<=1'b1;
                            else if ($signed(opa)<$signed(opb))l<=1'b1;
                            else e<=1'b1;
                        end 
                        else 
                            err <= 1'b1;
                    end
                    4'b1100: begin      //SIGNED SUBSTRACTION
                        if (inp_valid == 2'b11) begin
                            {cout, res[WIDTH-1:0]} <= $signed(opa) - $signed(opb);
                            res[2*WIDTH-1:WIDTH]   <= {WIDTH{1'b0}};
                            oflow <= (opa[WIDTH-1] != opb[WIDTH-1]) &&(res[WIDTH-1] != opa[WIDTH-1]);
                            //comparator
                            if($signed(opa)>$signed(opb))g<=1'b1;
                            else if ($signed(opa)<$signed(opb))l<=1'b1;
                            else e<=1'b1;
                        end 
                        else 
                            err <= 1'b1;
                    end
                    default:
                    begin
                     res <= {(2*WIDTH){1'b0}};
                     err<= 1'b1;
                     g <= 1'b0;
                     e <= 1'b0;
                     l <= 1'b0;
                     cout<=1'b0;
                     oflow<=1'b0;
                    end
                            
                endcase
            end 
            else begin
                case (cmd)
                    4'b0000: if (inp_valid == 2'b11) res <= {{WIDTH{1'b0}}, opa & opb}; else err <= 1'b1;   //AND
                    4'b0001: if (inp_valid == 2'b11) res <= {{WIDTH{1'b0}}, ~(opa & opb)}; else err <= 1'b1;    //NANS
                    4'b0010: if (inp_valid == 2'b11) res <= {{WIDTH{1'b0}}, opa | opb}; else err <= 1'b1;       //OR
                    4'b0011: if (inp_valid == 2'b11) res <= {{WIDTH{1'b0}}, ~(opa | opb)}; else err <= 1'b1;    //NOR
                    4'b0100: if (inp_valid == 2'b11) res <= {{WIDTH{1'b0}}, opa ^ opb}; else err <= 1'b1;       //XOR
                    4'b0101: if (inp_valid == 2'b11) res <= {{WIDTH{1'b0}}, ~(opa ^ opb)}; else err <= 1'b1;    //XNOR
                    4'b0110: if (inp_valid == 2'b11 || inp_valid == 2'b01) res <= {{WIDTH{1'b0}}, ~opa}; else err <= 1'b1;      //NOT A
                    4'b0111: if (inp_valid == 2'b11 || inp_valid == 2'b10) res <= {{WIDTH{1'b0}}, ~opb}; else err <= 1'b1;      //NOT B
                    4'b1000: if (inp_valid == 2'b11 || inp_valid == 2'b01) res <= {{WIDTH{1'b0}}, opa >> 1}; else err <= 1'b1;  //RIGHT SHIFT A 
                    4'b1001: if (inp_valid == 2'b11 || inp_valid == 2'b01) res <= {{WIDTH{1'b0}}, opa << 1}; else err <= 1'b1;  //LEFT SHIF A
                    4'b1010: if (inp_valid == 2'b11 || inp_valid == 2'b10) res <= {{WIDTH{1'b0}}, opb >> 1}; else err <= 1'b1;  //RIGHT SHIFT B
                    4'b1011: if (inp_valid == 2'b11 || inp_valid == 2'b10) res <= {{WIDTH{1'b0}}, opb << 1}; else err <= 1'b1;  //LEFT SHIFT B
                    4'b1100: begin          //ROTATE LEFT
                        if (inp_valid == 2'b11)
                        begin
                            if (|opb[WIDTH-1:rotate_value]) 
                                err <= 1'b1;
                            else 
                                res <= {{WIDTH{1'b0}},(opa << opb[rotate_value-1:0]) |(opa >> (WIDTH - opb[rotate_value-1:0]))};
                        end
                    end
                    4'b1101: begin          //ROTATE RIGHT
                        if (inp_valid == 2'b11)
                        begin
                            if (|opb[WIDTH-1:rotate_value]) 
                                err <= 1'b1;
                            else 
                                res <= {{WIDTH{1'b0}},(opa >> opb[rotate_value-1:0]) |(opa << (WIDTH - opb[rotate_value-1:0]))};
                        end
                    end
                    default:
                    begin
                         res <= {(2*WIDTH){1'b0}};
                         err<=1'b1;
                         g <= 1'b0;
                        e <= 1'b0;
                        l <= 1'b0;
                        cout<=1'b0;
                        oflow<=1'b0;
                    end
                endcase
            end
        end
//MULTIPICATION AFTER CAPTURE INPUTS
        else if (cycle_count == 2'b10) begin
            err <= 1'b0;
            if ((i_inp_valid != inp_valid) && (i_cmd == cmd))   //IN INP_VALID IS CHANGED
            begin
                err<= 1'b1;
                res <= {(2*WIDTH){1'b0}};
                cycle_count <= 2'b00; //reset the cycle for capture
            end 
            else if ((i_inp_valid != inp_valid) && (i_cmd != cmd)) begin //inp_valid and cmd changed capture the cmd at that time and perform operation
                opa<= i_opa;
                opb<= i_opb;
                cmd <= i_cmd;
                inp_valid <= i_inp_valid;
                cin_r <= cin;
                mode_r <= mode;
                cycle_count <= 2'b01;
            end 
            else begin //calulate at 2 cycle after capture store in register
                if (cmd == 4'b1001)     //if cmd is 9
                begin
                    res<={(2*WIDTH){1'bx}};
                    res_multi <= (opa + 1) * (opb + 1);
                end
                else        //cmd is 10
                begin
                    res<={(2*WIDTH){1'bx}};
                    res_multi <= (opa << 1) * opb;
                end
                cycle_count <= 2'b11;
            end
        end

        else if (cycle_count == 2'b11) begin    //at 3 cycle the res is assigned with multiplied value
            res <= res_multi;
            cycle_count <= 2'b00;
        end
    end
	else
	begin
//		res<=res;
		err<=1'b1;
	//	cout<=1'b0;
	//	oflow<=1'b0;
	end
end

endmodule
