module sign_extend(input logic [15:0] in,
                   output logic [31:0] out);

assign out[31:0] = {{16{in[15]}}, in[15:0]};

endmodule: sign_extend