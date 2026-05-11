`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/10/2026 07:07:16 PM
// Design Name: 
// Module Name: alu_ref
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module alu_ref #(parameter N=4)
(
    input wire [N-1:0] opa, opb,
    input wire cin, mode,
    input wire [3:0] cmd,
    input wire [1:0]inp_valid,
    input wire ce,
    output reg [2*N-1:0] res,
    output reg cout, oflow, g, e, l, err
);

    reg [N-1:0] opa_1, opb_1;
    localparam rotate_value = $clog2(N);
    always @(*) 
    begin
        if(ce)
        begin
        res = {(2*N){1'b0}};
        cout = 1'b0;
        oflow = 1'b0;
        g = 1'b0;
        e = 1'b0;
        l = 1'b0;
        err = 1'b0;
        if (mode)
        begin  // arithmetic mode
            case(cmd)
                4'b0000:
                begin  // add
                if(inp_valid==2'b11)
                begin
                    res = opa + opb;
                    cout = res[N];
                end
                else
                         err=1'b1;
end
                4'b0001:
                begin  // sub
                if(inp_valid==2'b11)
                begin
                    oflow = (opa < opb);
                    res = opa - opb;
                end
                else
                    err=1'b1;
                end
                4'b0010:
                 begin  // add_cin
                 if(inp_valid==2'b11)
                 begin
                    res = opa + opb + cin;
                    cout = res[N];
                 end
                 else
                    err=1'b1;
                end
                4'b0011:
                begin  // sub_cin
                if(inp_valid==2'b11)
                 begin
                    res = opa - opb - cin;
                    oflow=opa<opb;
                 end
                 else
                    err=1'b1;
                end
                4'b0100:  // inc_a
                begin
                if(inp_valid==2'b11 || inp_valid==2'b01)
                     res = opa + 1;
                else
                    err=1'b1;
                end
                4'b0101:  // dec_a
                begin
                if(inp_valid==2'b11 || inp_valid==2'b01)
                     res = opa - 1;
                else
                    err=1'b1;
                end
                4'b0110:  // inc_b
                begin
                if(inp_valid==2'b11 || inp_valid==2'b10)
                     res = opb + 1;
                else
                    err=1'b1;
                end
                4'b0111:  // dec_b
                begin
                if(inp_valid==2'b11 || inp_valid==2'b10)
                     res = opb - 1;
                else
                    err=1'b1;
                end
                4'b1000:  // cmp
                begin
                if(inp_valid==2'b11)
                begin
                    res = {(2*N){1'b0}};
                    if (opa == opb) begin
                        e = 1'b1; g = 1'b0; l = 1'b0;
                    end else if (opa > opb) begin
                        e = 1'b0; g = 1'b1; l = 1'b0;
                    end else begin
                        e = 1'b0; g = 1'b0; l = 1'b1;
                    end
                end
              else
                err=1'b1;
                end
                4'b1001:
                begin   //multi inc
                if(inp_valid==2'b11)
                    res=(opa+1)*(opb+1);
                else
                    err=1'b1;
                end
                4'b1010:
                begin   //multi shifta
                if(inp_valid==2'b11)
                    res=(opa<<1)*opb;
                else
                    err=1'b1;
                end
                4'b1011:
                begin       //signed addition
		if(inp_valid==2'b11) begin
                    res=$signed(opa)+$signed(opb);
                    oflow=(opa[N-1] == opb[N-1]) && (res[N-1] != opa[N-1]);
                    if($signed(opa)>$signed(opb))g =1'b1;
                    else if ($signed(opa)<$signed(opb))l =1'b1;
                    else e =1'b1;
                end
		else
			err=1'b1;
		end
                4'b1100:
                begin       //signed substraction
		if(inp_valid==2'b11) begin
                    res=$signed(opa)-$signed(opb);
                    oflow=(opa[N-1] != opb[N-1]) && (res[N-1] != opa[N-1]);
                    if($signed(opa)>$signed(opb))g =1'b1;
                    else if ($signed(opa)<$signed(opb))l=1'b1;
                    else e=1'b1;
		end
		else
			err=1'b1;
                end
                default:
                begin
                    res = {(2*N){1'b0}};
                     err = 1'b1;
                     g = 1'b0;
                     e = 1'b0;
                     l = 1'b0;
                     cout =1'b0;
                     oflow =1'b0;
                end
            endcase
        end
        else begin  // logical mode
            case(cmd)
                4'b0000: if(inp_valid==2'b11) res = {1'b0, opa & opb}; else err=1'b1;       // and
                4'b0001: if (inp_valid==2'b11) res = {1'b0, ~(opa & opb)};else err=1'b1;    // nand
                4'b0010: if (inp_valid==2'b11) res = {{N{1'b0}}, opa | opb}; else err=1'b1;    // or
                4'b0011: if (inp_valid==2'b11) res = {{N{1'b0}}, ~(opa | opb)}; else err=1'b1;    // nor
                4'b0100: if (inp_valid==2'b11) res = {{N{1'b0}}, opa ^ opb}; else err=1'b1;      // xor
                4'b0101: if (inp_valid==2'b11) res = {{N{1'b0}}, ~(opa ^ opb)}; else err=1'b1;  // xnor
                4'b0110: if (inp_valid==2'b11 || inp_valid==2'b01) res = {{N{1'b0}}, ~opa}; else err=1'b1;       // not_a
                4'b0111: if (inp_valid==2'b11 || inp_valid==2'b10) res = {{N{1'b0}}, ~opb}; else err=1'b1;           // not_b
                4'b1000: if (inp_valid==2'b11 || inp_valid == 2'b01) res = {{N{1'b0}}, opa >> 1}; else err=1'b1;       // shr1_a
                4'b1001: if (inp_valid==2'b11 || inp_valid == 2'b01) res = {{N{1'b0}}, opa << 1}; else err=1'b1;        // shl1_a
                4'b1010: if (inp_valid==2'b11 || inp_valid == 2'b10) res = {{N{1'b0}}, opb >> 1}; else err=1'b1;       // shr1_b
                4'b1011: if (inp_valid==2'b11 || inp_valid == 2'b10) res = {{N{1'b0}}, opb << 1}; else err=1'b1;       // shl1_b
                4'b1100:
                begin  // rol_a_b
                    if (inp_valid == 2'b11)
                        begin
                            if (|opb[N-1:rotate_value])
                                err = 1'b1;
                            else
                                res = {{N{1'b0}},(opa << opb[rotate_value-1:0]) |(opa >> (N - opb[rotate_value-1:0]))};
                        end
                else
                    err=1'b1;
                end
                4'b1101:
                begin  // ror_a_b
                    if (inp_valid == 2'b11)
                        begin
                            if (|opb[N-1:rotate_value])
                                err = 1'b1;
                            else
                                res = {{N{1'b0}},(opa >> opb[rotate_value-1:0]) |(opa << (N - opb[rotate_value-1:0]))};
                        end
                     else
                        err=1'b1;
                end
                default:
                    begin
                         res = {(2*N){1'b0}};
                         err =1'b1;
                         g = 1'b0;
                        e = 1'b0;
                        l = 1'b0;
                        cout =1'b0;
                        oflow =1'b0;
                    end
            endcase
        end
    end
end
endmodule


