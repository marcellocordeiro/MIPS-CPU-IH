module Mux32_2 (input logic [31:0] in0, in1, input logic IorD, output logic [31:0] out);

assign out = (IorD)? in1:in0;
	
endmodule: Mux32_2