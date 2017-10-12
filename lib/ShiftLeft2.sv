module ShiftLeft2 (input logic [31:0] in,
                   output logic [31:0] out);

assign out[31:2] = in[29:0];
assign out[1:0] = 0;

endmodule: ShiftLeft2